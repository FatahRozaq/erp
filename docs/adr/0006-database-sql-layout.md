# ADR-0006 — SQL database per schema di luar service Go

**Status:** diterima 30 Oktober 2026. **Owner:** Architecture, Database Lead, Backend Leads. **Mengubah:** lokasi file pada standar repository/backend/database; kepemilikan fakta dan invariant pada ADR-0004 tetap berlaku.

## Keputusan

Semua migration SQL kanonik ditempatkan di `backend/database/migrations/<schema>/`, setara dengan `backend/golang/`. Query bernama untuk sqlc ditempatkan di `backend/database/queries/<schema>/`. Folder mengikuti **nama schema PostgreSQL sebenarnya**, bukan nama service. Schema `platform_runtime`, `commercial_runtime`, `operations_runtime`, dan `finance_runtime` tetap terpisah. Nomor migration, checksum SQL, role deploy, lock, dan history dijaga per schema.

`backend/database/sqlc.yaml` memetakan schema/query aktif ke package Go generated di adapter PostgreSQL service owner. Kode generated hanya akses persistence dan tidak memuat aturan bisnis, authorization, atau transaksi lintas owner. Query ditambah saat use case membutuhkan; sqlc tidak menjadi migration runner dan tidak menggantikan function DB untuk invariant atomik. SQL yang tidak dapat dianalisis sqlc tetap ditangani lewat wrapper typed dan tes PostgreSQL.

## Transisi

Sebelas migration baseline dipindahkan tanpa mengubah byte. Manifest SHA-256 dan pemeriksaan inventaris menunjuk lokasi baru. Semua tautan dokumen, CODEOWNERS, dan CI mengikuti path baru. Tidak ada DDL baru atau eksekusi migration akibat pemindahan folder. Satu pengecualian warisan: `accounting/000001_grni_posting.up.sql` membuat `finance.posting_intents` serta schema `finance`. File ini tetap berada di folder `accounting` untuk menjaga checksum; urutan apply awal adalah `accounting/000001` sebelum `finance/000001`. Migration **baru** harus hanya mengubah schema foldernya sendiri.

Deployment B-02 harus memastikan runner membaca lokasi baru dengan ledger/versi lama yang sama; jangan menerapkan migration lama dua kali. Bila deployment lama sudah memuat path di ledger, lakukan pemetaan path terverifikasi sebelum menyalakan runner baru. Rollback kode dapat menunjuk kembali lokasi lama dari commit sebelumnya tanpa mengubah database.

## Alasan

Satu tempat SQL memudahkan review per schema dan memberi input yang jelas bagi sqlc, sementara lima service Go tetap deployable terpisah. Pemisahan folder tidak mengubah ownership tabel, hak akses runtime, atau kontrak bisnis.
