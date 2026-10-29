# UX-002 — Peta layar dan interaksi seluruh Foundation+MVP

**Scope:** web responsif untuk seluruh tugas MVP; mobile online read/visit pilot opsional, offline order Phase 2 mengikuti [SYNC-001](mobile-sync-protocol.md). Struktur Next.js/Flutter mengikuti [standar web](../engineering/frontend-standards.md) dan [mobile](../engineering/mobile-standards.md). Aksesibilitas menargetkan [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/) untuk web; hasil evaluasi harus dibuktikan pada UI nanti, bukan diasumsikan dari library.

## Pola bersama

Shell menampilkan tenant/entity/branch aktif, role, environment, menu berdasarkan permission dan status session. Peralihan entity membersihkan query cache, selection, draft lintas scope dan menampilkan konteks baru sebelum action. URL langsung tetap diperiksa server. Semua list memakai filter di URL, sort stabil `(business_date/created_at, guid)`, cursor scoped, page size terbatas, skeleton/empty/error/permission states, export hanya sesuai scope. Form menampilkan required/precision/UOM/currency, validasi client untuk ergonomi dan error server per field, preview total server authoritative. Tombol submit dinonaktifkan saat request berjalan tetapi retry memakai idempotency key lama; 412 menampilkan diff versi dan meminta review ulang, bukan overwrite. Pending saga/exception selalu tampak sebagai status dan CTA retry/reconcile sesuai permission.

| Area / route web | Role & aksi utama | Field/validasi dan state khusus |
|---|---|---|
| `/settings/organization` | Tenant/Security Admin: node create/activate/inactivate | parent/entity, code, effective date; preview hierarchy/cycle; in-use 422 |
| `/settings/access/users` | Security Admin: invite, grant, suspend, revoke | scope picker subset dari pemberi, reason, checker; revoked banner |
| `/settings/access/roles` | Security Admin: role/permission catalog | diff privilege dan SoD conflict; self-escalation denied |
| `/settings/policies` | Process Owner: simulate/test/publish/activate | rule version, effective range, fixture result, two approvers; no-active warning |
| `/settings/tax` | Tax Lead: tax rule/class/quote | DPP/rate/rounding preview, rule missing fail closed |
| `/settings/numbering` | Admin: sequence/config view | scope/type/year, assigned numbers audit; no manual reuse |
| `/master/products`, `/master/products/[guid]` | Steward: SKU/UOM create/publish/deactivate | base UOM, conversion version, tax/valuation class; historical snapshot warning |
| `/master/customers`, `/master/customers/[guid]` | Sales Steward: account/terms/status | entity account, tax profile, masked sensitive fields, checker action |
| `/master/vendors`, `/master/vendors/[guid]` | Purchase Steward: account/bank/terms | verified bank token, dual approval, masked bank |
| `/purchase/requisitions`, `/purchase/requisitions/[guid]` | Requester/Approver: draft/submit/approve | qty/UOM/need date, scope, approval progress, conversion refs |
| `/purchase/orders`, `/purchase/orders/[guid]` | Buyer/Approver: create/submit/approve/amend | vendor, line qty/price/tax, threshold, receipt projection, stale ETag |
| `/inventory/receipts`, `/inventory/receipts/[guid]` | Receiver: scan/inspect/post | PO remaining, lot/expiry, accepted/hold/damaged, over-limit error |
| `/inventory/stock` | Warehouse/Controller: scoped balance | available/held/hold/in-transit, as-of and lot/expiry; no set-balance action |
| `/inventory/adjustments`, `/inventory/adjustments/[guid]` | Controller: count/approve/post | book/count/delta/cost, evidence, maker-checker, period |
| `/sales/orders`, `/sales/orders/[guid]` | Sales/Approver: draft/submit/approve/cancel | customer, line qty, price/tax/discount/credit preview, pending reservation |
| `/credit/accounts/[guid]` | Credit Controller: exposure and override | bucket breakdown, deposit eligible, FX age, override expiry/SoD |
| `/warehouse/picks`, `/warehouse/picks/[guid]` | Picker: claim/scan/pack | lease, scan SKU/lot/serial, allocated vs picked, mismatch feedback |
| `/warehouse/deliveries`, `/warehouse/deliveries/[guid]` | Dispatcher/Driver: dispatch/POD | shipped vs accepted/rejected/in-transit, recipient/evidence, pending Finance |
| `/finance/sales-invoices`, `/finance/sales-invoices/[guid]` | AR Officer: source preview/issue | accepted portions, tax and cost snapshot, period, journal result |
| `/finance/vendor-invoices`, `/finance/vendor-invoices/[guid]` | AP Officer: match/issue | PO/GRN/invoice 3 columns, qty/price variance, exception resolution |
| `/finance/receipts`, `/finance/payments` | Cashier/Approver: post/allocate | bank ref, amount, open items, unapplied, checker, duplicate warning |
| `/accounting/journals`, `/accounting/journals/[guid]` | Accountant/Controller: post/reverse | line debit/credit balance, account/dimension, source link, immutable badge |
| `/accounting/periods` | Controller: close/reopen | owner attestations, pending exception counts, two-person reopen |
| `/reports/trial-balance`, `/reports/pnl`, `/reports/aging`, `/reports/stock-valuation` | Analyst: filter/export | entity/period/as-of, freshness/watermark, drill-down source |
| `/data/imports`, `/data/imports/[guid]` | Steward: upload/preview/commit | template, file hash, per-row error, partial results and retry |
| `/documents/[guid]` | scoped viewer: preview/download | scan status, retention, download audit; no unsafe inline file |
| `/approvals`, `/exceptions`, `/notifications` | role-specific inbox/action | source link, SoD, pending owner/age/error, acknowledge/retry |
| `/search` | any scoped user | type filters, freshness, no cross-scope leakage |

## Critical interaction contracts

| Scenario | UI behavior |
|---|---|
| 401/session revoked | clear scoped cache, redirect login, preserve only safe unsent draft locally if policy permits |
| 403/404 wrong scope | generic no access/not found; no prior PII in cache/back navigation |
| 409 idempotency/body conflict | show original operation result or instruct new action after reloading state |
| 412 stale ETag | fetch current server version, show changed fields, require explicit resubmit with new key |
| 422 policy/period/credit/stock | show stable code, actor who can resolve, no optimistic success state |
| 202 async | operation/pending state with polling or event refresh; never show posted until owner ack |
| partial quantity | show requested/approved/received/accepted/rejected/in-transit separately; no implicit close |
| exported file | ask scope and as-of, show job status/expiry, audit each download |

Mobile online pilot bila dipilih menampilkan customer/product snapshot, route/visit, order draft tanpa offline submit, delivery/POD online dan approval inbox online sesuai role. Device loss/revoke, camera permission denied, no network, battery/background limits dan scope switch memiliki state eksplisit. Offline production tetap Phase 2 dan tidak menjadi gate MVP pilot. Detail field lintas layar mengikuti FSD dan OpenAPI; desain visual dapat dieksekusi setelah route/action/state di atas disetujui.
