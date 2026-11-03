# Runbook migration database — B-02.1

Berlaku untuk PostgreSQL 18, empat owner pada `backend/database/plan.json`, dan executable `backend/golang/tools/migrate`. SQL baseline tidak diedit. [ADR-0007](../adr/0007-migration-runner.md) menetapkan ledger, lock, role dan pemulihan; [standar DB](../engineering/database-standards.md) tetap berlaku.

## 1. Persiapan lokal

Jalankan PostgreSQL dari Compose. Bootstrap di bawah hanya untuk lingkungan disposable lokal/CI: semua password adalah fixture `erp_local_only`. Script membuat database dan role bila belum ada serta menerapkan hak koneksi; script tidak menghapus atau mereset database. Script ini memerlukan administrator, sedangkan runner memakai role deploy non-superuser. Provisioning produksi memakai secret manager dan administrator platform yang ditunjuk.

```sh
podman-compose -f infra/compose/compose.yaml up -d postgres
PGPASSWORD=erp_local_only psql -h 127.0.0.1 -p 15432 -U erp_local -d erp_local \
  -f backend/database/bootstrap/000001_local_owners.sql
(cd backend/golang/tools/migrate && go build -o /tmp/erp-migrate ./cmd/migrate)
```

| Owner | Database | Role deploy | Role aplikasi |
|---|---|---|---|
| platform | erp_platform | erp_platform_deploy | erp_platform_runtime |
| commercial | erp_commercial | erp_commercial_deploy | erp_commercial_runtime |
| operations | erp_operations | erp_operations_deploy | erp_operations_runtime |
| finance | erp_finance | erp_finance_deploy | erp_finance_runtime |

Semua role deploy/runtime berdiri sendiri tanpa membership role lain; bukan superuser, CREATEDB, CREATEROLE, REPLICATION, atau BYPASSRLS. Runtime hanya CONNECT ke database owner, tanpa CREATE/TEMP atau akses ledger. Deploy mendapat CREATE dalam database owner, bukan kuasa membuat database/role. Runtime belum dipakai oleh skeleton HTTP B-01; integrasi koneksi bisnis akan dilakukan oleh slice terkait.

## 2. Status dan apply

Contoh credential di bawah hanya fixture lokal. Di lingkungan lain, isi `ERP_MIGRATION_DSN` melalui mekanisme secret platform, bukan argumen CLI atau file Git.

```sh
export ERP_MIGRATION_DSN='postgres://erp_platform_deploy:erp_local_only@127.0.0.1:15432/erp_platform?sslmode=disable'
/tmp/erp-migrate -owner platform -action status
/tmp/erp-migrate -owner platform -action apply -timeout 2m
/tmp/erp-migrate -owner platform -action status
```

Ulangi dengan owner/database/role yang sesuai. Runner membaca seluruh SQL ke memori, menghitung SHA-256, memvalidasi history semua schema owner, dan mengambil lock session per schema dengan urutan nama. Apply mengikuti dependency manifest: runtime owner lebih dulu, lalu domain; Finance memakai `finance_runtime` → `accounting` → `finance`. Ledger menyimpan `(schema_name, version, name, checksum, applied_at, applied_by, duration_ms)`. SQL dan ledger commit dalam transaksi yang sama per file. Identitas ledger tidak bergantung lokasi absolut checkout.

Log JSON `migration_started`, `migration_applied`, `migration_failed`, `migration_complete` memberikan schema/versi/checksum/durasi/SQLSTATE. Kegagalan tidak menulis row history applied. Pengiriman log ke collector mengikuti platform deploy; file log/DSN tidak dimasukkan Git. `status` adalah pembacaan administratif dan tidak membuat schema/history; ia tetap memakai lock serta role deploy agar snapshot status konsisten dengan runner lain.

## 3. Menambah migration

1. Tambah nomor berikutnya di `migrations/<schema>/`, tanpa mengubah file applied. Daftarkan schema/dependency baru di `plan.json`; jangan menambahkan schema tanpa owner.
2. DDL, function, trigger dan grant disimpan dalam file schema yang sama. Dependency function metadata berada di runtime schema owner yang sama. Untuk function baru, cabut PUBLIC dan grant EXECUTE eksplisit; default EXECUTE PUBLIC sudah dicabut oleh runner sebelum baseline.
3. Tinjau lock/durasi dan data lama. Trigger metadata berlaku untuk tabel mutable yang sudah ada; ia menjaga identity/scope/created fields immutable, insert version 1, update version +1, actor dan timestamp. Service masih wajib scoped CAS dan actor terverifikasi. Tabel audit/ledger bisnis hanya SELECT/INSERT bagi runtime; delivery state outbox memakai grant kolom terbatas.
4. Jalankan fresh apply, upgrade, privilege, failure/concurrency dan restore yang relevan. Query sqlc tetap di `queries/<schema>/`; regenerate serta commit output adapter.

Sepuluh migration hardening B-02.1 menambah trigger/grant dan kolom audit; tidak ada penghapusan data. Audit baseline mendapat `module='legacy'`, `source='legacy-baseline'` sebagai provenance yang eksplisit. Insert audit berikutnya wajib mengisi module/source. Tidak ada endpoint audit baru dalam slice ini.

## 4. Kegagalan dan pemulihan

| Situasi | Tindakan dan bukti |
|---|---|
| Lock sibuk/deadline | Invocation keluar nonzero. Pastikan runner lain selesai; ulangi status/apply. Jangan menghapus ledger atau memaksa versi. Session lock lepas saat koneksi ditutup. |
| SQL file aktif gagal | PostgreSQL rollback SQL dan ledger file itu; file sebelumnya tetap committed. Periksa SQLSTATE di log dan status. Perbaiki file hanya jika belum applied di lingkungan mana pun, lalu ulangi. Jika sudah applied di tempat lain, pertahankan checksum dan buat perbaikan additive atau perbaiki prerequisite lingkungan. |
| Koneksi putus saat commit | Status hasil commit mungkin belum diketahui pemanggil. Sambungkan ulang dan jalankan status/apply: row history yang commit akan di-skip; transaksi yang rollback akan diulang. |
| Checksum/nama/file applied berbeda atau hilang | Restore checkout/artifact SQL yang cocok dengan ledger. Jangan rewrite checksum agar lulus. Investigasi perubahan tanpa otorisasi. |
| Schema lama tanpa ledger | Runner menolak auto-adopt. Inventarisasi objek, pemilik, versi dan checksum; susun migrasi/adopsi yang direview terpisah. Exception baseline finance hanya diterima ketika accounting/000001 sudah tercatat. |
| Upgrade berhasil tetapi kode perlu rollback | Gunakan binary aplikasi yang kompatibel dengan schema expand. Jangan down/drop data posted. Buat forward-fix baru untuk grant/function/metadata bila perlu. |

Untuk perubahan yang membutuhkan restore, ambil checkpoint, restore ke database baru, verifikasi data/metadata/ledger/ACL lalu ulangi runner. Tes B-02.1 memakai `pg_dump --format=custom` dan `pg_restore --exit-on-error` untuk empat owner; setelah restore, runner harus no-op dan runtime tetap tidak dapat memutasi audit. Ini bukti pemulihan migration pada fixture kecil. Backup terjadwal, PITR, retensi, replay event dan RPO/RTO tetap scope B-02.3.

## 5. Bukti CI dan batas

Job `database` menjalankan PostgreSQL 18.1, provisioning fixture, test Go/integrasi, build CLI, apply/rerun/status untuk keempat owner. Job `contracts` menjaga 11 checksum baseline; job `sqlc` memeriksa drift generated Go. Lihat [bukti B-02.1](../roadmap/b-02-1-evidence.md). B-02.2, B-02.3 dan gate G1 tetap terbuka.
