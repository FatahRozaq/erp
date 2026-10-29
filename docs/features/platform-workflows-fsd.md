# FSD-PLT — Import, dokumen, notifikasi, search dan laporan MVP

**Scope:** F-10 MVP dasar, dengan satu legal entity pilot dan data multi entity terisolasi. **Owner:** Platform untuk import job, attachment dan notification delivery; setiap domain tetap owner validasi/commit row bisnis; read model search/report hanya proyeksi. Integrasi marketplace/bank/WhatsApp, export terjadwal dan analitik lanjutan ditunda. Lihat [PRD F-10](../enterprise-erp-prd.md#17-kontrak-fitur-besar) dan [standar keamanan](../engineering/backend-standards.md).

## Import CSV dua tahap

Template berversi per tipe `SKU|CUSTOMER|VENDOR|OPENING_STOCK|OPENING_AR|OPENING_AP|COA` mengikuti [IMP-001](mvp-import-templates.md) untuk header, tipe, validasi dan contoh. Upload masuk object quarantine privat; MIME, magic bytes, ukuran, hash dan malware scan diverifikasi sebelum parse. Parser membatasi memori/row dan menolak formula injection pada export; nilai yang diawali `=,+,-,@` di-escape saat CSV keluar. Preview menyimpan row result `VALID|INVALID|DUPLICATE` dengan kolom/kode aman; tidak memutasi master. Commit memakai snapshot hash+template version yang sama, domain command per row dan `external_id` unik per source; batch dapat `COMPLETED|PARTIAL`, tiap row outcome final tercatat. Retry manifest/row yang sama tidak menciptakan record kedua. Import opening balance membutuhkan Controller, periode pembukaan dan rekonsiliasi debit/kredit/stok sebelum activation.

| Command | Guard | Outcome |
|---|---|---|
| `CreateImportJob` | `data.import`, entity scope, template aktif, quota | UPLOADED+signed upload URL TTL singkat |
| `PreviewImport` | object scan clean, hash dan schema cocok | VALIDATING→PREVIEW_READY/FAILED, row errors |
| `CommitImport` | PREVIEW_READY, actor scope/checker bila sensitif, file hash tetap | COMMITTING→COMPLETED/PARTIAL; row domain commands idempotent |
| `DownloadResult` | same scope, job owner/role; URL pendek | CSV manifest error aman dan audit download |

## Attachment, notification, search dan report

Attachment metadata menyimpan owner type/GUID, entity, object key privat, SHA-256, MIME terverifikasi, size, scan status, retention class, uploaded actor/time dan immutable version. Signed URL hanya untuk operasi dan objek yang diizinkan, berumur pendek dan tidak masuk log; download diaudit. Object `PENDING_SCAN` tidak boleh menjadi bukti POD/approval/posting. Dokumen keuangan yang issued mempertahankan attachment version; penggantian adalah versi baru, bukan overwrite.

Notification memakai event id dan recipient rule version; `QUEUED→SENT/FAILED`, dedup `(recipient,event_id,channel)` dan retry terbatas. In-app notification tidak memuat PII penuh; email hanya tautan ke aplikasi, tanpa token/data finansial sensitif. Delivery failure tidak me-rollback transaksi domain, kecuali komunikasi adalah syarat hukum eksplisit yang harus diproses sebagai exception terpisah.

Global search MVP memakai proyeksi Postgres per owner untuk customer/SKU/SO/PO/invoice/vendor, dengan tenant/entity/branch filter sebelum ranking/pagination; hasil memiliki `indexed_at` dan tidak dipakai untuk keputusan stock/credit. Query dibatasi panjang, page size dan sort; delete/scope revoke menghapus hasil atau menolak query. Report AR/AP aging, stock valuation, trial balance dan P&L memakai watermark/source version. Export besar async dengan filter/scope snapshot, masa berlaku URL dan audit. Stale read model diberi indikator, bukan angka yang dipresentasikan sebagai real-time.

## Acceptance minimum

| Given/When | Then |
|---|---|
| CSV 100 row, tiga invalid | preview menunjukkan 3 kode/baris; commit menghasilkan paling banyak 97 row sah, rerun tidak mengganda |
| file berubah setelah preview | commit 409 `IMPORT_SNAPSHOT_CHANGED`, no business write |
| malware scan pending/failed | dokumen tidak dapat dipakai untuk POD/posting atau diunduh umum |
| user entity B mencari nomor invoice entity A | hasil kosong/404 dan tidak ada PII bocor |
| event approval dipublish ulang | satu in-app notification per penerima/channel/event |
| report aging dibuat saat event Finance tertinggal | `as_of`/watermark ditampilkan dan exception freshness tercatat |

Semua job punya status polling, owner, created/updated timestamps, retry count, stable error, request/correlation IDs dan retention schedule. API/data/UX/test plan rinci di [planning gate](../planning-gate.md).
