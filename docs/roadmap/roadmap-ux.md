# UX-RM — Peta layar Phase 2 sampai final

**Shell web:** [Next.js + shadcn-admin](../adr/0005-shadcn-admin-frontend.md) melalui wrapper lokal `components/ui` dan `components/layout`; App Router route tetap tipis dan feature code berada pada `src/features`. Layout memuat entity switcher, role navigation, breadcrumb, notification, global search, as-of/watermark indicator, dan user menu. Semua keputusan akses diulang pada BFF/Echo API; tombol yang hilang bukan kontrol keamanan. Setiap layar memiliki loading, empty, forbidden/not-found, stale ETag, pending, conflict, retryable error, audit/history dan keyboard/focus state. WCAG 2.2 AA, ID/EN, timezone entity, decimal string dan mobile responsive diuji sebelum rilis.

| Tahap/route web | Data dan aksi utama | Guard dan status yang harus terlihat |
|---|---|---|
| P2 `/purchase/rfqs`, `/purchase/rfqs/[guid]` | PR source, invited vendors, deadline, quote revisions, comparison matrix, score explanation, split award | Buyer/manager scope; bid confidentiality, FX/UOM missing, deadline/award race, approval history |
| P2 `/purchase/blanket-contracts/[guid]` | cap qty/value, consumed/reserved, releases, create PO | `available` server, concurrent cap 409/422, expiry, source PO link |
| P2 `/sales/returns/[guid]`, `/purchase/returns/[guid]` | source portions, cumulative eligible, inspection, memo/tax correction | Before/after invoice path, partial, period closed, source serial, pending Finance ack |
| P2 `/inventory/transfers/[guid]` | source/dest, line, shipped/received/hold/discrepancy, cost snapshot | Same entity, partial state, in-transit aging, claim/reconcile; confirm destructive cancel |
| P2 `/warehouse/bins`, `/warehouse/waves/[guid]` | capacity/status, relocation scan, wave task lease | Wrong bin/lot, expired item, over-capacity, stale task, no double allocation |
| P2 `/inventory/counts/[guid]` | freeze watermark, expected/first/second count, discrepancy, approval | Blind count by role, threshold second count, blocked movement, posted adjustment link |
| P2 `/sales/routes/[guid]`, `/sales/visits/[guid]` | stops, assignment, visit timestamps/evidence, target attainment | GPS consent optional and explicit, offline pending/review, source server time |
| P2 `/settings/notifications` | device registration, channel/category preference, quiet hours | Security category cannot disable when mandatory; revoked device state |
| P2 `/reports/operations` | fill rate/return/transfer/visit/RFQ metrics | Filter entity/date, formula version, watermark lag, scoped export |
| P3 `/settings/approval-graphs/[guid]` | graph stages/edges/quorum, simulation, publish, delegation | Cycle/unreachable/SoD error, revision comparison, effective period |
| P3 `/approvals/inbox` | parallel assignments, due/escalated, delegate history | Maker conflict, quorum progress, stale source revision, retry idempotent |
| P3 `/finance/budgets/[guid]`, `/finance/expenses/[guid]` | authorized/actual/committed/available, claim evidence, reimbursement | Hard/soft policy, duplicate receipt, SoD, closed period, source journal/payment |
| P3 `/sales/promotions/[guid]` | rule type/eligibility/priority/stack/cap, quote simulation | Effective overlap, rejected candidates, cap race, tax explanation |
| P3 `/finance/bank-reconciliation/[guid]` | statement lines, suggested/matched/exception, close equation | Suggestion not posting, duplicate/match race, variance and checker |
| P3 `/finance/fx-rates`, `/finance/revaluation/[guid]` | source/pair/rate, foreign/carrying/delta, inverse journal | Stale/missing rate, period lock, re-run source uniqueness |
| P3 `/reports/schedules`, `/settings/connectors/[guid]` | cron/timezone, audience, run status; target/mapping/checkpoint/DLQ | Secret reference only, scope recheck, replay approval, no payload PII |
| P3 `/intercompany/transfers/[guid]` | both entity docs, shipment/receipt, due-to/from, tax, ack status | Two-entity approval, pending/exception and reconciliation before close |
| EXP `/manufacturing/boms/[guid]`, `/manufacturing/work-orders/[guid]` | versioned BOM, material reservations/issues, WIP, partial completion/variance | Batch/serial, missing posting rule, period, source movement/journal links |
| EXP `/pos/registers/[guid]`, `/pos/sales/[guid]` | shift, cart/tax/stock/payment/receipt, refund, cash close | Provider pending/unknown, stock timeout, one capture, cashier SoD |
| EXP `/tms/plans/[guid]` | carrier/driver/stops, ETA, milestones/evidence | TMS delivered ≠ POD accepted, late/out-of-order, revoked carrier |
| EXP `/analytics`, `/analytics/forecasts/[guid]` | metric formula, entity/as-of/watermark, lineage, forecast quality/recommendation | stale projection banner, scope at drill-down/export, human review before any action |

## Mobile Flutter Phase 2 dan sesudahnya

Fitur tetap mengikuti [standar mobile](../engineering/mobile-standards.md) dan [SYNC-001](../features/mobile-sync-protocol.md). `/routes` menampilkan assignment dan snapshot TTL; `/visits/[local_id]` menyimpan note/check-in/out+consent; `/orders/drafts/[local_id]` menunjukkan `LOCAL_DRAFT|PENDING_SYNC|NEEDS_REVIEW|ACCEPTED|REJECTED` dengan diff harga/stock/credit dari server; `/sync` menunjukkan queue, retry, last sync, cursor reset dan upload evidence. `/warehouse/tasks` menampilkan scan bin/lot/serial online-first dan lease; `/delivery/[guid]/pod` menyimpan evidence privat dan baru menampilkan accepted setelah server ack. `/approvals` online-only untuk keputusan. Push hanya membuka route setelah auth/scope cek ulang. Device revoked mengunci cache; offline draft dipertahankan terenkripsi untuk review lalu purge menurut policy.

## Kontrak interaksi

Setiap command web/mobile mengirim `Idempotency-Key`, `If-Match` untuk aggregate yang sudah ada, dan hanya field yang ada di OpenAPI. UI menampilkan status `202/PENDING` sebagai belum final. Pada `409/412`, tampilkan server/current vs draft dan pilihan refresh/reapply yang membuat key baru; jangan auto-overwrite. Pada `422`, tampilkan invariant dan field yang terkait; pada `503`, retry hanya dengan key sama. Semua laporan/ekspor mencatat filter scope, formula version dan watermark; chart tidak menyamarkan data tertunda. Template shadcn-admin tidak boleh membawa demo auth/router Vite atau mock data ke produk ERP; asset/komponen yang dipakai tercatat dalam vendor manifest.
