# QA-002 — Vektor kontrak dan penerimaan Foundation+MVP

**Status:** input/output deterministik untuk test producer, consumer, API, database, UI dan E2E ketika kode dibuat. Nilai synthetic dan tanggal bisnis `2026-10-28`; timezone `Asia/Jakarta`; currency IDR; qty base pcs; seluruh GUID dari fixture [DATA-003](../features/mvp-data-dictionary.md). Expected output numeric memakai decimal string, bukan float. Rujukan endpoint adalah [OpenAPI kanonik](../../contracts/openapi/README.md), event ada di [matriks producer/consumer](../../contracts/events/README.md). Tes yang membutuhkan runtime baru dijalankan setelah handler/worker/UI ada; dokumen ini adalah oracle sebelum kode.

## Kontrak API dan state

| ID / req | Given + When | Expected HTTP/hasil | Persist/audit/event yang diperiksa |
|---|---|---|---|
| V-01 F-01 | Admin `E-A` invite email baru dengan role subset | 201 `INVITED`; token tak ada di response | satu invitation hash, audit actor; email job boleh pending |
| V-02 F-01 | Sales `B-A` GET/submit dokumen `E-B` via GUID | 404 untuk read, 403 untuk action; no data `E-B` | deny audit tanpa payload PII; no write |
| V-03 F-01 | Grant revoke atau user suspend, lalu token lama dipakai ≥60 detik | 401/403; refresh ditolak | session_version meningkat; event `iam.user.suspended.v1` bila suspend |
| V-04 F-01 | Dua penulis PATCH role/org pada ETag `"1"` | satu 200, satu 412 `STALE_VERSION` | version naik sekali, satu audit sukses |
| V-05 F-02 | Customer identity sudah punya account E-A, buat account E-B memakai `party_guid` | 201 account baru, party GUID tetap | dua account scoped, identity satu; no cross-entity write |
| V-06 F-02 | Maker propose bank token, maker sendiri approve | 403 `APPROVAL_SOD_VIOLATION` | value lama tetap, proposal pending, audit deny |
| V-07 F-02 | GRN 2 carton dengan conversion published 1:12; kemudian versi 1:10 | movement `24` pcs; histori tetap `24` | old conversion GUID/version tersimpan, event tidak berubah |
| V-08 F-03 | SO gross 300, exposure 850, limit 1000, deposit eligible 100 | net exposure 750, available 250; 422 `CREDIT_LIMIT_EXCEEDED` untuk SO 300 | no reservation; exposure bucket tidak digandakan |
| V-09 F-03 | Dua submit SO sama key+body; lalu key sama body beda | hasil pertama sama dua kali; body beda 409 `IDEMPOTENCY_KEY_REUSED` | satu nomor, satu approval, satu bucket |
| V-10 F-03 | SO approved revision 1; ubah qty saat reservation held | 201 revision 2 `PENDING_RELEASE`; submit baru ditahan sampai release ack | approval lama invalid; no double hold |
| V-11 F-03 | Dua writer override pada SO revision sama ketika policy disabled | 422 `CREDIT_OVERRIDE_DISABLED` keduanya | no override; bila enabled, maksimal satu active override |
| V-12 F-04 | PO 10 @100, GRN 6 lalu 4; GRN tambahan 1 | dua post 200, ketiga 422 `PURCHASE_PO_RECEIPT_EXCEEDS_REMAINING` | stock +10, GRNI 1000, receipt limit 10 |
| V-13 F-04 | PO approved 10 sudah received 6, amend total 5 | 422 `PURCHASE_RECEIVED_QTY_EXCEEDS_AMENDMENT` | approved/received snapshot tetap |
| V-14 F-04 | Vendor invoice 10 @105 vs PO @100 | `MATCH_EXCEPTION`, no issue | AP/GL zero, per-line variance 50; after draft correction @100 can match |
| V-15 F-05 | 100 concurrent reserve 1 pada sellable 10 | ≤10 HELD; 90 backorder/insufficient | balance nonnegative; unique source leg |
| V-16 F-05 | Reservation HELD 5: consume 3 then expire/release remaining 2 twice | consumed 3, released 2; retry same result | one consume and one release movement, no negative balance |
| V-17 F-05/06 | Serial X scanned into two packs | first accepted; second 409 `SERIAL_ALREADY_PACKED` | serial one active pack; no duplicate outbox |
| V-18 F-06 | Dispatch 5; POD accepted 3, rejected 1, in-transit 1 | `accepted+rejected+in_transit=5`; only 3 eligible invoice | one source portion per accepted quantity; event `warehouse.delivery.accepted.v1` |
| V-19 F-06 | POD correction and Finance issue race on same source portion | Finance claim atau issue menang melalui row lock; bila claim menang, issue 409/pending sampai correction event applied; bila issue menang, correction 422 `POD_ALREADY_INVOICED` | no invoice on stale accepted qty; proof original/correction immutable |
| V-20 F-07 | Sales invoice 3×200 + tax 66, cost 3×110 | gross 666; debit AR 666, credit revenue 600/tax 66; debit COGS 330, credit in transit 330 | invoice+journal atomic; event `finance.sales_invoice.issued.v1` |
| V-21 F-07 | AR 100, payment 100 allocates 60 and leaves 40 unapplied; then apply 20 | first outstanding 40; after second outstanding 20 dan unapplied 20 | payment=allocation+unapplied+fee; bank ref unique |
| V-21a F-07 | Customer receipt 100 dengan `allocations=[]`, lalu apply 20 ke AR 100 | posted: eligible deposit 100 dan AR 100; apply: deposit 80 dan AR 80; exposure tetap 0 jika tanpa komitmen lain | `finance.payment.posted.v1` memuat `unapplied_base=100`, lalu `finance.payment.allocation_applied.v1` tepat sekali; fee 0 |
| V-22 F-07 | Two allocation writers each allocate 60 to same open AR 100 | one succeeds, second fails/retries to ≤40 | no negative outstanding, journal one per allocation |
| V-23 F-07 | Reverse posted customer receipt 60 while concurrent SO submit, original period closed, next period open | Credit reversal hold blocks submit; reversal document 201, journal inverse in next period; setelah event applied hold dilepas | bank ref original retained; open item/exposure rises 60 tanpa overcommit |
| V-23a F-07 | AR 100, receipt 100 seluruhnya unapplied, ApplyUnapplied 20, lalu reverse penuh | sebelum reversal AR 80/deposit 80/exposure 0; setelah reversal AR 100/deposit 0/exposure 100; hold dilepas setelah kedua bucket diperbarui | event reversal memuat `reopened_allocations=20` dan `unapplied_reversed_base=80`; duplicate/late event tidak mengganda exposure |
| V-24 F-08 | Missing posting rule or period closed at invoice issue | 422 `POSTING_RULE_MISSING` or `PERIOD_CLOSED` | invoice remains DRAFT, no number/GL |
| V-25 F-08 | Trial balance period with debit 666 and credit 600+66 | debit=credit 666 | GL projection matches journal lines; report watermark present |
| V-26 F-08 | Close with Operations attestation stale or stock delta ≠0 | 422 `PERIOD_CLOSE_RECONCILIATION_PENDING` | period OPEN, owner+delta in scoped details |
| V-27 F-09 | Approval boundaries 9,999,999/10,000,000/100,000,000/100,000,001 | Supervisor/Manager/Manager/Director | policy version and matched rule trace recorded |
| V-28 F-09 | Decision revision 1 arrives after source revised to 2 | ignored as stale, source stays pending revision 2 | inbox dedup; old decision remains audit history |
| V-29 F-09 | Tax net 120,000 × DPP factor 11/12 × 12% | DPP 110,000, VAT 13,200, gross 133,200 | tax rule version, rounding trace, no float |
| V-30 F-10 | CSV 100 rows: 97 valid, 3 invalid; commit then replay | 97 committed once, 3 row errors stable | external ID registry 97 unique, no 3 bad writes |
| V-31 F-10 | File hash or policy watermark changes after preview | 409 `IMPORT_SNAPSHOT_CHANGED` | no domain command executed |
| V-32 F-10 | Report job E-A READY, actor switches to E-B and downloads same GUID | 404/403; signed URL not issued | scoped download audit deny; no PII leak |

## Producer/consumer contract cases

| Event | Producer invariant | Consumer/idempotency/ordering invariant | Failure injection |
|---|---|---|---|
| `master.product.published.v1` | SKU class dan conversion version snapshot diterbitkan setelah publish; 2 carton = 24 pcs | Commercial/Operations menyimpan version snapshot dan menghitung base qty yang sama; histori tidak berubah saat conversion baru terbit | duplicate event, conversion V2 tiba sebelum PO V1 selesai |
| `master.party.published.v1` | Platform publishes version after checker; no bank/tax plaintext | Commercial/Finance cache scoped version; older version never replaces newer | duplicate and gap version → snapshot fetch/park |
| `sales.order.submitted.v1`, `sales.order.approved.v1` | Commercial emits after local state+credit ack | Policy creates one instance per source revision; Operations reserves only approved current revision | approval response lost; old revision event late |
| `policy.approval.decided.v1` | one decision per step/revision | Commercial/Finance consumes once, checks revision and policy GUID; ack pending visible | duplicate, old revision, gap aggregate version |
| `purchase.order.approved.v1` | immutable approved qty/revision | Operations receipt limit unik per PO line, menyimpan source aggregate version; revisi lebih baru mengubah limit hanya bila ≥received, versi lama tidak mengubah lagi | PO amendment event before release ack |
| `warehouse.goods_receipt.posted.v1` | movement/balance/outbox one commit | Finance GRNI intent once per source leg; amount matches cost snapshot | 2× replay, crash after Finance commit |
| `inventory.stock.reserved.v1` | reservation/held committed together | WMS creates task only for current SO revision and qty, once | cancel arrives before reserve event |
| `warehouse.delivery.shipped.v1`, `warehouse.delivery.accepted.v1` | no shipped event before Inventory ack; accepted portion unique | Finance creates eligible billing source once; rejects quantity beyond accepted | POD duplicate, Finance outage, out-of-order shipped/accepted |
| `warehouse.delivery.pod_corrected.v1` | signed accepted/rejected delta hanya sebelum Finance issue | Finance/Credit mengubah projection portion sekali tanpa mengedit event lama; invoice issued menolak koreksi | duplicate correction, Finance issue race, out-of-order original/correction |
| `finance.sales_invoice.issued.v1`, `finance.vendor_invoice.issued.v1`, `finance.payment.posted.v1` | source+action unique; invoice/payment and journal local atomic | Commercial/Operations projection only; never posts GL again | broker replay, subscriber crash after commit |
| `finance.payment.allocation_applied.v1` | allocation+journal reclass+outbox satu commit; aggregate version meningkat | Commercial Credit memindahkan nilai AR dan eligible deposit, dedup event dan tahan gap versi | replay, event mendahului payment.posted, dua ApplyUnapplied bersamaan |
| `finance.payment.reversed.v1` | original link dan reopened allocations/journal inverse satu Finance commit | Credit mengembalikan exposure sekali; report aging menghitung reversal | duplicate reversal event, late original posted event |
| `accounting.journal.posted.v1`, `accounting.period.closed.v1` | journal balanced; close has attestations | reports update watermark once; closed period blocks backdated post | late invoice event before cut-off, duplicate close |

Every consumer test validates JSON Schema Draft 2020-12 example, unknown optional field tolerance within major v1, required-field break rejection, aggregate version gap parking, inbox uniqueness, DLQ owner/age and replay with same business operation GUID. Runtime tests record request/event/operation GUID and reconciliation R-01–R-08 from [DATA-002](../features/mvp-physical-data-design.md#reconciliation-queries-yang-wajib-ada). Static lint is evidence that contract parses; it is not evidence that a service implements it.
