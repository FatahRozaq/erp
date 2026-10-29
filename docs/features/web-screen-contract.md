# UX-001 — Kontrak layar web MVP

**Status:** baseline desain implementasi, 28 Oktober 2026. **Owner:** Product Design + Web. Server tetap memutus permission dan scope; tombol tersembunyi bukan kontrol keamanan. Aplikasi memakai BFF session dan pola cache di [standar frontend](../engineering/frontend-standards.md).

| Route | Role/permission minimum | Data dan aksi utama | State yang harus tersedia |
|---|---|---|---|
| `/app/context` | user aktif | pilih legal entity/branch aktif | loading, tidak ada membership, scope berubah |
| `/app/master/skus` | `master.sku.read` | list/search SKU, create/publish bagi manager | empty, invalid code/UOM, publish conflict |
| `/app/purchase/orders` | `purchase.po.read` | list PO scoped, filter status/date, create | empty, cursor expired, denied |
| `/app/purchase/orders/[guid]` | `purchase.po.read` | draft lines, submit, approval status | saving, stale version, waiting approval, rejected |
| `/app/operations/receipts` | `inventory.receipt.read` | draft/post GRN dari PO approved | remaining changed, partial, posting pending, failed |
| `/app/operations/stock` | `inventory.balance.read` | balance/ledger drill per warehouse | as-of/stale projection, empty, denied |
| `/app/sales/orders` dan `/[guid]` | `sales.order.read` | draft/submit, credit hold, reservation | pending approval/reservation, backorder, stale |
| `/app/warehouse/deliveries` dan `/[guid]` | `warehouse.delivery.read` | pick/dispatch/POD | partial POD, pending Finance, exception |
| `/app/finance/invoices` dan `/[guid]` | `finance.invoice.read` | issued invoice, AR/tax status | posting pending, tax rejected, period lock |
| `/app/finance/payments` | `finance.payment.read` | payment/allocation | unmatched, pending bank, posted |
| `/app/finance/ledger` | `accounting.journal.read` | journal/trial balance/close | reconciliation mismatch, closed period |
| `/app/approvals` | `approval.inbox.read` | inbox/decide | competing decision, SoD denied, config pending |
| `/app/audit` | `audit.event.read` | trace actor/source/outcome | access denied, redacted field, retention |

Setiap screen mendefinisikan di kode: query key termasuk tenant/entity/scopeVersion, skeleton loading, empty state dengan aksi aman, error dengan `request_id`, stale/as-of label, akses keyboard/fokus, validasi format client, dan konfirmasi untuk command irreversible. Jumlah uang/qty ditampilkan sebagai string decimal terformat; submit mengirim nilai kontrak kanonik, bukan hasil float JavaScript. Aksi ditampilkan hanya jika permission+state mengizinkan, tetapi server wajib cek ulang. Semua mutation kritikal memakai If-Match dan Idempotency-Key; 412 menampilkan current version dan pilihan reload/review, 409 duplicate mismatch tidak diulang otomatis.

Bulk import/export tidak tersedia default pada role biasa. Import hanya melalui preview+validasi+approval dan job status; export diberi `export.<domain>.create`, scope, row cap, alasan, audit, file terenkripsi dan URL singkat. Export ledger/PII butuh izin terpisah dan masking. Route yang tidak berizin menunjukkan 403 aman, tidak membocorkan data saat prefetch/cache. Wireframe visual dibuat bersama layar nyata, sedangkan tabel ini mengunci informasi dan keadaan minimum per route.

## Wireframe tekstual slice pertama

`/app/master/skus`: header konteks tenant; tabel `code/name/base UOM/status/updated_at`; cari kode, filter status, pagination; tombol **Tambah SKU** bila `master.sku.create`; row DRAFT menampilkan **Publish** bila `master.sku.publish`. Form: code wajib 1–64, name 1–200, UOM dipilih dari daftar ACTIVE. Publish menampilkan ringkasan perubahan dan butuh konfirmasi; 412 memuat versi baru sebelum user dapat mengulang.

`/app/purchase/orders/[guid]`: header nomor/status/entity/vendor/branch/currency; line `SKU/qty/unit price/received qty` dan gross total string decimal. DRAFT dapat tambah/hapus line lalu Submit; WAITING_APPROVAL menampilkan langkah dan actor; APPROVED menampilkan remaining per line. Maker tidak melihat tombol Approve pada dokumen sendiri. Submit memerlukan preview jumlah/pajak dan policy version. Invalid vendor/SKU/amount ditandai per field; 409/412 menampilkan banner dan reload.

`/app/operations/receipts`: pilih PO APPROVED dan warehouse entity sama; isi accepted qty per line maksimum remaining dari server, tampilkan estimasi nilai dan sisa. Tombol Post meminta konfirmasi; UI tidak menganggap selesai sebelum respons POSTED. Jika approved event belum terproyeksi, tampilkan **Menunggu sinkronisasi PO** dengan status yang bisa di-refresh. Over-receipt race menampilkan remaining terbaru dan membiarkan draft direvisi; tidak mengulang otomatis dengan quantity lama.
