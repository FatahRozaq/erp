# FSD-O2C — Sales order sampai kas dan jurnal MVP

**Scope:** F-03, F-05 reservation, F-06 delivery, F-07 AR, F-08 GL. Satu LegalEntity; beberapa branch/warehouse. **Owner:** Commercial untuk SO/credit, Operations untuk stok/WMS/POD, Finance untuk invoice/payment/journal. Mengikuti [policy G-02–G-06](../decisions/mvp-business-policy.md), [command matrix](mvp-command-matrix.md) dan [return Phase 2](returns-fsd.md). Mobile order offline tidak termasuk MVP.

## State, sumber dan izin

| Aggregate | State MVP | Actor/permission utama | Sumber kebenaran |
|---|---|---|---|
| SalesOrder | DRAFT→SUBMITTED→WAITING_APPROVAL→APPROVED_PENDING_RESERVATION→ALLOCATABLE/BACKORDERED→PARTIALLY_FULFILLED/FULFILLED; CANCELLED hanya sebelum shipped | Sales `sales.order.create/submit`; approver terpisah `sales.order.approve` | Commercial |
| Credit bucket | APPROVED_UNSHIPPED→SHIPPED_UNACCEPTED→ACCEPTED_UNBILLED→POSTED_AR→PAID/CANCELLED | service-only mutation; Credit Controller override bila aktif | Commercial Credit |
| Reservation | REQUESTED→HELD→ALLOCATED→CONSUMED/RELEASED/EXPIRED | service `inventory.reserve/release/consume` | Operations Inventory |
| Pick/Delivery | OPEN→PICKED→PACKED→DISPATCHED→POD_ACCEPTED_PENDING_FINANCE→DELIVERED; EXCEPTION terlihat | Picker/Dispatcher/Driver; `warehouse.pick/pack/dispatch/pod` | Operations Warehouse |
| Invoice | DRAFT→ISSUED→PARTIALLY_PAID→PAID; correction dokumen baru | Finance `finance.invoice.issue` | Finance |
| Payment | DRAFT→APPROVED→POSTED→REVERSED | Cashier+checker `finance.receipt.post` | Finance |

SO line menyimpan `sku_guid`, entered qty/UOM, conversion version bila non-base UOM, base qty hasil validasi server, requested warehouse, price/tax/discount/policy snapshot GUID, gross/net/tax decimal dan version. Bila client mengirim 2 carton dan base qty 24, server menguji rasio published 1:12 pada business date; mismatch ditolak 422 dan snapshot lama tidak berubah saat conversion baru terbit. `source_portion_guid` dibuat deterministik per delivery accepted portion; ia menjadi kunci dedup Finance dan credit bucket, bukan SO line yang dapat dipenuhi beberapa kali. Credit account dikunci saat submit dan sebelum dispatch; exposure mengikuti G-05, satu bucket aktif per portion. Reserve stok hanya setelah approval terkonfirmasi; WMS tidak memulai pick dari state sementara. Semua lookup/command memeriksa tenant, entity, branch/warehouse, permission, SoD, ETag dan idempotency key.

## Command dan boundary transaksi

| Command | Guard utama | Owner write atomik | Event/ack dan kegagalan |
|---|---|---|---|
| `Create/ReviseSO` | customer account ACTIVE, SKU/price/tax aktif; qty>0; revision setelah submit mengulang approval | SO header+lines/snapshot+audit; revision baru | salah scope 404/403; rule tidak ada 422 |
| `SubmitSO` | DRAFT, total server authoritative, discount floor, credit available | Credit lock bucket+commitment; Commercial SO status/nomor/approval request dalam transaksi lokal masing-masing | saga pending sampai dua ack; failed Sales commit → release credit; same op GUID tidak mengganda |
| `ApproveSO` | step policy, actor bukan maker, threshold G-06 | Policy decision; Sales consume dan set APPROVED_PENDING_RESERVATION | duplicate decision 409; versi berubah → approval invalidated |
| `Reserve/Release` | available sellable−held cukup, lot/expiry sah | lock balance urut SKU/warehouse/lot; reservation+balance+outbox | kurang → BACKORDERED; timeout pending, retry op GUID sama |
| `Pick/Pack/Dispatch` | reservation confirmed; picked≤allocated; FEFO; serial unik; credit recheck | Operations inventory consume + warehouse→in-transit movement, WMS delivery state setelah ack | scan mismatch/revoked scope 422/403; dispatch tidak mendebit COGS |
| `AcceptPOD` | DISPATCHED, evidence sah dan checksum lolos; accepted+rejected≤shipped; recipient ada | Operations accepted/rejected source portions + outbound cost snapshot + outbox | partial remains open; incomplete proof → POD_REVIEW_REQUIRED; tidak revenue |
| `IssueInvoiceFromPOD` | accepted portion belum invoiced, dispatch posting ada, period/tax rule aktif | Finance lock billing portion; invoice+AR/revenue/tax+COGS/in-transit journal dan outbox satu DB transaction | Finance ack mengubah delivery completed; failure tetap pending, close period menolak |
| `PostCustomerReceipt` | bank evidence/ref unik; allocated≤open AR; period/currency sah | payment+allocation+bank/AR dan unapplied liability journal+outbox satu DB transaction | unmatched masuk unapplied/suspense; retry tidak mengganda |

Tidak ada transaksi DB lintas Commercial/Operations/Finance. Event membawa GUID, version, operation dan source portion; worker inbox dedup, gap version diparkir. Query status menampilkan `pending_owner`, `last_error_code`, `last_attempt_at` untuk saga yang belum selesai. Operator dapat retry atau reconcile setelah sebab diperbaiki; posted ledger tidak pernah diedit.

## Contoh angka dan jalur alternatif

Fixture entity IDR, customer credit limit 3.000, stok sellable 10 pcs dengan average cost 110, SO 5 pcs @ net 200, pajak efektif 11%, tanpa diskon. SO gross 1.110 dan credit bucket 1.110. Dispatch 5 memindahkan nilai 550 dari warehouse ke in transit; tidak ada revenue/COGS. POD menerima 3 dan menolak 2: Finance invoice 3 × 200 + 11% = 666, jurnal Dr AR 666 / Cr Revenue 600 / Cr Output Tax 66 dan Dr COGS 330 / Cr In Transit 330. Dua unit kembali ke warehouse bernilai 220; bucket kredit untuk 3 berpindah ke POSTED_AR, dua yang ditolak CANCELLED. Receipt customer 400: Dr Bank 400 / Cr AR 400; outstanding 266 dan invoice PARTIALLY_PAID. Receipt kedua 266 melunasi AR. Semua nilai dan line source disimpan sebagai decimal/snapshot, bukan dihitung ulang dari harga terkini.

Jika hanya 2 unit dipick, delivery partial memiliki source portion sendiri dan sisa SO tetap ALLOCATABLE/BACKORDERED sesuai reservation. Jika POD 31 Desember diterima server 1 Januari, business date 31 Desember hanya dipakai bila period masih OPEN; jika closed, buat exception untuk Controller. Jika Finance gagal setelah POD, status tetap `POD_ACCEPTED_PENDING_FINANCE`; retry memakai op GUID sama, period close menolak pending itu. Cancel sebelum dispatch me-release bucket/reservation; setelah dispatch memakai return/reversal flow, bukan cancel SO.

## Acceptance dan reconciliation

| Skenario | Expected |
|---|---|
| Dua SO bersaing atas credit available 1.000, masing-masing gross 700 | Paling banyak satu approved commitment; yang lain credit hold |
| 100 reservation atas stok 10 | `held+allocated≤10`; tidak ada sellable negatif |
| POD 3 accepted/2 rejected dikirim ulang | Satu set source portion, invoice 3 unit, COGS 330 sekali |
| Payment 400 dikirim ulang dengan bank ref/op GUID sama | Satu receipt/journal; open AR 266 |
| Actor branch B mengakses SO branch A | 403/404, tidak ada data/side effect yang bocor |
| Tax rule hilang atau period closed | Invoice issue 422, invoice/AR/journal tidak dibuat; delivery pending terlihat |

Rekonsiliasi harian: per source portion, `accepted_qty = invoiced_qty + accepted_unbilled_qty`; per delivery, `shipped=accepted+rejected+in_transit`; stock movement↔balance/valuation; invoice gross↔AR; payment allocation↔bank/AR; Finance journal source GUID unik. Perbedaan memiliki owner, kode, umur dan prioritas di exception queue. API, data, UI dan QA rinci ditautkan dari [planning gate](../planning-gate.md).
