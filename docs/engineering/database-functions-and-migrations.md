# Standar migration dan function PostgreSQL untuk backend ERP

**Berlaku untuk:** semua owner database PostgreSQL 18 dan adapter Go/Echo, dari Foundation sampai Enterprise Expansion. Dokumen ini memperjelas [standar database](database-standards.md), [standar backend](backend-standards.md), dan [ADR-0004](../adr/0004-versioned-database-functions.md). Migration bukan opsional: aplikasi tidak mengubah schema/function sendiri pada startup dan runtime role tidak memiliki DDL. Function DB digunakan secara nyata untuk invariant lokal yang harus atomik, bukan sebagai folder dekoratif.

## 1. Sumber, folder, dan alur versi

```text
backend/database/
├── migrations/<schema>/
│   ├── 000001_create_tables.up.sql
│   ├── 000002_apply_movement_v1.up.sql       # CREATE FUNCTION, REVOKE/GRANT, komentar
│   ├── 000002_apply_movement_v1.down.sql     # hanya bila aman dan benar-benar reversible
│   └── 000003_apply_movement_v2.up.sql       # breaking signature/semantik, v1 tetap hidup
├── queries/<schema>/                          # query bernama untuk sqlc
└── sqlc.yaml                                  # output ke adapter Go owner

backend/golang/services/<owner>/internal/<module>/adapters/postgres/
├── sqlc/                                      # generated; tidak diedit manual
├── movement_repository.go                    # panggil function dengan parameter typed
└── movement_repository_test.go               # PostgreSQL integration/concurrency
```

File yang sudah diaplikasikan **immutable**. Function definition dan grant yang dideploy berada dalam migration baru, bukan SQL manual di server produksi, init script terpisah, atau string DDL di Go. `schema_migrations`/runner dan lock migrasi dipakai per schema; hasil apply, checksum, durasi, dan versi dicatat. sqlc hanya menghasilkan kode typed dari query dan migration; ia tidak menjalankan migration, authorization, atau invariant atomik. Up/down berpasangan hanya jika down tidak menghapus fakta atau merusak binary yang masih berjalan; selain itu tulis forward-fix, restore checkpoint dan rencana pemulihan. [Standar database §8](database-standards.md#8-migrations-hak-akses-dan-operasi) menjelaskan expand/backfill/switch/contract dan rolling compatibility. Pengecualian `accounting/000001` yang juga membuat objek `finance` serta dependency awal `accounting`→`finance` didokumentasikan di [ADR-0006](../adr/0006-database-sql-layout.md); migration baru tidak boleh mengulang pola lintas schema ini.

Perubahan function yang tetap kompatibel pada parameter, return, permission dan makna boleh `CREATE OR REPLACE FUNCTION` dalam migration **baru**. Mengubah signature, return type, error contract atau makna hasil adalah breaking: buat `_v2`, uji v1/v2 paralel, pindahkan caller, tunggu semua instance lama berhenti, lalu drop v1 pada migration contract terpisah. PostgreSQL menjelaskan batas `OR REPLACE`, ownership dan grant yang dipertahankan di [CREATE FUNCTION](https://www.postgresql.org/docs/18/sql-createfunction.html). Jangan otomatis `DROP CASCADE` pada function yang dipakai view/trigger.

## 2. Function yang direncanakan per owner

| Owner dan fase | Function DB minimal yang dinilai saat slice dibuat | Invariant atomik dan caller |
|---|---|---|
| Setiap document owner / Commercial Foundation | `numbering.claim_document_number_v1` di DB owner dokumen terkait; `credit.reserve_exposure_v1` di DB Commercial | Nomor final tidak dipakai ulang; exposure tidak melewati limit saat dua SO serentak. Go memeriksa policy/scope dan memanggil function di transaksi owner yang tepat, tanpa SQL lintas DB. |
| Operations MVP | `inventory.apply_stock_movement_v1`, `inventory.reserve_stock_v1` | Source portion unik, balance/ledger/cost sesuai, no negative sellable/double allocation. GRN/adjustment/reservation caller memakai typed args dan transaction owner. |
| Finance MVP | `accounting.post_balanced_journal_v1` | Period OPEN, source/journal unik dan total debit=credit sebelum status POSTED; invoice/payment caller tetap mengontrol use case dan audit/outbox. |
| Phase 2 | `purchase.claim_blanket_capacity_v1`, `inventory.apply_transfer_leg_v1`, `inventory.post_count_delta_v1` | Cap kontrak, shipped/received portion dan count adjustment tidak melewati batas pada race/retry. |
| Phase 3 | `budget.reserve_commitment_v1`, `finance.match_bank_line_v1`, `finance.post_fx_revaluation_v1` | Available hard budget, one-to-one match, period/source FX unik dan jurnal seimbang. |
| Enterprise Expansion | `manufacturing.issue_material_v1`, `pos.claim_register_sale_v1`, `analytics.advance_checkpoint_v1` | WIP/stock satu kali, sale/provider reference unik, watermark hanya maju setelah batch tervalidasi. |

Daftar ini menetapkan **kewajiban meninjau dan mengimplementasikan function DB pada slice terkait**, bukan izin membangun function generik besar. Nama final dan signature typed dicatat di migration serta dokumentasi modul sebelum handler dipakai. Jika satu invariant lebih aman sebagai `UNIQUE`/`CHECK` atau satu SQL CAS, gunakan constraint/CAS dan catat alasan; tidak perlu function pembungkus yang hanya memanggil satu `SELECT`. Sebaliknya, operasi multi-statement yang harus konsisten di satu owner tidak boleh tersebar sebagai SQL ad hoc tanpa pengujian race. Function/trigger awal `accounting.reject_overlapping_fiscal_period()` sudah ada di [migration Finance](../../backend/database/migrations/accounting/000001_grni_posting.up.sql); hardening berikutnya memakai migration baru.

## 3. Batas tanggung jawab

**Go application/domain:** autentikasi, permission, tenant/entity/branch scope, policy version dan state transition lintas owner, input/DTO, orkestrasi saga, idempotency API, error HTTP, observability dan keputusan bisnis yang perlu event/layanan lain. **Function PostgreSQL owner:** lock dan invariant lokal, CAS/source uniqueness, perubahan ledger/balance/journal yang harus atomik, serta return typed untuk hasil baru. Go memanggilnya dengan parameter terikat lewat `sql.Tx` yang sama dengan audit, idempotency result dan outbox. Function tidak melakukan `COMMIT`, `ROLLBACK`, HTTP, broker, secret lookup atau akses tabel owner lain.

Input function tidak boleh berupa SQL dinamis dari user atau `jsonb` bebas yang menyembunyikan kontrak. Setiap parameter/return mencantumkan tipe dan nullability; GUID tenant/entity/actor/operation adalah argumen eksplisit atau berasal dari konteks transaksi tepercaya. Function tetap memvalidasi scope dan source row yang di-lock; validasi Go tidak menggantikan constraint DB. Error memakai SQLSTATE/constraint name yang terdokumentasi dan dipetakan secara allowlist ke kode API stabil; jangan menjadikan teks `RAISE` yang bebas sebagai logika klien. [PL/pgSQL RAISE](https://www.postgresql.org/docs/18/plpgsql-errors-and-messages.html) mendukung SQLSTATE spesifik.

## 4. Keamanan dan kualitas function

- `SECURITY INVOKER` adalah default. Beri `EXECUTE` hanya kepada runtime role owner yang membutuhkan; cabut default `PUBLIC` dan tetapkan grant dalam transaksi migration yang sama. Untuk `SECURITY DEFINER`, perlu ADR/security review, owner tanpa superuser, `SET search_path` berisi schema tepercaya dengan `pg_temp` terakhir, nama objek schema-qualified, dan tes pemanggil berprivilege rendah. [Panduan resmi PostgreSQL](https://www.postgresql.org/docs/18/sql-createfunction.html#SQL-CREATEFUNCTION-SECURITY) menjelaskan risiko search path dan default grant.
- Tandai function yang menulis data **`VOLATILE`**. `STABLE` hanya untuk read yang konsisten per statement, `IMMUTABLE` hanya untuk hasil yang benar-benar tidak bergantung tabel, timezone, atau konfigurasi. Salah label dapat menghasilkan hasil cache/plan yang salah menurut [volatility categories PostgreSQL](https://www.postgresql.org/docs/18/xfunc-volatility.html).
- Nama function `schema.verb_object_vN`, komentar menjelaskan invariant, input/output, error, lock order, dan owner. Jangan overload nama yang membuat pemilihan signature ambigu. Gunakan `numeric` untuk uang/qty, `timestamptz` untuk instant, dan UUID untuk referensi publik.
- Lock order konsisten, cek ulang state setelah lock, source operation key unik permanen, dan hasil retry idempotent. Function yang memodifikasi ledger harus mengembalikan GUID/version/amount yang dipakai audit/outbox, bukan meminta caller membaca state dari cache. Ukur query plan/lock wait pada fixture representatif; function bukan alasan untuk mengabaikan indeks.

## 5. Checklist review untuk setiap perubahan migration/function

- [ ] Owner/schema, reader/writer lama dan baru, data shape, dependency function/view/trigger, serta urutan deploy dipetakan.
- [ ] Migration baru memiliki up, checksum, estimasi lock/durasi, rollback **atau** forward-fix; file lama tidak diedit.
- [ ] Expand/backfill/verifikasi/switch/contract menjaga binary lama dan baru selama rolling deploy; destructive contract adalah langkah terpisah.
- [ ] Function mempunyai signature typed, volatility/privilege/search path/error code yang ditinjau, `PUBLIC` tidak dapat `EXECUTE` bila tidak diperlukan.
- [ ] PostgreSQL integration test menjalankan fresh migration, upgrade dari versi sebelumnya, function call sah/tidak sah, null/boundary, duplicate/retry, dua caller serentak dan rollback transaksi.
- [ ] Tes menegaskan ledger/balance/credit/journal/source uniqueness, audit/outbox atomik, serta no cross-tenant/entity access bila relevan.
- [ ] `pg_proc`/catalog atau introspection test menegaskan function dan grant yang terpasang sesuai versi; Go adapter memakai signature yang sama.
- [ ] Restore/replay dan forward-fix diuji untuk perubahan yang tidak aman di-down; runtime role tidak punya DDL/superuser/`BYPASSRLS`.

Jalankan tes function terhadap PostgreSQL asli, bukan mock SQL saja. Bukti SQL dan hasilnya menjadi bagian work order serta gate fase pada [timeline](../roadmap/implementation-timeline.md) dan [checklist AI](../roadmap/ai-work-orders.md).
