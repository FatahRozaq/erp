# FSD-001 — SKU → PO → Goods Receipt → Stock Ledger

**Status:** baseline implementasi, 28 Oktober 2026. **Owner:** Master (Platform), Purchase (Commercial), Inventory (Operations), Finance GRNI. **Scope:** satu tenant dan legal entity per dokumen, barang stok domestik IDR, tanpa bin dan tanpa lot pada fixture dasar. Rule pajak, valuasi, approval dan aktivasi mengikuti [keputusan bisnis](../decisions/mvp-business-policy.md). Kontrak HTTP berada di `contracts/openapi/{master,purchase,inventory}/v1.yaml`; event di `contracts/events/`; DDL di `backend/golang/services/{platform,commercial,operations,finance}/migrations/`.

Prasyarat fixture M0: tenant, legal entity, branch, warehouse, principal/permission, vendor account aktif, approval policy dan akun Inventory/GRNI serta fiscal period OPEN. Slice ini tidak mendefinisikan lifecycle organisasi/vendor/IAM; owner M0 menyediakannya lewat contract atau seed integration test yang sah. Data produksi tidak boleh memakai fixture tersebut dan tetap memerlukan policy activation.

Keputusan ownership receipt limit tercatat pada [ADR-0001](../adr/0001-receipt-limit-owner.md); guard fiscal period pada [ADR-0002](../adr/0002-fiscal-period-overlap.md).

## 1. Aktor, permission dan fakta owner

| Aksi | Permission | Scope tambahan | Owner penulisan |
|---|---|---|---|
| Buat UOM / publish SKU | `master.uom.create` / `master.sku.publish` | tenant, entity assortment | Platform |
| Buat/submit PO | `purchase.po.create/submit` | entity, branch | Commercial |
| Approve PO | `purchase.po.approve` | entity, approval step; bukan maker | Commercial/Policy |
| Buat/post GRN | `inventory.receipt.create/post` | entity, warehouse | Operations |
| Baca stock ledger | `inventory.movement.read` | entity, warehouse | Operations |

Permintaan membawa legal entity pilihan tetapi server memverifikasi membership; GUID lintas owner bukan bukti izin. Master menerbitkan `master.product.published.v1`; Purchase menyimpan snapshot SKU/UOM saat PO submit; Operations menerima `purchase.order.approved.v1` untuk membentuk receipt limit otoritatif dan menyimpan snapshot PO line. Event dipakai untuk proyeksi yang memiliki guard versi; belum terproyeksi berarti post ditahan.

## 2. Aturan command dan batas transaksi

| Command | Precondition/guard | Efek atomik pada owner | Hasil dan kesalahan |
|---|---|---|---|
| `CreateUom` | code unik per tenant, name valid | UOM ACTIVE, audit | 201; 409 code duplicate |
| `CreateSku` | kode aktif unik per tenant, UOM valid, tipe barang STOCKED | SKU draft, audit | 201 DRAFT; 409 code duplicate |
| `PublishSku` | DRAFT, cost class dan base UOM valid, If-Match | PUBLISHED+version, audit, outbox | 200; 412 stale, 422 missing attribute |
| `CreatePurchaseOrder` | vendor/account aktif untuk entity, SKU PUBLISHED, qty>0, unit price≥0 | PO DRAFT+line, audit | 201; 422 invalid vendor/SKU |
| `SubmitPurchaseOrder` | DRAFT, line lengkap, policy aktif, If-Match, Idempotency-Key | nomor PO permanen, snapshot price/UOM/tax/policy, status WAITING_APPROVAL, audit, outbox, idempotency result | 200; 409 key mismatch; 412 stale; 422 rule |
| `ApprovePurchaseOrder` | pending step, approver sah, maker-checker, If-Match | decision, PO APPROVED, version, audit, outbox | 200; 403 SoD; 409 competing decision; 412 stale |
| `CreateGoodsReceipt` | PO APPROVED, warehouse entity sama, lines dari PO | GRN DRAFT+line, audit | 201; 422 scope/state |
| `PostGoodsReceipt` | GRN DRAFT, qty accepted>0, accepted≤PO remaining, SKU/UOM snapshot valid, policy aktif, period open, If-Match, Idempotency-Key | lock PO receipt counter + stock balance dalam urutan key tetap; movement IN immutable, average cost dan balance baru, GRN POSTED, audit+outbox+result | 200; 409 duplicate mismatch/PO race; 412 stale; 422 overreceipt/period/negative math |

Satu `PostGoodsReceipt` mencatat seluruh line GRN atau rollback seluruhnya. Partial receiving berarti GRN baru untuk sisa PO; tidak ada posting parsial tersembunyi pada satu GRN. Setelah `purchase.order.approved.v1` dikonsumsi, Operations membuat `receipt_limit` dengan approved qty immutable dan received counter mutable untuk PO line, lalu menjadi **owner otoritatif remaining receipt**. Post GRN mengunci `receipt_limit`, memvalidasi `received_qty + accepted_qty ≤ approved_qty`, dan menaikkan counter dalam transaksi yang sama dengan movement. Purchase menerima `warehouse.goods_receipt.posted.v1` untuk proyeksi status, tidak memutus remaining saat post. PO amendment sesudah approval di luar slice ini dan harus memakai protokol revisi limit yang menunggu ack Operations; cancel/reissue hanya bila belum ada receipt. Event approval belum terproyeksi → GRN menunggu, tidak memakai snapshot stale.

Urutan lock dalam Operations: GRN header → `receipt_limits` terurut menurut PO line GUID → `cost_pools` terurut entity/SKU/ownership → `stock_balances` terurut entity/warehouse/SKU/status. Pool/balance yang belum ada dibuat dengan unique key dan `INSERT ... ON CONFLICT DO NOTHING`, lalu di-lock dan dibaca ulang. Cek ulang remaining dan cost setelah lock. Tidak ada panggilan jaringan saat transaksi DB terbuka. `business_operation_guid` dan source line/leg key unik permanen; retry key sama menghasilkan hasil pertama. PostgreSQL [row locks dan isolation](https://www.postgresql.org/docs/18/transaction-iso.html) menjadi dasar uji konkurensi.

```mermaid
sequenceDiagram
  actor Approver
  participant Purchase
  participant Broker
  participant Operations
  participant Finance
  Approver->>Purchase: ApprovePurchaseOrder (If-Match, key)
  Purchase->>Purchase: commit PO APPROVED + audit + outbox
  Purchase-->>Broker: purchase.order.approved.v1
  Broker-->>Operations: deliver at least once
  Operations->>Operations: inbox dedup + create receipt limits
  actor Receiver
  Receiver->>Operations: PostGoodsReceipt (If-Match, key)
  Operations->>Operations: lock limits/cost pool/balance; commit GRN+movement+outbox
  Operations-->>Broker: warehouse.goods_receipt.posted.v1
  Broker-->>Purchase: update received projection idempotently
  Broker-->>Finance: create posting intent, post GRNI journal
  Finance-->>Broker: accounting.journal.posted.v1
  Broker-->>Operations: posting ack for reconciliation
```

## 3. State, angka dan rekonsiliasi

PO: `DRAFT → WAITING_APPROVAL → APPROVED → PARTIALLY_RECEIVED → RECEIVED → CLOSED`; reject/return sebelum approved kembali ke DRAFT revision. GRN: `DRAFT → POSTED` atau `DRAFT → VOIDED`; koreksi posted memakai return/adjustment baru. SKU: `DRAFT → PUBLISHED → INACTIVE`; SKU yang telah direferensikan tidak dihapus fisik.

Contoh fixture: PO 10 unit SKU-A @ IDR 100, approved. GRN-1 menerima 6; movement masuk 6 × 100=600, remaining PO 4, Dr Inventory 600/Cr GRNI 600 lewat Finance posting intent. GRN-2 menerima 4; nilai 400, PO menjadi RECEIVED setelah event ack Purchase. GRN paralel lain yang mencoba 5 ketika receipt limit tersisa 4 memperoleh `PURCHASE_PO_RECEIPT_EXCEEDS_REMAINING` dan tidak menghasilkan movement. Bila stok awal 10 @100 dan receipt 10 @120, average baru 110; residual disimpan deterministik seperti G-02.

Rekonsiliasi harian: (1) jumlah movement IN/OUT per balance key = balance tersimpan, (2) `receipt_limits.received_qty` = jumlah GRN posted per PO line ≤ approved qty, (3) proyeksi received Purchase = jumlah event GRN posted setelah lag nol, (4) setiap GRN posted memiliki posting intent Finance dan akhirnya jurnal GRNI, (5) outbox+inbox lag/exception terlihat. Period close menolak unmatched posting. Source cross-owner menyimpan GUID+snapshot, FK lokal hanya dalam owner.

## 4. Data model, migration dan tes

Platform: `master.skus`, `master.uoms`; Commercial: `purchase.purchase_orders`, `purchase.purchase_order_lines`; Operations: `inventory.receipt_limits`, `inventory.goods_receipts`, `inventory.goods_receipt_lines`, `inventory.cost_pools`, `inventory.stock_balances`, `inventory.stock_movements`; Finance: `finance.posting_intents`, `accounting.accounts/fiscal_periods/journals/journal_lines`. Tiap service juga punya migration `runtime` untuk business operation registry, idempotency, outbox, inbox dan audit. Setiap mutable row mempunyai `id/guid/created_at/by/updated_at/by/deleted_at/by/version` sesuai [standar DB](../engineering/database-standards.md). Ledger/journal append-only tidak punya `updated_*/deleted_*`; actor asal dan `business_operation_guid` tetap disimpan. Migration per owner dan urutan: runtime+master → PO → receipt limit+GRN+cost pool/balance/movement → posting intent/GL → backfill → aktifkan command. Mutasi fiscal period wajib transaksi `SERIALIZABLE` dan retry lengkap pada `40001` agar interval tidak overlap tanpa extension PostgreSQL tambahan. Index berdasarkan tenant/entity/status/business_date dan unique source key; tidak ada partisi sebelum profil volume dan ADR.

Tes penerimaan: publish SKU dua kali dengan key sama; PO 10, dua receipt 6+4; dua proses berebut remaining 4; qty negatif/lebih; entity/warehouse silang; maker approve sendiri; stale If-Match; crash setelah commit sebelum event publish; event duplikat; Finance gagal lalu retry; ledger vs balance vs GRNI tetap cocok. Angka contoh harus menjadi fixture integration, bukan hanya unit test.

**Rujukan industri:** [OpenAPI 3.1.1](https://spec.openapis.org/oas/v3.1.1.html), [PostgreSQL constraints](https://www.postgresql.org/docs/18/ddl-constraints.html), dan [OWASP API authorization](https://api-security.owasp.org/editions/2023/en/0xa1-broken-object-level-authorization/).
