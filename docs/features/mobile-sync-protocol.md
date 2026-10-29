# SYNC-001 — Protokol mobile offline Phase 2

**Status:** baseline desain implementasi, 28 Oktober 2026. **Scope:** draft order dan POD evidence queue; approval, credit override, payment dan posting tetap online. Server adalah sumber otoritatif untuk nomor, harga, pajak, kredit, stok dan permission. Pola repository local/remote mengikuti [panduan Flutter offline-first](https://docs.flutter.dev/app-architecture/design-patterns/offline-first).

## Wire contract

Semua request memakai OIDC access token saat online, `device_guid`, `tenant_guid` dan `scope_version` terverifikasi. `POST /api/v1/sync/commands` menerima array maksimum 50 command dengan `client_command_guid` UUIDv7, `idempotency_key`, `base_entity_version`, `created_at_device`, `payload_schema_version`, dan payload typed. Server mengembalikan hasil **per command**: `ACCEPTED` + server GUID/version, `NEEDS_REVIEW` + conflict code/current snapshot aman, atau `REJECTED` + code. HTTP 200 berarti batch diterima untuk diproses, bukan semua command berhasil. Server menyimpan hasil dedup per tenant/device/command secara permanen untuk aksi bisnis; key HTTP TTL 72 jam. Jika koneksi putus setelah server commit, retry dengan GUID/key sama mengambil hasil pertama.

Foto/tanda tangan POD disimpan terenkripsi di perangkat saat offline. Saat online, klien meminta `POST /api/v1/sync/evidence-uploads` dengan SHA-256, media type dan ukuran maksimum 10 MiB; server memberi URL unggah privat berumur pendek. Klien mengunggah objek, lalu mengirim `UPLOAD_POD_EVIDENCE` yang mereferensikan `evidence_upload_guid` dan checksum yang sama. Server memverifikasi ownership, checksum, MIME hasil inspeksi dan hasil malware scan sebelum POD accepted; objek gagal/expired tetap `NEEDS_REVIEW` dan tidak membuat revenue. URL tidak dicatat di log dan objek sementara dihapus sesuai retensi.

`GET /api/v1/sync/delta?collection=products&cursor=…` mengembalikan `scope_version, next_cursor, has_more, upserts[], tombstones[], server_time`. Cursor opaque ditandatangani, mengikat tenant/user/device/scope version/collection dan posisi log. Urutan stabil `(change_seq, record_guid)`; satu page maksimum 500 record. Tombstone memuat `guid, deleted_at, reason=DELETED|OUT_OF_SCOPE` tanpa PII. Cursor invalid/expired/terikat scope lama → HTTP 409 `SYNC_RESET_REQUIRED`, lalu klien menghapus cache scoped dan mengambil snapshot baru; draft lokal dipertahankan terisolasi untuk review. Scope revoked → HTTP 403, kunci cache lokal dan purge saat online berikutnya. Data cache maksimal 7 hari dan selalu terenkripsi seperti [standar mobile](../engineering/mobile-standards.md).

## Transaksi dan konflik

Mobile menyimpan draft+outbox dalam satu transaksi SQLite, status `PENDING_SYNC`. Setelah response, simpan ack/status+server GUID dan hapus outbox hanya dalam satu transaksi SQLite; crash sebelum commit mengulang key lama. Untuk delta, upserts+tombstones+cursor dalam satu transaksi; cursor tidak maju bila record gagal. Server mengembalikan current version dan field konflik yang diizinkan; klien tidak melakukan last-write-wins pada price, tax, stock, credit, approval atau status posted. Draft milik user boleh di-merge manual setelah menarik snapshot terbaru dan dikirim sebagai command baru. Approval/financial command offline ditolak `OFFLINE_ACTION_NOT_ALLOWED`.

| Skenario | Hasil yang harus diuji |
|---|---|
| Upload terputus setelah commit server | Retry mengembalikan result/nomor sama, tanpa SO kedua |
| Produk dihapus/inactivated | Tombstone menyingkirkan cache; draft yang memakai SKU masuk NEEDS_REVIEW |
| Harga berubah saat offline | Server quote ulang; UI menampilkan delta dan meminta konfirmasi baru sebelum submit |
| Permission/scope dicabut | Cursor lama ditolak, cache scoped dikunci/purge saat online; command lama 403 |
| Device revoked/lost | Refresh ditolak, sesi dibatalkan, cache terenkripsi TTL; remote wipe best-effort saat online |
| Batch sebagian diterima | Ack per command atomik lokal; command gagal tetap tersedia dengan alasan |

Sync endpoint punya rate/body limit, audit, request/correlation ID, backoff dengan jitter dan tidak memuat token/PII di log. Tombstone disimpan server selama umur cursor maksimum 30 hari; cursor lebih tua reset snapshot agar delete tidak hilang. Perubahan scope selalu reset walau cursor masih baru. [OpenAPI sync](../../contracts/openapi/sync/v1.yaml) menetapkan payload HTTP awal; contract test dan schema event terpisah dibuat bila implementasi Phase 2 mempublikasikan event baru.
