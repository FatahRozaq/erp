# CMD-RM — Command dan kontrak lintas owner sampai tahap final

**Aturan bersama:** path eksternal `/api/v1`, bearer OIDC/workload kecuali webhook signature, `X-Legal-Entity-Guid` scoped, `Idempotency-Key` pada mutasi, `If-Match` untuk aggregate existing, decimal string, Problem `{success:false,code,message,details,request_id}`. `202` berarti pending, bukan completed. Setiap command menghasilkan audit+outbox dalam transaksi owner; worker/consumer memakai inbox dedup dan source operation GUID permanen. Path/field/response yang dapat dibaca mesin ada di [OpenAPI kanonik](../../contracts/openapi/README.md). Daftar ini menetapkan state, guard, owner, dan efek yang tidak boleh hilang dari handler. `409` untuk concurrent/duplicate conflict, `412` stale ETag, `422` invariant bisnis, `503` dependency owner; error khusus di kolom terakhir.

## Phase 2

| Owner / command (`operationId`) | Input wajib dan guard | Commit/result/event | Error khusus |
|---|---|---|---|
| Commercial `createRfq` | `pr_guid,pr_revision,deadline,evaluation_policy_guid,lines[]`; PR APPROVED | RFQ DRAFT+source snapshot | `PR_REVISION_STALE` |
| Commercial `openRfq` | `guid`, If-Match; policy PUBLISHED, invited vendor aktif | OPEN+deadline immutable | `RFQ_POLICY_INVALID` |
| Commercial `submitVendorQuote` | `rfq_guid,vendor_account_guid,lines[],currency`; invite/deadline valid | quote version SUBMITTED | `RFQ_DEADLINE_PASSED` |
| Commercial `awardRfq` | `guid`, If-Match, `awards[]`, comparison hash, reason; sum≤PR | award+PO source once, `purchase.rfq.awarded.v1` | `AWARD_QTY_EXCEEDS_PR` |
| Commercial `createBlanketContract` / `activateBlanketContract` | vendor, dates, caps, policy; checker berbeda | ACTIVE contract snapshot | `CONTRACT_POLICY_MISSING` |
| Commercial `releaseBlanketPo` | contract GUID, If-Match, line qty/value; cap lock | release+PO DRAFT, `purchase.blanket.released.v1` | `CONTRACT_CAP_EXCEEDED` |
| Commercial/Operations/Finance `createPurchaseReturn` / `inspectPurchaseReturn` / `postPurchaseReturn` | GRN/source, qty, evidence, disposition; received−returned limit | return/stock movement/memo via saga; `purchase.return.posted.v1` saat final | `PURCHASE_RETURN_EXCEEDS_SOURCE` |
| Operations `createTransfer` / `approveTransfer` | two warehouses same entity, line qty; checker | APPROVED and source limits | `TRANSFER_ENTITY_MISMATCH` |
| Operations `shipTransfer` / `receiveTransfer` | portion qty, lot/serial, cost, If-Match | stock→transit→destination; `inventory.transfer.shipped/received.v1` | `TRANSFER_RECEIVE_EXCEEDS_SHIPPED` |
| Operations `resolveTransferDiscrepancy` | claim evidence, checker, accepted loss/receipt | adjustment+claim CLOSED | `TRANSFER_CLAIM_UNRESOLVED` |
| Operations `relocateBin` | source/dest bin, SKU/lot/serial, qty; capacity | paired movement, warehouse total unchanged | `BIN_CAPACITY_EXCEEDED` |
| Operations `createWave` / `releaseWave` | pick task GUIDs allocated and unleased | one wave/task assignment; no stock delta | `PICK_TASK_ALREADY_WAVED` |
| Operations `createStockCount` / `postStockCount` | scope, freeze watermark, two counts if threshold | count+approved adjustment once, `inventory.count.posted.v1` | `COUNT_SECOND_PASS_REQUIRED` |
| Commercial `publishRoutePlan` / `recordVisit` | salesman/date/stops or visit command/device; scoped assignment | route PUBLISHED, visit append-only; `sales.visit.recorded.v1` | `VISIT_ASSIGNMENT_INVALID` |
| Platform `registerPushDevice` / `setNotificationPreference` | device token or category/channel/quiet hours; user scope | encrypted token/preference; security preference locked | `NOTIFICATION_MANDATORY` |
| Platform `getOperationsReport` | entity/date/filter/as_of; scoped read | snapshot+watermark/formula version; no mutation | `REPORT_SOURCE_STALE` |

Mobile `createEvidenceUpload`, `pushMobileCommands`, `pullMobileDelta` dan Sales return commands tetap mengikuti [SYNC-001](../features/mobile-sync-protocol.md) dan [FSD-RET](../features/returns-fsd.md). Tidak ada order/stock/credit authoritative yang diputuskan di mobile offline.

## Phase 3

| Owner / command | Input wajib dan guard | Commit/result/event | Error khusus |
|---|---|---|---|
| Platform `publishApprovalGraph` / `decideApprovalStage` / `delegateApproval` | graph DAG/quorum or source revision/actor/delegation scope | one stage transition; `policy.approval.stage_decided.v1` | `APPROVAL_QUORUM_INVALID`, `APPROVAL_SOD_VIOLATION` |
| Finance `createBudget` / `activateBudget` / `reserveBudget` / `releaseBudget` | entity/year/cost center/account/amount/source key; hard available lock | budget version/commitment; `budget.commitment.changed.v1` | `BUDGET_INSUFFICIENT` |
| Finance `createExpenseClaim` / `approveExpenseClaim` / `postExpenseClaim` | receipt hash/category/amount/cost center; checker/period | payable+journal; `finance.expense.posted.v1` | `EXPENSE_RECEIPT_DUPLICATE` |
| Commercial `publishPromotion` / `quotePromotion` | typed rule, effective, cap/stack; simulation | version PUBLISHED or quote explanation | `PROMOTION_CAP_EXCEEDED` |
| Finance `importBankStatement` / `matchBankLine` / `closeBankReconciliation` | file hash/line IDs or source payment; close equation | statement/match/attestation; `finance.bank_reconciliation.closed.v1` | `BANK_MATCH_CONFLICT` |
| Finance `publishFxRate` / `runFxRevaluation` | pair/source/date/rate; period OPEN | rate version or revalue+inverse intent; `finance.fx_revaluation.posted.v1` | `FX_RATE_STALE` |
| Platform `createReportSchedule` / `activateReportSchedule` | cron+timezone+scope/query hash | schedule/run unique; no direct ledger write | `SCHEDULE_SCOPE_INVALID` |
| Platform `registerConnector` / `ingestConnectorEvent` | target allowlist/mapping or signature+external ID | validated delivery/owner command; `platform.connector.event_accepted.v1` | `CONNECTOR_SIGNATURE_INVALID` |
| Commercial/Operations/Finance `createIntercompanyTransfer` / `approveIntercompanyTransfer` / `shipIntercompanyTransfer` / `receiveIntercompanyTransfer` / `closeIntercompanyTransfer` | two entity approvals, tax/FX/price, source/dest qty | pair saga with due-from/to+inventory; `intercompany.transfer.shipped/received.v1` | `INTERCOMPANY_POLICY_MISSING` |

## Enterprise Expansion

| Owner / command | Input wajib dan guard | Commit/result/event | Error khusus |
|---|---|---|---|
| Operations `publishBom` / `createWorkOrder` / `releaseWorkOrder` | BOM components/yield/effective or target qty; policy/stock/period | BOM snapshot, WO reservation | `BOM_EFFECTIVE_OVERLAP` |
| Operations `issueWorkOrderMaterials` / `completeWorkOrder` | component portions or output qty/scrap/cost; WIP lock | stock/WIP/finished movement; `manufacturing.work_order.issued/completed.v1` | `WORK_ORDER_WIP_MISMATCH` |
| Commercial/Finance `openPosShift` / `checkoutPosSale` / `refundPosSale` / `closePosShift` | register/cashier/cart/payment provider; stock+capture proof | sale/payment/journal/receipt or refund; `pos.sale.completed/refunded.v1` | `POS_PROVIDER_OUTCOME_UNKNOWN` |
| Operations `createTransportPlan` / `assignTransportPlan` / `recordTransportMilestone` | dispatched delivery GUIDs/carrier/driver or milestone/evidence | plan/milestone; `tms.milestone.recorded.v1` | `TMS_SOURCE_NOT_DISPATCHED` |
| Platform/Data `getMetricSnapshot` / `runForecast` / `getForecastRun` | metric/formula/as_of or model/horizon/dataset watermark | read-only snapshot or recommendation; `analytics.forecast.completed.v1` | `ANALYTICS_SOURCE_STALE` |

Semua state, angka dan race yang mengikat command ini berada dalam [FSD-P2](phase-2-fsd.md), [FSD-P3](phase-3-fsd.md), [FSD-EXP](enterprise-expansion-fsd.md), [DATA-RM](roadmap-data-dictionary.md), dan [QA-RM](roadmap-test-vectors.md). Saat service split, command URI/kontrak publik dipertahankan atau diberi versi baru; `POSTING_PENDING/EXCEPTION` wajib menggantikan asumsi transaksi lokal bila invoice/journal dipisah.
