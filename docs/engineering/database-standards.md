# Standar Database PostgreSQL — Enterprise ERP

**Status:** baseline skema, migration dan function DB sebelum DDL produksi. **Baseline:** PostgreSQL 18 sesuai [PRD](../enterprise-erp-prd.md) §11/25/30. **Berlaku untuk:** semua schema domain, proyeksi, audit, outbox dan inbox. Jadwal retensi desain Indonesia ada pada [keputusan G-16](../decisions/mvp-business-policy.md#g-16oq-09--data-retensi-dan-lokasi-operasi-indonesia); aktivasi produksi tetap memerlukan review Legal/Security. Dokumentasi ini menetapkan konvensi implementasi; setiap tabel/function baru harus menyebut owner dalam migration review. Detail versioning, permission dan pengujian function ada di [standar migration/function](database-functions-and-migrations.md) serta [ADR-0004](../adr/0004-versioned-database-functions.md).

## 1. Ownership, schema, dan referensi

Gunakan schema per modul: `identity`, `organization`, `master`, `policy`, `numbering`, `sales`, `purchase`, `credit`, `inventory`, `warehouse`, `finance`, `accounting`, dan schema dukungan yang benar-benar diperlukan. Satu modul memiliki DDL, writer, migrations, audit dan rekonsiliasinya. Runtime role hanya menerima hak minimum pada schema miliknya; migration owner/role berbeda dari runtime role. PostgreSQL memberi kontrol `USAGE` schema dan `GRANT` per objek, sehingga pemisahan ini dapat ditegakkan pada DB, bukan hanya konvensi kode ([PostgreSQL schemas](https://www.postgresql.org/docs/18/ddl-schemas.html), [privileges](https://www.postgresql.org/docs/18/ddl-priv.html)).

Foreign key **di dalam** schema/owner diwajibkan bila relasi sinkron dan stabil. Jangan membuat FK lintas owner atau query SQL langsung ke schema owner lain. Simpan referensi lintas owner sebagai GUID dan validasi lewat API/event snapshot owner; jalankan reconciler untuk orphan/lag. Pengecualian `finance`↔`accounting` pada MVP memerlukan ADR, role terbatas, transaksi lokal dan test invoice→journal. Semua tabel transaksi yang bergantung entity mencantumkan `tenant_guid uuid` dan `legal_entity_guid uuid`. Untuk **relasi entitas bisnis**, akhiran `_guid` berarti identitas lintas owner dan `_id` berarti `bigint` FK lokal dalam owner yang sama. Identifier protokol yang sudah baku seperti `event_id`, `request_id`, `correlation_id` dan `trace_id` adalah pengecualian bernama; tipe dan formatnya dijelaskan dalam kontrak. API menampilkan `guid`, bukan PK lokal.

## 2. Kolom standar dan pengecualian

| Kolom | Tipe dan aturan | Makna |
|---|---|---|
| `id` | `bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY` | PK lokal satu tabel; tidak keluar melalui API/event |
| `guid` | `uuid NOT NULL DEFAULT uuidv7()` + `UNIQUE` | Identitas publik/lintas owner, immutable |
| `created_at` | `timestamptz NOT NULL DEFAULT now()` | Instant pembuatan pada DB |
| `created_by` | `uuid NOT NULL` | GUID actor manusia/service yang membuat |
| `updated_at` | `timestamptz NOT NULL DEFAULT now()` | Instant perubahan terakhir; saat insert sama dengan created |
| `updated_by` | `uuid NOT NULL` | GUID actor perubahan terakhir; saat insert sama dengan created |
| `deleted_at` | `timestamptz NULL` | Soft delete hanya jika kelas tabel mengizinkan |
| `deleted_by` | `uuid NULL` | GUID actor soft delete; wajib berpasangan dengan `deleted_at` |
| `version` | `bigint NOT NULL DEFAULT 1 CHECK (version > 0)` | Optimistic concurrency pada baris agregat; naik tepat satu per mutasi berhasil |

PostgreSQL 18 mendukung identity column dan fungsi native `uuidv7()`; UUIDv7 time-ordered membantu pola indeks, tetapi waktu yang dikodekan di dalamnya **bukan** `created_at`, `business_date`, atau bukti waktu transaksi ([CREATE TABLE](https://www.postgresql.org/docs/18/sql-createtable.html), [UUID functions](https://www.postgresql.org/docs/18/functions-uuid.html)). `guid` selalu unique termasuk row soft-deleted dan tidak pernah didaur ulang. UUIDv4 yang sudah ada tetap valid untuk import/kompatibilitas. GUID bukan kontrol akses: authorization tetap memeriksa principal, permission dan scope setiap operasi ([OWASP API1:2023](https://api-security.owasp.org/editions/2023/en/0xa1-broken-object-level-authorization/)).

Tabel **mutable** (master, draft, balance, projection, idempotency record, outbox delivery state) memakai seluruh kolom standar kecuali `deleted_*` bila penghapusan dilarang. `created_by`/`updated_by` harus berasal dari actor terverifikasi; job menggunakan GUID service principal yang terdaftar, bukan `NULL` atau actor palsu. Bila migrasi historis tidak memiliki actor asli, gunakan principal migrasi dan simpan provenance sumber secara terpisah.

Tabel **immutable/append-only** (posted `inventory_movements`, `journal_lines`, `audit_events`, fakta event) tetap mempunyai `id`, `guid`, `created_at`, `created_by`, tenant/entity bila relevan, dan identitas source. Tabel ini **tidak** mempunyai `updated_*`/`deleted_*` dan umumnya tidak perlu `version` mutable: perubahan dilakukan melalui movement/reversal/event baru. Jika mekanisme umum memerlukan `version`, nilainya tetap `1` dan tidak digunakan untuk update. Jangan membuat soft delete pada ledger/audit hanya agar semua tabel tampak seragam. `outbox` adalah pengecualian berbeda: payload/event immutable, tetapi delivery state/attempt/updated fields dapat berubah; pisahkan payload dari delivery state bila kontrol append-only ketat diperlukan.

Policy finansial/stok disimpan sebagai `policy_versions` immutable dan `policy_activations` per tenant/legal entity/type dengan `effective_from/to`, approver GUID berbeda, simulation hash, dan regulation/ADR reference. Interval aktif untuk tipe/scope yang sama tidak boleh overlap; dokumen menyimpan GUID versi yang dipakai. Publish/activate menulis audit dan outbox. Bila tidak ada policy aktif atau ada dua kandidat, command mengembalikan `POLICY_NOT_ACTIVE`/`POLICY_AMBIGUOUS` sebelum mengubah ledger. Nilai default dan gate aktivasi ada di [keputusan bisnis MVP](../decisions/mvp-business-policy.md#aturan-aktivasi-dan-bukti-penutupan).

## 3. Contoh DDL untuk agregat mutable

Contoh lengkap ini memakai Sales Order. Kode status, nilai uang, dan policy bisnis masih mengikuti kontrak/PRD; migration nyata menambah constraint yang sesuai keputusan final. `tenant_guid`, `legal_entity_guid`, `customer_account_guid`, dan seluruh actor UUID adalah GUID eksternal yang tidak mempunyai FK lintas owner.

```sql
CREATE SCHEMA IF NOT EXISTS sales;

CREATE TABLE sales.sales_orders (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    guid              uuid NOT NULL DEFAULT uuidv7(),
    tenant_guid       uuid NOT NULL,
    legal_entity_guid uuid NOT NULL,
    customer_account_guid uuid NOT NULL,
    document_no       text,
    status            text NOT NULL,
    business_date     date,
    currency_code     text NOT NULL,
    created_at        timestamptz NOT NULL DEFAULT now(),
    created_by        uuid NOT NULL,
    updated_at        timestamptz NOT NULL DEFAULT now(),
    updated_by        uuid NOT NULL,
    deleted_at        timestamptz,
    deleted_by        uuid,
    version           bigint NOT NULL DEFAULT 1,
    CONSTRAINT sales_orders_guid_uq UNIQUE (guid),
    CONSTRAINT sales_orders_scope_id_uq UNIQUE (tenant_guid, legal_entity_guid, id),
    CONSTRAINT sales_orders_currency_chk CHECK (currency_code ~ '^[A-Z]{3}$'),
    CONSTRAINT sales_orders_version_chk CHECK (version > 0),
    CONSTRAINT sales_orders_deleted_pair_chk
        CHECK ((deleted_at IS NULL) = (deleted_by IS NULL)),
    CONSTRAINT sales_orders_deleted_time_chk
        CHECK (deleted_at IS NULL OR deleted_at >= created_at)
);

-- Nomor final tidak boleh dipakai ulang setelah cancel/void/soft delete.
CREATE UNIQUE INDEX sales_orders_document_no_uq
    ON sales.sales_orders (tenant_guid, legal_entity_guid, document_no)
    WHERE document_no IS NOT NULL;

CREATE INDEX sales_orders_list_idx
    ON sales.sales_orders
       (tenant_guid, legal_entity_guid, status, business_date DESC, id DESC)
    WHERE deleted_at IS NULL;

CREATE TABLE sales.sales_order_lines (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    guid             uuid NOT NULL DEFAULT uuidv7() UNIQUE,
    tenant_guid      uuid NOT NULL,
    legal_entity_guid uuid NOT NULL,
    sales_order_id   bigint NOT NULL,
    line_no          integer NOT NULL CHECK (line_no > 0),
    sku_guid         uuid NOT NULL,
    qty_base         numeric(20,6) NOT NULL CHECK (qty_base > 0),
    created_at       timestamptz NOT NULL DEFAULT now(),
    created_by       uuid NOT NULL,
    updated_at       timestamptz NOT NULL DEFAULT now(),
    updated_by       uuid NOT NULL,
    deleted_at       timestamptz,
    deleted_by       uuid,
    version          bigint NOT NULL DEFAULT 1 CHECK (version > 0),
    CONSTRAINT sales_order_lines_scope_fk
        FOREIGN KEY (tenant_guid, legal_entity_guid, sales_order_id)
        REFERENCES sales.sales_orders (tenant_guid, legal_entity_guid, id),
    CONSTRAINT sales_order_lines_deleted_pair_chk
        CHECK ((deleted_at IS NULL) = (deleted_by IS NULL)),
    CONSTRAINT sales_order_lines_line_uq
        UNIQUE (sales_order_id, line_no)
);
```

`UNIQUE (tenant_guid, legal_entity_guid, id)` memungkinkan composite FK child memastikan tenant/entity sama; ini redundan terhadap PK tetapi sengaja untuk mencegah cross-scope relation lokal. `sku_guid` merujuk Master owner sehingga tidak dibuat FK. Pada tabel master yang `code` boleh dipakai ulang sesudah soft delete, gunakan unique **partial** pada `(tenant_guid, code) WHERE deleted_at IS NULL`; pada nomor dokumen final **jangan** partial terhadap `deleted_at`. PostgreSQL mendukung partial index dan unique constraint/index ([CREATE INDEX](https://www.postgresql.org/docs/18/sql-createindex.html), [constraints](https://www.postgresql.org/docs/18/ddl-constraints.html)).

`sales_orders.version` adalah versi agregat yang dikirim sebagai ETag. Setiap insert/update/soft delete line harus mengunci root, memvalidasi expected root version, dan menaikkan root version tepat sekali dalam transaksi yang sama dengan mutasi line, audit, dan outbox. `sales_order_lines.version` hanya untuk concurrency row internal; nilainya tidak menggantikan ETag root. Jika satu command mengubah beberapa line, root tetap naik sekali. Dengan demikian submit dari layar lama gagal CAS meskipun header tidak berubah.

## 4. Mutasi, concurrency, dan transaksi

Setiap update agregat wajib compare-and-swap berdasarkan scope dan `version`; 0 row berarti tidak ditemukan/di luar scope atau versi usang, lalu dibedakan dengan lookup scoped yang aman. Ubah `updated_*` dan `version` dalam statement yang sama. Contoh statement di dalam `sql.Tx` Go:

```sql
UPDATE sales.sales_orders
SET status = $1,
    updated_at = now(),
    updated_by = $2,
    version = version + 1
WHERE id = $3
  AND tenant_guid = $4
  AND legal_entity_guid = $5
  AND version = $6
  AND deleted_at IS NULL
RETURNING guid, version, updated_at;
```

Soft delete hanya untuk draft/master yang diizinkan: set `deleted_at`, `deleted_by`, `updated_at`, `updated_by`, `version + 1` dalam transaksi yang juga menulis audit. Baris yang telah direferensikan dinonaktifkan; posted financial/stock document tidak dihapus dan hanya dikoreksi dengan reversal/source baru. Query normal menyaring `deleted_at IS NULL`; akses histori memakai izin khusus dan tetap scoped. Jangan otomatis `ON DELETE CASCADE` untuk fakta bisnis.

Inventory reservation, balance, nomor dokumen dan period close memerlukan lock row/constraint serta urutan penguncian konsisten. `SELECT ... FOR UPDATE` melindungi row selama transaksi; PostgreSQL `READ COMMITTED` dapat melihat snapshot berbeda antar statement, sehingga invariant harus dicek ulang setelah lock, bukan hanya sebelum transaksi ([row locks](https://www.postgresql.org/docs/18/explicit-locking.html), [isolation](https://www.postgresql.org/docs/18/transaction-iso.html)). `SKIP LOCKED` hanya untuk worker queue/outbox, bukan query stock/credit otoritatif karena ia memberi pandangan yang tidak lengkap ([SELECT locking clause](https://www.postgresql.org/docs/18/sql-select.html)). Tangani deadlock/serialization (`40P01`, `40001`) dengan retry **seluruh** transaksi yang idempotent dan berbatas, bukan mengulang satu SQL di tengah transaksi gagal.

Satu transaction owner menyimpan perubahan state, audit kritikal, idempotency result, dan outbox. Setiap command bisnis membawa `business_operation_guid` stabil yang dibuat sekali pada sumber dan dipakai ulang pada retry. Registry/hasil command memiliki `UNIQUE (tenant_guid, business_operation_guid)` permanen. Untuk movement/posting parsial, owner juga mendefinisikan source portion key unik, misalnya `(tenant_guid, source_type, source_guid, source_line_guid, action, source_portion_guid, movement_leg)`; seluruh komponen key wajib non-null dan stabil pada replay. `movement_leg` membedakan beberapa baris ledger yang sah dari satu operasi. `source_version` hanya untuk CAS/urutan state, **bukan** bagian dari key deduplikasi: menaikkan versi tidak boleh mengizinkan aksi bisnis yang sama diposting lagi. Nomor final dialokasikan melalui counter row atomik pada submit/issue/post; gap tidak diisi ulang. Jangan mengandalkan Redis lock untuk integritas. `CHECK` cocok untuk invariant satu row (misalnya `sellable >= 0`, `allocated <= reserved`); balance journal lintas line tidak bisa dijamin oleh `CHECK` biasa, sehingga posting memvalidasi debit=credit dalam transaksi owner dan daily reconciliation menguji hasilnya ([PostgreSQL constraints](https://www.postgresql.org/docs/18/ddl-constraints.html)).

## 5. Audit dan logging

Audit durable berbeda dari log observability. Satu command berprivilege, perubahan master sensitif, approval, stock movement, posting, close/reopen, login/revoke, dan pengunduhan data sensitif merekam actor, target, aksi, before/after yang sudah dimasking, reason bila perlu, source, waktu, request/correlation ID, IP/device yang sesuai policy. Audit bisnis ditulis dalam transaksi yang sama dengan mutasi; kegagalan audit harus menggagalkan command kritikal. Log aplikasi JSON di stdout menghubungkan `trace_id`/`span_id`, tetapi tidak menjadi satu-satunya bukti audit ([OpenTelemetry log correlation](https://opentelemetry.io/docs/specs/otel/logs/)). Contoh DDL berikut memuat field minimum PRD §39; `guid` pada row audit diekspor sebagai `event_id` dalam kontrak audit.

```sql
CREATE TABLE sales.audit_events (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    guid              uuid NOT NULL DEFAULT uuidv7() UNIQUE,
    tenant_guid       uuid NOT NULL,
    legal_entity_guid uuid,
    scope_guids       jsonb NOT NULL DEFAULT '{}'::jsonb,
    module            text NOT NULL,
    target_type       text NOT NULL,
    target_guid       uuid,
    action            text NOT NULL,
    actor_guid        uuid,
    actor_type        text NOT NULL CHECK (actor_type IN ('USER', 'SERVICE', 'SYSTEM', 'ANONYMOUS')),
    delegator_guid    uuid,
    source            text NOT NULL,
    outcome           text NOT NULL CHECK (outcome IN ('SUCCESS', 'DENIED', 'FAILED')),
    policy_version    text,
    occurred_at       timestamptz NOT NULL,
    recorded_at       timestamptz NOT NULL DEFAULT statement_timestamp(),
    created_at        timestamptz NOT NULL DEFAULT now(),
    created_by        uuid NOT NULL,
    request_id        text,
    correlation_id    uuid,
    trace_id          text,
    ip_address        inet,
    device_id         text,
    user_agent        text,
    reason            text,
    before_redacted   jsonb,
    after_redacted    jsonb,
    CONSTRAINT audit_events_actor_chk
        CHECK (actor_type = 'ANONYMOUS' OR actor_guid IS NOT NULL)
);

CREATE INDEX sales_audit_target_idx
    ON sales.audit_events (tenant_guid, target_type, target_guid, recorded_at DESC);
```

Tidak ada `UPDATE`/`DELETE` untuk runtime role pada audit/ledger; migration role berbeda dari aplikasi. Bahkan bila row memiliki `id`, `guid`, dan `created_at`, append-only tidak mempunyai `deleted_at` atau jalur update. `recorded_at` memakai awal statement insert DB; `created_at` adalah metadata pembuatan row dengan waktu awal transaksi. PostgreSQL membedakan `statement_timestamp()` dari `now()`/awal transaksi, yang dapat berbeda jika transaksi memuat beberapa statement ([fungsi waktu PostgreSQL](https://www.postgresql.org/docs/18/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT)). Outbox event juga mengisi `recorded_at` dengan `statement_timestamp()`. `scope_guids` hanya berisi pasangan nama scope dan GUID valid yang diizinkan schema, bukan payload bebas/PII. `actor_guid` dan `target_guid` dapat NULL untuk percobaan login anonim yang belum memiliki identitas/target terverifikasi; `created_by` tetap GUID service principal penulis audit. Pada command langsung `actor_guid` dan `created_by` sama, tetapi dapat berbeda saat worker mencatat aksi dari principal lain. Identitas asal harus disalin dari konteks tepercaya, bukan dari body request bebas.

Audit membaca PII hanya menurut izin; jangan simpan secret, token, password, nomor rekening utuh, atau payload mentah yang tidak dibutuhkan. Batasi dan sanitasi `user_agent`/`reason`; catat usaha login tanpa username mentah. Retention, legal hold, erasure/masking dan akses auditor mengikuti [jadwal baseline G-16](../decisions/mvp-business-policy.md#g-16oq-09--data-retensi-dan-lokasi-operasi-indonesia) dan policy legal entity yang diaktifkan. Audit database administrator/DDL memerlukan log database/infrastruktur terpisah karena app audit tidak dapat menangkap perubahan di luar jalur aplikasi.

Untuk tamper evidence, proses segel mengurutkan event secara deterministik menurut `(recorded_at, id)`, melakukan canonical serialization atas field audit yang tersimpan, lalu membuat hash berantai per batch/partisi. Metadata append-only menyimpan `partition_key`, `batch_no`, `first_event_guid`, `last_event_guid`, `previous_digest`, `batch_digest`, dan `signature_ref`; kombinasi partisi dan nomor batch unik. Digest harian ditandatangani dan disimpan di immutable object storage. Restore drill serta sampling bulanan memverifikasi rantai dan tanda tangan; rancangan partisi/late arrival ditutup dalam ADR sebelum produksi.

## 6. Tipe data, waktu, dan nilai finansial

- Instant: `timestamptz` dan API UTC. PostgreSQL menyimpan instant `timestamp with time zone` dalam UTC dan menampilkan sesuai timezone sesi; `business_date date` serta IANA timezone legal entity disimpan terpisah agar akuntansi dan filter lokal benar ([date/time types](https://www.postgresql.org/docs/18/datatype-datetime.html)). Event mempunyai `occurred_at` dan `recorded_at`; jangan memakai UUID timestamp atau `created_at` sebagai tanggal bisnis.
- Nominal, harga dan qty: `numeric(20,6)` sebagai baseline PRD; FX `numeric(24,10)`. Decimal di Go/JSON (string), tanpa `float32/float64` pada jalur uang/stok. `numeric` memberi presisi eksak dan direkomendasikan PostgreSQL untuk nominal uang, tetapi lebih mahal dari integer/float; ukur beban pada query panas ([numeric types](https://www.postgresql.org/docs/18/datatype-numeric.html)).
- Simpan currency code, original amount, base amount, FX source/time/rate snapshot, UOM asli dan base qty/conversion version. Validasi skala/range **sebelum** write agar pembulatan implisit kolom `numeric(p,s)` tidak mengubah nilai diam-diam. Titik rounding line discount→taxable base→tax→total dan residual account mengikuti PRD §22; default `HALF_UP` dan aturan residual dijelaskan di [G-04](../decisions/mvp-business-policy.md#g-04--pajak-indonesia-dan-pembulatan), dengan aktivasi Tax/Finance per legal entity.
- Quantity stok per base UOM; `stock_balance` memakai key unik `(legal_entity_guid, warehouse_guid, stock_point_guid, sku_guid, lot_guid/serial_guid, ownership, inventory_status, base_uom_guid)` dengan penanganan `NULL` yang eksplisit. Jangan mengandalkan `UNIQUE` biasa bila komponen nullable: gunakan nilai non-null kanonik, `NULLS NOT DISTINCT`, atau key normalisasi yang disetujui. `reserved` dan `allocated` bukan dua pengurang stok. Movement immutable dan balance dihitung/diubah dalam satu transaksi; rekonsiliasi dapat membangun ulang balance dari ledger.
- Jurnal posted punya header+line append-only, source unik, legal entity, currency/base amounts, rule version, period dan reversal link. Debit=credit per currency/base setelah rounding; period closed menolak post/backdate tanpa reopen berizin. Jangan memperbarui journal posted untuk koreksi.

## 7. Indeks, partisi, dan query

Setiap indeks punya query/predicate pemakai, owner dan bukti `EXPLAIN (ANALYZE, BUFFERS)` pada data representatif. Indeks list memulai dengan `tenant_guid`/`legal_entity_guid`, lalu filter yang selektif, waktu/status dan stable tie-break `id`; jangan menambah indeks untuk setiap kolom secara otomatis. Unique pada source/idempotency, nomor dokumen dan active master code adalah constraint bisnis. PostgreSQL membuat indeks otomatis untuk PK/UNIQUE, jadi jangan duplikasi ([unique indexes](https://www.postgresql.org/docs/18/indexes-unique.html)). Search/proyeksi tetap menerapkan scope sebelum hasil.

Partisi ledger hanya setelah profil ukuran, latency, retention dan query menunjukkan manfaat. PostgreSQL mengharuskan kolom partition key masuk ke PK/UNIQUE pada parent partitioned table; desain `id` PK tunggal dan `guid UNIQUE` contoh di atas **tidak dapat langsung** dipindah ke partition-by-date tanpa desain identitas baru. Sebelum partisi, buat ADR untuk composite key/lookup registry yang menjaga global GUID dan source uniqueness, plus rehearsal query/migrasi/restore ([partitioning limitations](https://www.postgresql.org/docs/18/ddl-partitioning.html)). Pembuatan indeks besar di produksi mempertimbangkan `CREATE INDEX CONCURRENTLY` dan migration non-transactional terpisah, karena normal index build memblokir write ([CREATE INDEX](https://www.postgresql.org/docs/18/sql-createindex.html)).

## 8. Migrations, hak akses, dan operasi

Migration per schema di `backend/database/migrations/<schema>/000001_name.up.sql` dan `.down.sql` bila benar-benar reversible. Query sqlc per schema di `backend/database/queries/<schema>/`; konfigurasi dan output Go mengikuti [ADR-0006](../adr/0006-database-sql-layout.md). Nomor urut immutable; migration yang sudah dipakai tidak diedit. Setiap perubahan punya expand→backfill/checkpoint→switch readers/writers→contract plan, kompatibilitas deploy bergulir, estimasi lock/durasi, backup/restore atau forward-fix untuk langkah irreversible, dan bukti dry run pada volume relevan. `NOT NULL`, unique/index, backfill dan perubahan tipe besar dijadwalkan dengan strategi online yang diuji. Satu runner/lock migration per schema; runtime role tidak boleh DDL, superuser, `BYPASSRLS`, atau owner tabel. Rotasi credential dan secret store dikelola infra.

**Function PostgreSQL juga dideploy melalui migration owner**, termasuk `CREATE OR REPLACE FUNCTION`, `REVOKE/GRANT`, trigger dan perubahan permission. Backend memakainya untuk invariant lokal multi-statement yang harus atomik (misalnya stock movement, credit reservation, balanced journal), sedangkan orkestrasi/otorisasi dan saga tetap di Go. Function/trigger yang sudah ada pada SQL awal tidak ditulis ulang; perubahan hardening dibuat dalam migration berikutnya. Aturan signature v1/v2, `SECURITY INVOKER`, `search_path`, volatility, SQLSTATE dan tes PostgreSQL asli ada di [standar khusus](database-functions-and-migrations.md).

Row-level security PostgreSQL dapat menjadi lapisan tambahan bagi tabel berisiko tinggi, tetapi hanya jika role runtime, `FORCE ROW LEVEL SECURITY`, identitas tenant pada koneksi pool/transaction dan fail-closed policy diuji. RLS bukan pengganti otorisasi permission/scope di aplikasi; owner/superuser dapat melewati policy tertentu menurut konfigurasi ([PostgreSQL RLS](https://www.postgresql.org/docs/18/ddl-rowsecurity.html)). Backup dengan PITR, restore drill, RPO/RTO, retention dan legal hold mengikuti PRD §§45, 48, 52. Kunci keberhasilan rilis adalah hasil rekonsiliasi stock ledger↔balance, AR/AP↔control account, dan debit↔credit, bukan keberhasilan migration saja.

## 9. Gerbang DDL review

Sebelum menambah tabel/kolom/function, reviewer memeriksa: owner/schema dan akses role; kelas mutable/immutable; `id`/`guid` dan actor; tenant/entity scope; FK lokal/foreign GUID; nullability dan `CHECK`; uniqueness termasuk soft delete dan nullable key; version CAS; source/idempotency; audit dan retention; PII/encryption; decimal/timezone; indeks berdasarkan query; function signature/volatility/grant/search path; migrasi serta rollback/forward-fix; test concurrency dan rekonsiliasi bila data stok/keuangan. Pengecualian ditulis dalam ADR serta kontrak, bukan komentar SQL tersembunyi.
