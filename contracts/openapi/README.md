# Kontrak HTTP kanonik

OpenAPI 3.1.1 di folder per owner adalah sumber kebenaran lintas backend, web dan mobile. Kontrak Foundation+MVP: [Platform](platform/v1.yaml), [Master SKU/UOM](master/v1.yaml), [Platform workflow](workflows/v1.yaml), [Purchase Requisition](requisition/v1.yaml), [Purchase Order](purchase/v1.yaml), [Sales/Credit](sales/v1.yaml), [Inventory GRN](inventory/v1.yaml), [Operations/WMS](operations/v1.yaml), [Finance AR/AP](finance/v1.yaml), dan [Accounting](accounting/v1.yaml). Phase 2 menambah [Mobile Sync](sync/v1.yaml) dan [Returns](returns/v1.yaml) serta operasi di spec owner. Enterprise Expansion menambah [Manufacturing](manufacturing/v1.yaml), [POS](pos/v1.yaml), [TMS](tms/v1.yaml), dan [Analytics](analytics/v1.yaml). Phase 3 dan fase lain juga memperluas spec owner yang sama. `x-owner`, `x-stage`, `x-permission`, dan `x-error-codes` mengikat operasi ke deployable, tahap, otorisasi dan error domain pada [matriks command](../../docs/roadmap/roadmap-command-contract.md). Total **16 spec, 258 operasi, 585 contoh request/response langsung** diverifikasi lokal pada 29 Oktober 2026. Syntax lint dapat dijalankan dengan `postman spec lint --issueType=syntax --no-report-events <file>`; governance lint Postman memerlukan login workspace dan belum boleh diklaim lulus.

## Perilaku bersama

Bearer OIDC diverifikasi issuer/audience/expiry; `X-Legal-Entity-Guid` adalah pilihan konteks yang dicocokkan dengan membership dan scope. Path GUID yang tidak ada atau di luar scope memberi 404. Setiap command menegakkan permission `x-permission`, state, policy aktif, dan SoD di server. Browser menggunakan BFF session; BFF meneruskan identitas tepercaya. `Idempotency-Key` berlaku pada create dan transisi, scope menurut PRD §32; key sama+body sama mengembalikan hasil yang sama, body beda 409. TTL API 72 jam, sedangkan source business unique permanen. `If-Match: "N"` wajib untuk mutasi agregat; mismatch 412 dan response aman tanpa menulis.

Endpoint `billing-source-portions/*/correction-claims` dan `credit/accounts/*/reversal-holds` hanya menerima workload identity antarlayanan dengan audience owner, tenant/entity scope dan permission internal spesifik. Claim/reversal hold mengambil row lock owner; `abort` dan `release` memeriksa bukti state owner aktual sebelum melepas fence. User token dan BFF tidak diberi permission ini.

| Status | Kode dasar | Retry |
|---|---|---|
| 400 | `REQUEST_INVALID` | setelah memperbaiki payload |
| 401 | `AUTH_REQUIRED` | setelah login/refresh |
| 403 | `FORBIDDEN`, `APPROVAL_SOD_VIOLATION` | tidak otomatis |
| 404 | `RESOURCE_NOT_FOUND` | tidak otomatis |
| 409 | `IDEMPOTENCY_KEY_REUSED`, `CONCURRENT_DECISION`, `SYNC_RESET_REQUIRED` | hanya setelah membaca state |
| 412 | `STALE_VERSION` | reload lalu review, key command baru bila payload berubah |
| 422 | `POLICY_NOT_ACTIVE`, `TAX_POLICY_MISSING`, `PURCHASE_PO_RECEIPT_EXCEEDS_REMAINING`, `INVENTORY_PERIOD_CLOSED` | setelah konfigurasi/data berubah |
| 429 | `RATE_LIMITED` | ikuti `Retry-After` |
| 503 | `DEPENDENCY_UNAVAILABLE` | retry dengan key sama dan backoff |

Error JSON mengikuti PRD §33 (`success=false, code, message, details, request_id`). RFC [9457 Problem Details](https://www.rfc-editor.org/rfc/rfc9457.html) adalah alternatif standar, tetapi mengganti bentuk error saat ini akan mengubah kontrak web/mobile; keputusan migrasi perlu ADR. Header `request_id` dan jejak audit menghubungkan insiden. Detail error tidak memuat PII/secret. Cursor list mengikat scope+filter+sort; scope berubah atau cursor expired → 409 dengan kode stabil, tidak melanjutkan halaman dari konteks lama. ETag dan conditional requests mengikuti [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html).

Request dan response 2xx memiliki contoh sintetis yang lolos validasi schema; error memakai response Problem atau `default` dengan kode domain pada `x-error-codes`. Contoh ini menetapkan bentuk payload. Angka dan transisi bisnis yang harus dibuktikan ada di [QA-002](../../docs/quality/mvp-contract-vectors.md); response contoh bukan bukti server berjalan. Gate CI: sintaks, referensi, contoh success/error, permission/status matrix, breaking-change diff, generated client drift, contract tests, dan consumer review. [OpenAPI 3.1.1](https://spec.openapis.org/oas/v3.1.1.html) dipin sampai toolchain proyek memilih upgrade bersama.

Untuk Phase 2, Phase 3, dan Enterprise Expansion, angka/transisi/failure ditetapkan oleh [QA-RM](../../docs/roadmap/roadmap-test-vectors.md) dan [FSD roadmap](../../docs/roadmap/README.md). `x-emits` menyatakan event final dari command; response `202` atau state `PENDING_*`/`QUEUED` bukan bukti event final sudah terbit. `x-emits-on-status` menegaskan status terminal pada return pembelian, POS checkout dan forecast. Webhook connector memakai security scheme `webhookHmac`: HMAC-SHA256 atas timestamp dan raw bytes, replay window, secret rotation dan source ID dedup wajib diuji sebelum command owner dikirim. Tidak ada aplikasi/server live yang tervalidasi oleh syntax lint.
