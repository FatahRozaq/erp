# FSD-INV-WMS — Stok, reservasi, picking, delivery dan adjustment MVP

**Scope:** F-05/F-06 untuk satu legal entity, multi branch/warehouse. Operations adalah owner movement, balance, lot, reservation, pick, pack dan delivery. Transfer antar warehouse dan stock count lengkap adalah Phase 2; adjustment berizin MVP tersedia untuk selisih pilot. Lihat [G-02/G-03](../decisions/mvp-business-policy.md) dan [O2C](o2c-fsd.md).

## Inventory model dan posting

Stock key `(tenant,entity,warehouse,sku,ownership,lot?,status)`; status `SELLABLE|HOLD|DAMAGED|IN_TRANSIT`. Cost pool key `(entity,sku,ownership)` dalam mata uang dasar, bukan per warehouse. Balance adalah proyeksi yang harus sama dengan jumlah movement posted; ledger append-only dan setiap `(source_type,source_guid,source_line_guid,leg)` unik permanen. Stock `sellable−reserved≥0`; lot expiry wajib untuk SKU berpolicy expiry; serial unik dalam tenant untuk SKU serialized. Movement menyimpan qty base, unit cost snapshot, value, direction, business date, recorded_at, actor, operation, correlation dan reversal reference. Semua posting menggunakan satu transaksi Operations: lock balance/limit dalam urutan `(entity,sku,warehouse,lot,status)`, cek ulang invariant, append movement, update balance/cost, audit+outbox lalu commit. Deadlock/serialization retry mengulang seluruh command dengan operation GUID sama.

## Reservation sampai POD

| Command | Guard | Hasil | Failure |
|---|---|---|---|
| `ReserveStock` | SO approved ack, SKU/warehouse active, available cukup; FEFO bila lot aktif | HELD/ALLOCATED, reserved counter bertambah, event | kurang → BACKORDERED tanpa negative stock |
| `ReleaseReservation` | source SO cancel/revision, belum consumed | release sekali, reserved counter turun | duplicate no-op idempotent |
| `ClaimPickTask` | task OPEN, user warehouse scope, version | assignee+lease expiry; stale task ditolak | dua picker: satu menang |
| `ScanPickLine` | SKU/lot/serial cocok; qty≤allocated; serial belum dipick | scan leg+picked qty; audit device | mismatch/expired 422 |
| `Pack/Dispatch` | picked qty sah, pack list cocok, credit recheck ack | reservation consumed; warehouse→in-transit legs; delivery DISPATCHED | dependency pending → tidak ship |
| `AcceptPOD` | bukti signed/photo checksum valid, recipient dan accepted/rejected per line, sum≤shipped | accepted source portions+cost snapshot; pending Finance | evidence gagal → REVIEW_REQUIRED |
| `ApproveAdjustment` | count/evidence+reason, maker≠checker, period open | positive/negative movement baru; balance+cost; audit | negative sellable atau missing valuation 422 |

Satu delivery line dapat memiliki beberapa POD portions. `shipped_qty = accepted_qty + rejected_qty + still_in_transit_qty` per line; kelebihan atau duplicate portion ditolak dengan lock header/line. Barang rejected yang kembali ditransfer dari IN_TRANSIT ke HOLD/SELLABLE menurut inspeksi, tanpa revenue/COGS. POD accepted memicu Finance; delivery `DELIVERED` hanya setelah ack Finance. Period close menolak accepted-unbilled dan in-transit yang tidak direkonsiliasi menurut policy cut-off.

## Contoh dan acceptance

Stock awal 10 pcs @110. Reserve SO 5 → sellable fisik 10, reserved 5, available 5. Pick/dispatch 5 → sellable fisik 5, reserved 0, in transit 5 bernilai 550. POD accepted 3/rejected 2 → in transit 0, returned sellable/hold 2 bernilai 220, tiga unit cost snapshot 330 menunggu Finance. Setelah Finance invoice/journal ack, movement dan GL cocok 330. Dua request reserve paralel 7 dan 7 atas stok 10: tepat satu berhasil. Dua picker claim satu task: satu assignee. Replay dispatch/POD dengan key sama tidak menambah movement/portion. Adjustment +2 dari count 12 vs book 10 memerlukan approval dan reason; count 8 vs book 10 mem-post -2 dengan valuation snapshot, bukan `UPDATE balance=8`.

Rekonsiliasi per `(entity,sku,ownership,warehouse,status)` membandingkan saldo proyeksi dengan jumlah movement; per cost pool total value dengan receipt/dispatch/reversal legs; per delivery shipped dengan accepted/rejected/in-transit; per accepted source dengan Finance invoice/COGS ack. Selisih masuk exception queue, bukan dipaksa menjadi nol. API/data/UX/test plan rinci di [planning gate](../planning-gate.md).
