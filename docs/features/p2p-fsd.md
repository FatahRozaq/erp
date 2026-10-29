# FSD-P2P — Purchase requisition sampai AP dan pembayaran MVP

**Scope:** PR sederhana, PO approval, partial GRN, three-way match, vendor invoice, AP/payment dan GRNI (F-04/F-07/F-08). **Owner:** Commercial Purchase, Operations Inventory, Finance AP/GL. Mengikuti [G-06/G-07](../decisions/mvp-business-policy.md), [FSD slice PO→GRN→GRNI](first-slice-fsd.md), dan [PRD F-04/F-07](../enterprise-erp-prd.md#17-kontrak-fitur-besar). RFQ, blanket PO, return-to-vendor penuh dan tolerance>0 adalah Phase 2.

## State dan source

| Aggregate | State MVP | Invariant |
|---|---|---|
| PurchaseRequisition | DRAFT→SUBMITTED→APPROVED/REJECTED→CONVERTED/CANCELLED | approved qty tidak melebihi requested; line boleh menjadi beberapa PO portions; maker≠approver |
| PurchaseOrder | DRAFT→SUBMITTED→APPROVED→PARTIALLY_RECEIVED→RECEIVED→CLOSED; CANCELLED sebelum receipt | approved qty snapshot; amendment baru untuk qty/price; nomor permanen |
| GoodsReceipt | DRAFT→POSTED/VOIDED | accepted+hold+damaged≤sisa PO; movement per source leg unik; posted immutable |
| VendorInvoice | DRAFT→MATCH_EXCEPTION/READY→ISSUED→PARTIALLY_PAID/PAID | exact qty+price match, source portion sekali; nomor vendor+entity+tax period unik |
| SupplierPayment | DRAFT→APPROVED→POSTED→REVERSED | allocated+unapplied=payment net of fee; bank ref unik |

PR approval tidak mencadangkan stok atau membuat AP. PO line dan GRN line mengirim entered qty/UOM serta base qty; owner menguji `base=entered×numerator/denominator` terhadap conversion published yang berlaku, lalu menyimpan GUID versi. Pada base UOM, conversion version NULL dan rasio 1:1. PO `APPROVED` menerbitkan receipt limit Operations dari snapshot qty/UOM/price. GRN menambah stok hanya accepted sesuai klasifikasi; hold/damaged berada di ledger tersendiri dan tidak menjadi sellable. Finance menerima GRN event dan mem-post GRNI dengan source GUID unik; vendor invoice hanya dapat issue setelah GRNI dan exact match. Referensi lintas owner GUID, bukan FK SQL. Buyer dan AP melihat status asinkron/pending bila event belum diproses.

## Command/guard/hasil

| Command | Guard dan permission | Owner write | Failure |
|---|---|---|---|
| `Submit/ApprovePR` | requester scope branch/entity, item dan qty valid; approver bukan maker | PR revision, decision, audit, outbox | 403 SoD; 412 stale |
| `Create/ApprovePO` | vendor account aktif, PR portions approved atau direct PO beralasan, tax/terms/warehouse sah, threshold G-06 | PO snapshot+number+approval+outbox | vendor blocked 422; no approver 422 |
| `AmendPO` | PO belum CLOSED; tidak mengurangi qty di bawah received/committed; approval ulang | revision baru, receipt limit delta event setelah approval | receipt limit lama tetap sampai ack; no silent historical edit |
| `PostGRN` | PO approved, source ref unik, UOM/lot/expiry sesuai policy, qty remaining≥accepted; lock limit | GRN+line+movement+balance+cost pool+outbox dalam satu Operations transaction | over 0 tolerance 422; concurrent 6+4+1 menolak 1 |
| `MatchVendorInvoice` | PO/GRN/price/tax source snapshot tersedia; duplicate vendor invoice nomor dicek | draft match result per line dan exception code | unmatched/invoice-before-receipt → MATCH_EXCEPTION, no AP/GL |
| `IssueVendorInvoice` | semua line READY, period OPEN, tax rule aktif, amount server-calculated | AP invoice+GRNI/input tax/AP journal satu Finance transaction | missing mapping/period 422 rollback semua |
| `Approve/PostSupplierPayment` | payee verified, maker≠checker, bank evidence, allocation≤open AP | payment+allocation+bank/AP journal+audit/outbox | wrong bank/duplicate ref 409/422 |

Koreksi GRN posted membuat movement lawan dan dokumen baru; jika vendor invoice sudah issued, gunakan vendor credit/debit note, bukan edit. Harga/freight final setelah sebagian stok terjual memakai adjustment inventory/COGS pada periode terbuka atau correction baru pada periode berikutnya. Cancellation PR/PO melepaskan commitment tepat sekali; PO tidak dapat dibatalkan ketika ada receipt posted kecuali reversal source selesai. AP period close menunggu GRNI unmatched dan posting intent pending=0 atau exception Controller yang disetujui.

## Contoh numerik

PO 10 pcs @100 IDR, PPN masukan efektif 11%, freight 0, over-receipt tolerance 0. GRN pertama 6 pcs: Dr Inventory 600 / Cr GRNI 600, average cost bertambah dari pool sesuai G-02. Vendor invoice untuk 10 tiba: 6 matched, 4 exception; seluruh invoice masih `MATCH_EXCEPTION` tanpa AP/jurnal. GRN kedua 4: Dr Inventory 400 / Cr GRNI 400. Invoice 10 @100 + PPN 110 kemudian issue: Dr GRNI 1.000 / Dr Input Tax 110 / Cr AP 1.110. Payment supplier 600: Dr AP 600 / Cr Bank 600; open AP 510. Payment kedua 510 menutupnya. Jika harga invoice 105, match price variance 50 dan issue ditolak sampai PO amendment/credit note; tidak memakai tolerance tersembunyi. Freight 100 yang layak kapitalisasi pada dua line net 600 dan 400 dibagi 60/40, residual deterministik ke nilai terbesar (lihat G-07).

## Acceptance dan rekonsiliasi

| Given/When | Then |
|---|---|
| Dua GRN paralel masing-masing 6 untuk PO sisa 10 | tepat satu commit atau total accepted≤10; tidak ada stock movement berlebih |
| GRN 6, invoice 10 | invoice MATCH_EXCEPTION; AP=0, input tax=0, GRNI masih 600 |
| Invoice 10 @105 atas PO @100 | 422 price mismatch, no journal |
| Invoice 10 @100 dikirim ulang | satu invoice/source line/journal, response idempotent |
| Payment 600 dari AP 1.110 dikirim ulang | open AP tetap 510, satu bank reference/journal |
| User entity lain menebak GUID PO/GRN | 403/404, tidak ada data terungkap |

Query rekonsiliasi: per PO line `approved_qty ≥ accepted_receipt_qty`; per GRN source `inventory_value = GRNI_credit` sebelum match; per vendor invoice `matched_value = GRNI_debit` dan `gross = AP_credit`; per payment `allocated = AP_debit`. Exception queue memperlihatkan source, umur, owner dan langkah koreksi. API/data/UX/test plan rinci di [planning gate](../planning-gate.md).
