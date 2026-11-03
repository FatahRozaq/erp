# B-02.1 — Bukti migration/function dan metadata per owner

**Verifikasi lokal: 3 November 2026.** Scope hanya B-02.1. Branch `codex/feature/b-02-1-migration-runner` dibuat dari `main` terbaru `36b75c7`; fetch ulang pada tanggal verifikasi masih menunjuk baseline yang sama. B-02 keseluruhan, B-02.2, B-02.3 dan G1 tetap terbuka. Reviewer DBA/domain aktual tetap perlu review sebelum merge.

## Artefak dan acceptance

| Acceptance | Implementasi / bukti |
|---|---|
| Empat owner dan urutan dependency | [Manifest](../../backend/database/plan.json), validasi graph dan file; `finance_runtime` → `accounting` → `finance`, termasuk accounting/000001 sebelum finance/000001 sesuai ADR-0006 |
| Runner deploy tersendiri | [Module Go](../../backend/golang/tools/migrate/README.md), CLI apply/status, DSN dari env, deadline/signal; bukan startup service |
| Checksum, lock dan versi | SHA-256 dari bytes SQL, session advisory lock per schema, ledger privat, SQL+history atomic per file; missing/renamed/checksum/gap gagal sebelum pending DDL |
| Role terpisah | [Bootstrap lokal](../../backend/database/bootstrap/000001_local_owners.sql); delapan role deploy/runtime, empat DB; runner menolak role elevated/membership dan runtime CREATE/TEMP |
| Metadata dan audit | Sepuluh migration tambahan; trigger identity/scope/created immutable, version +1, actor/timestamp, delete actor; audit append-only dan provenance legacy; service tetap wajib memverifikasi actor dan scoped CAS |
| Function/grant | SECURITY INVOKER, fixed search_path, PUBLIC EXECUTE dicabut, grant eksplisit; runtime dilarang DDL/ledger/audit mutation/immutable ledger mutation; kolom payload outbox tidak dapat diperbarui |
| Kompatibilitas baseline | `scripts/check_migration_inventory.py`: **11 baseline terjaga, 21 total**; tidak mengubah bytes migration yang sudah dijalankan |
| Upgrade/pemulihan | Baseline-only → hardening pada empat owner, data/audit lama dipertahankan; pg_dump custom → pg_restore database baru → runner no-op dan ACL tetap berlaku |
| Query aktif sqlc | sqlc **v1.31.1** generate berhasil; adapter master tidak drift |
| Operasional | [ADR-0007](../adr/0007-migration-runner.md), [runbook](../operations/database-migrations.md), CI job database serta CODEOWNERS diperbarui |

Sepuluh file baru: `000002_metadata_privileges.up.sql` pada platform_runtime, commercial_runtime, operations_runtime, finance_runtime, master, purchase, sales, accounting dan finance; `inventory/000003_metadata_privileges.up.sql`. Baseline lain tetap utuh. Grant bisnis berikutnya akan mengikuti slice pemiliknya; keberadaan tabel outbox/inbox belum membuktikan relay/consumer berjalan.

## Lingkungan dan perintah yang benar-benar dijalankan

- PostgreSQL **18.1** pada container lokal `erp-b021-postgres`, bind `127.0.0.1:25432`, data/credential sintetis. Client pg_dump/pg_restore **18.6**; Go module **1.25.10**, pgx **v5.11.0**.
- Suite integration membuat database bernama acak khusus tes dan menghapus hanya database fixture itu saat cleanup. Empat database owner lokal dipertahankan untuk smoke CLI.
- Perintah Go dari `backend/golang/tools/migrate/`:

```sh
gofmt -l cmd internal
go vet ./...
ERP_MIGRATION_TEST_DSN='postgres://erp_local:erp_local_only@127.0.0.1:25432/erp_local?sslmode=disable' \
  go test -v -count=1 -timeout=3m ./...
go build -o /tmp/erp-migrate ./cmd/migrate
```

Hasil: format bersih, vet/build lulus; **12 test top-level lulus** (8 PostgreSQL + 4 unit, termasuk subtest empat owner), suite `internal/migration` **7.787 detik**. Environment DSN di atas sengaja berisi fixture lokal, bukan credential produksi. Tanpa `ERP_MIGRATION_TEST_DSN`, integration test di-skip; unit-only tidak boleh dipakai sebagai bukti PostgreSQL.

| Test PostgreSQL | Bukti yang diamati |
|---|---|
| `TestPostgresFreshOwnersAndPrivileges` | Status tidak memutasi; fresh apply/rerun empat owner; checksum/actor ledger; runtime DDL/TEMP/ledger/SET ROLE/cross-owner connect ditolak; audit/immutable facts/outbox payload dilindungi |
| `TestPostgresMetadataAndAtomicAudit` | Invalid initial/update metadata ditolak; update/version dan soft delete benar; kegagalan audit menggagalkan mutasi bisnis dalam transaksi yang sama |
| `TestPostgresUpgradeAndRestoreAllOwners` | Baseline-only, legacy row, upgrade tanpa kehilangan data; dump/restore nyata ke DB baru; ledger/ACL/provenance preserved, rerun no-op |
| `TestPostgresFailureRecoveryAndChecksums` | File applied diubah/dihapus/rename ditolak; seluruh history diperiksa sebelum DDL pending; DDL gagal rollback tanpa row ledger; retry file belum applied berhasil; log meredaksi SQL/detail sensitif |
| `TestPostgresCancellationAndConcurrentRunners` | Cancellation menggagalkan transaksi; dua runner hanya apply sekali; lock timeout lalu recovery setelah release |
| `TestPostgresUnmanagedSchemaRefused` | Schema tanpa ledger ditolak, tidak auto-adopt |
| `TestPostgresFiscalPeriodFunction` | Isolation tidak tepat `25000`, overlap `23514`, transaksi SERIALIZABLE bersaing menghasilkan satu fakta dan conflict `40001` |
| `TestPostgresRoleMembershipAndDefaultPrivileges` | Runtime diberi membership berprivilege ditolak; setelah revoke apply berhasil; function baru tidak otomatis executable oleh PUBLIC/runtime |

Unit test memeriksa urutan/21 file, dependency invalid/cycle/duplicate, schema tidak terdaftar, filename/gap/symlink, serta kepemilikan transaksi dan quoted SQL/function bodies.

Dari root repository, smoke CLI `-action apply` dan `-action status` diulang untuk platform/commercial/operations/finance pada database lokal yang sebelumnya sudah di-apply. Semuanya exit 0, **applied=0, pending=0**. Fresh apply dibuktikan oleh database disposable suite di atas; smoke ini membuktikan rerun dan ledger bertahan setelah container restart.

```sh
python3 scripts/check_migration_inventory.py
python3 scripts/validate_contracts.py
python3 scripts/validate_backlog.py
(cd backend/database && sqlc generate)
git diff --exit-code -- backend/golang/services/platform/internal/master/adapters/postgres/sqlc
git diff --check
```

Hasil: **11 baseline/21 total**, **16 OpenAPI + 43 event schema + 43 examples**, backlog **38 WO/88 slice/99 requirement**, generated SQL adapter tanpa drift, whitespace bersih. Tidak ada perubahan wire API/event dalam slice ini.

## CI dan batas bukti

[Workflow](../../.github/workflows/ci.yml) menambah job `database` dengan PostgreSQL 18.1, bootstrap sintetis, format/vet/test/build, apply/rerun/status empat owner. Job container menggunakan client PostgreSQL 18.1 agar pg_dump/pg_restore kompatibel dengan service PostgreSQL 18.1. Bukti run hosted dicatat setelah PR berjalan; konfigurasi workflow saja bukan bukti lulus hosted CI.

- Go race detector belum dijalankan berhasil pada host: `CGO_ENABLED=1 go test -race` berhenti karena `gcc` tidak tersedia. Tes konkurensi PostgreSQL di atas benar-benar dijalankan; keduanya jenis bukti berbeda.
- Restore fixture ini membuktikan pemulihan migration/ACL, bukan backup terjadwal, PITR, RPO/RTO atau DR produksi (B-02.3).
- Outbox/JetStream/inbox/DLQ/replay end-to-end tetap **B-02.2**. Authorization tenant/entity/actor aktif dan HTTP business command mengikuti slice berikutnya.
- SQL harus transactional dan trusted/reviewed; tidak mendukung concurrent index/nontransactional DDL atau auto-down. Runner menolak schema unmanaged; adopsi database eksternal membutuhkan rencana tersendiri.
- Provisioning/credential produksi, reviewer domain aktual, dan validasi terhadap volume pilot belum menjadi bukti lokal ini.

**Berikutnya siap secara dependency teknis: B-02.2**, setelah review/merge B-02.1. B-02 tidak dicentang. Penambahan skill atas permintaan pengguna tercatat terpisah pada [inventaris skill](../engineering/agent-skills.md); tidak mengubah scope fitur ERP.
