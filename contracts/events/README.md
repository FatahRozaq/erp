# Event contract — seluruh roadmap

Schema memakai [JSON Schema Draft 2020-12](https://json-schema.org/draft/2020-12). Setiap event adalah fakta lampau, envelope wajib memuat event ID, aggregate GUID/version, tenant/entity, operation GUID, occurred/recorded time, correlation dan causation. `recorded_at` berasal dari outbox DB dan tidak berubah saat replay. Nama mengikuti PRD §31.
Contoh payload berada di [examples](examples/) dan harus divalidasi terhadap schema sebelum producer/consumer dirilis. **43 schema dan 43 contoh** untuk Foundation sampai Enterprise Expansion lulus validator Draft 2020-12 lokal pada 29 Oktober 2026. Ini kontrak rencana, belum bukti worker atau consumer berjalan.

| Event | Producer | Consumer wajib | Efek konsumen |
|---|---|---|---|
| [`master.product.published.v1`](master/product-published/v1.json) | Platform/Master | Commercial, Operations | Update snapshot SKU/UOM; tidak membuat stok |
| [`purchase.order.approved.v1`](purchase/order-approved/v1.json) | Commercial/Purchase | Operations | Full active line snapshot + retired line GUIDs; upsert receipt limit per PO line memakai aggregate version lebih baru, turunkan total hanya bila `approved_qty≥received_qty`; retired line punya remaining 0, duplicate/versi lama diabaikan |
| [`warehouse.goods_receipt.posted.v1`](warehouse/goods-receipt-posted/v1.json) | Operations | Commercial, Finance | Purchase update proyeksi received; Finance buat posting intent GRNI idempotent |
| [`accounting.journal.posted.v1`](accounting/journal-posted/v1.json) | Finance | Operations, Reporting | Tandai GRN tersambung ke jurnal dan rekonsiliasi selesai; duplicate diabaikan |
| [`iam.user.suspended.v1`](iam/user-suspended/v1.json) | Platform/IAM | Gateway, Web BFF, Mobile session service | Invalidasi cache/session; TTL authz tetap membatasi revoke ≤60 detik |
| [`master.party.published.v1`](master/party-published/v1.json) | Platform/Master | Commercial, Finance | Refresh customer/vendor account snapshot; data sensitif diambil via owner API berizin |
| [`policy.version.activated.v1`](policy/version-activated/v1.json) | Platform/Policy | Commercial, Operations, Finance | Refresh policy cache/version; command fail closed bila policy relevan tidak aktif |
| [`policy.approval.decided.v1`](policy/approval-decided/v1.json) | Platform/Policy | Commercial, Finance, Operations | Aplikasikan keputusan pada source revision tepat; stale revision masuk exception |
| [`sales.order.submitted.v1`](sales/order-submitted/v1.json) | Commercial/Sales | Platform/Policy | Buat approval instance dari policy version, idempotent per SO revision |
| [`sales.order.approved.v1`](sales/order-approved/v1.json) | Commercial/Sales | Operations/Inventory, Reporting | Minta reservation per line; tidak langsung mengizinkan WMS dispatch |
| [`inventory.stock.reserved.v1`](inventory/stock-reserved/v1.json) | Operations/Inventory | Commercial/Sales, Operations/WMS | Set ALLOCATABLE/BACKORDERED; WMS hanya release pick bila allocated ack |
| [`warehouse.delivery.shipped.v1`](warehouse/delivery-shipped/v1.json) | Operations/Warehouse | Commercial/Credit, Finance | Credit bucket ke in-transit; Finance tunggu cost source sebelum POD posting |
| [`warehouse.delivery.accepted.v1`](warehouse/delivery-accepted/v1.json) | Operations/Warehouse | Finance, Commercial/Credit | Finance invoice+COGS per accepted source portion; rejected tidak ditagih |
| [`warehouse.delivery.pod_corrected.v1`](warehouse/delivery-pod-corrected/v1.json) | Operations/Warehouse | Finance, Commercial/Credit | Terapkan signed delta accepted/rejected pada portion belum invoiced; event tidak boleh terbit bila source sudah issued; consumer dedup correction GUID |
| [`finance.sales_invoice.issued.v1`](finance/sales-invoice-issued/v1.json) | Finance | Operations/Warehouse, Commercial/Credit, Reporting | Ack delivery pending Finance; bucket ke POSTED_AR; projection source |
| [`finance.vendor_invoice.issued.v1`](finance/vendor-invoice-issued/v1.json) | Finance | Commercial/Purchase, Reporting | Tandai matched source dan AP projection; no duplicate GRNI settlement |
| [`finance.payment.posted.v1`](finance/payment-posted/v1.json) | Finance | Commercial/Credit, Reporting | Kurangi POSTED_AR untuk allocations dan bentuk eligible deposit dari `unapplied_base` hanya setelah posted; supplier payment tidak mengubah customer credit |
| [`finance.payment.allocation_applied.v1`](finance/payment-allocation-applied/v1.json) | Finance | Commercial/Credit, Reporting | Pindahkan nilai customer dari eligible deposit ke pelunasan AR tanpa mengubah exposure neto; supplier payment hanya AP/report |
| [`finance.payment.reversed.v1`](finance/payment-reversed/v1.json) | Finance | Commercial/Credit, Reporting | Aggregate GUID/version adalah payment asli; `reversal_guid` menunjuk dokumen pembalik. Buka seluruh allocation termasuk ApplyUnapplied dan hapus eligible deposit tersisa tepat sekali sebelum Credit hold dilepas; supplier payment reversal memperbarui AP/report; original payment tetap history |
| [`inventory.adjustment.posted.v1`](inventory/adjustment-posted/v1.json) | Operations/Inventory | Finance, Reporting | Buat journal shrinkage/gain dari cost snapshot; period exception bila perlu |
| [`accounting.period.closed.v1`](accounting/period-closed/v1.json) | Finance/Accounting | Commercial, Operations, Platform/Reporting | Tolak backdate baru dan kunci report watermark |

## Phase 2 Operations

| Event | Producer | Consumer wajib | Efek konsumen |
|---|---|---|---|
| [`purchase.rfq.awarded.v1`](purchase/rfq-awarded/v1.json) | Commercial/Purchase | Purchase PO, Reporting | Proyeksikan award dan source PO satu kali |
| [`purchase.blanket.released.v1`](purchase/blanket-released/v1.json) | Commercial/Purchase | Reporting, Budget bila aktif | Pantau cap dan komitmen dari release yang sudah committed |
| [`purchase.return.posted.v1`](purchase/return-posted/v1.json) | Commercial/Returns saga | Finance, Reporting | Rekonsiliasi stok dan memo setelah ack Operations/Finance; `supplier_debit_memo_guid` nullable bila invoice belum terbit |
| [`inventory.transfer.shipped.v1`](inventory/transfer-shipped/v1.json) | Operations | Reporting, Commercial | Pindahkan porsi ke in-transit, jangan tambah stok tujuan |
| [`inventory.transfer.received.v1`](inventory/transfer-received/v1.json) | Operations | Reporting, Finance | Akui porsi tujuan tepat sekali; cocokkan shipped dan received |
| [`inventory.count.posted.v1`](inventory/count-posted/v1.json) | Operations | Finance, Reporting | Jurnal selisih sesuai cost snapshot dan audit counting |
| [`sales.visit.recorded.v1`](sales/visit-recorded/v1.json) | Commercial/Sales | Reporting, Notification | Proyeksi kunjungan; GPS hanya sesuai consent dan policy |

## Phase 3 Enterprise Controls

| Event | Producer | Consumer wajib | Efek konsumen |
|---|---|---|---|
| [`policy.approval.stage_decided.v1`](policy/approval-stage-decided/v1.json) | Platform/Policy | Source owner, Notification | Terapkan quorum pada source revision yang sama |
| [`budget.commitment.changed.v1`](budget/commitment-changed/v1.json) | Finance/Budget | Commercial, Reporting | Perbarui status komitmen; source menunggu ack authoritative |
| [`finance.expense.posted.v1`](finance/expense-posted/v1.json) | Finance | Reporting, Budget | Proyeksikan payable/actual tanpa posting ganda |
| [`sales.promotion.activated.v1`](sales/promotion-activated/v1.json) | Commercial | Sales quote, Reporting | Invalidasi versi harga promo; SO menyimpan snapshot |
| [`finance.bank_reconciliation.closed.v1`](finance/bank-reconciliation-closed/v1.json) | Finance | Reporting, Control | Kunci watermark dan attestation hasil cocok |
| [`finance.fx_revaluation.posted.v1`](finance/fx-revaluation-posted/v1.json) | Finance | Reporting, Control | Proyeksikan signed delta dan inverse period |
| [`platform.connector.event_accepted.v1`](platform/connector-event-accepted/v1.json) | Platform/Integration | Owner target, Reporting | Teruskan command terpetakan dengan source ID unik; raw webhook tidak dipercaya |
| [`intercompany.transfer.shipped.v1`](intercompany/transfer-shipped/v1.json) | Operations | Finance kedua entity, Reporting | Buka paired due-from/due-to dan in-transit sesuai policy |
| [`intercompany.transfer.received.v1`](intercompany/transfer-received/v1.json) | Operations | Finance kedua entity, Reporting | Cocokkan quantity, valuation dan kedua buku; mismatch jadi exception |

## Enterprise Expansion

| Event | Producer | Consumer wajib | Efek konsumen |
|---|---|---|---|
| [`manufacturing.work_order.issued.v1`](manufacturing/work-order-issued/v1.json) | Operations | Finance, Reporting | Proyeksikan material ke WIP dari movement committed |
| [`manufacturing.work_order.completed.v1`](manufacturing/work-order-completed/v1.json) | Operations | Finance, Reporting | Akui finished goods dan WIP/variance dengan cost snapshot |
| [`pos.sale.completed.v1`](pos/sale-completed/v1.json) | Commercial/POS | Finance, Operations, Reporting | Hanya setelah capture, stok dan posting final; retry tidak duplikasi receipt |
| [`pos.sale.refunded.v1`](pos/sale-refunded/v1.json) | Commercial/POS | Finance, Operations, Reporting | Hubungkan refund dengan sale asal dan sisa qty/value |
| [`tms.milestone.recorded.v1`](tms/milestone-recorded/v1.json) | Operations/TMS | Reporting, WMS | Proyeksikan milestone; DELIVERED TMS tidak menjadi POD accepted |
| [`analytics.forecast.completed.v1`](analytics/forecast-completed/v1.json) | Platform/Data | Reporting, Planner | Tampilkan rekomendasi dan lineage; tidak ada jalur auto-posting |

Producer menulis fakta+outbox satu transaksi. Relay dapat publish ulang; consumer menyimpan `(consumer_name,event_id)` inbox dan efek dalam satu transaksi, baru ack broker. Aggregate version dipakai untuk deteksi gap; gap diparkir dan owner snapshot API diambil sebelum replay, bukan mengasumsikan ordering global. Retry transient exponential backoff+jitter maksimal 10 attempt/24 jam, lalu DLQ dengan alert dan replay manual yang diaudit. Permanent schema/security error langsung DLQ. Tambah field optional hanya jika consumer lama toleran; rename/remove/ubah makna memakai `v2` dengan dual publish dan tanggal deprecation. Contract test wajib memakai contoh payload valid/invalid serta replay duplikat/out-of-order. Semantik at-least-once mengikuti [NATS JetStream](https://docs.nats.io/concepts/jetstream); konsumen tidak boleh berasumsi exactly-once.

Untuk customer receipt MVP, fee bank bernilai nol. Producer dan consumer menegakkan `gross_base = sum(allocations.amount_base) + unapplied_base` pada event posted. ApplyUnapplied mengurangi unapplied sebesar `amount_base` sambil mengurangi open AR yang sama, tanpa mengubah exposure neto. Reversal penuh menegakkan `gross_base = sum(reopened_allocations.amount_base) + unapplied_reversed_base`; daftar reopened mencakup allocation saat post dan ApplyUnapplied sesudahnya. Credit memproses semua event payment menurut `aggregate_version` payment asli dan tetap menahan `reversal_hold` sampai proyeksi final tersimpan.
