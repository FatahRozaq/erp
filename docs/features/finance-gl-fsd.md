# FSD-FIN — AR/AP, accounting, close dan laporan dasar MVP

**Scope:** F-07/F-08 dan bagian finansial F-09. Finance Core satu deployable/DB untuk invoice, payment, open item, tax snapshot dan journal; schema `finance` dan `accounting` punya repository/role terpisah, dengan transaksi lokal lintas schema hanya pada posting yang disetujui [PRD §26](../enterprise-erp-prd.md#26-financial-posting-matrix-awal). Controller mengaktifkan COA, posting rule dan fiscal period per legal entity sebelum transaksi riil. Lihat [policy G-02–G-07](../decisions/mvp-business-policy.md).

## Source, journal dan period

Setiap posting memakai key `(tenant,entity,source_type,source_guid,source_portion_guid?,action,leg)` yang unik permanen. `posting_intent` menyimpan source snapshot hash, rule version, business date, amount/currency/tax/cost and operation GUID. `journal` POSTED memiliki minimal dua line; jumlah debit=credit dalam base currency dan transaksi currency setelah rounding policy. Posted journal, tax snapshot dan allocation tidak diubah; koreksi membuat reversal tertaut dengan reason/checker. Account ACTIVE pada tanggal bisnis, dimension branch/department/cost center valid, period OPEN dan rule PUBLISHED wajib. Tidak ada account fallback. Data finansial memakai decimal string API, `numeric` DB dan actor/recorded time lengkap.

| Source | Debit | Credit | Gate tambahan |
|---|---|---|---|
| GRN accepted | Inventory | GRNI | receipt event dan cost snapshot idempotent |
| Vendor invoice matched | GRNI, Input Tax bila eligible | AP | PO/GRN/price match exact |
| Vendor payment | AP | Bank | bank evidence dan allocation sah |
| Dispatch | In Transit | Inventory Warehouse | movement Operations ack; belum revenue |
| POD accepted + invoice issue | AR, COGS | Revenue, Output Tax, In Transit | accepted portion dan tax snapshot; satu Finance commit |
| Customer receipt | Bank | AR atau Unapplied Cash liability | allocation dan bank ref unik |
| Approved stock loss | Shrinkage | Inventory | Operations source dan cost snapshot |

## Command dan read model

| Command/query | Guard | Hasil/failure |
|---|---|---|
| `IssueSalesInvoice` | source accepted unbilled, tax rule, period, account mapping | invoice+AR+tax+COGS journal satu commit; jika gagal tetap DRAFT dan source tersedia |
| `IssueVendorInvoice` | three-way match exact, input tax evidence, period open | invoice+AP+GRNI journal satu commit; mismatch → MATCH_EXCEPTION no posting |
| `PostCustomerReceipt` | bank ref unik, amount>0, allocations≤open AR, checker bila threshold | payment+allocation+bank/AR journal; unapplied balance tetap liability |
| `PostSupplierPayment` | verified payee, approval SoD, allocations≤open AP | payment+allocation+bank/AP journal; double ref ditolak |
| `PostManualJournal` | source/reason, maker≠checker, ≥2 line, balanced, period OPEN | journal baru POSTED; account/dimension invalid 422 |
| `ReverseJournal` | posted source, reversal permission/checker, open target period | inverse journal+link; original tetap immutable |
| `CloseFiscalPeriod` | owner cut-off attestations, no pending POD/posting, GRNI terbuka terjelaskan/diaging, trial balance dan stock/AR/AP reconcile | period CLOSED+digest+audit+event; selisih atau GRNI tanpa owner → 422 dengan daftar source |
| `ReopenFiscalPeriod` | Controller+second approver, reason dan deadline, period berikutnya belum final | new period status version/audit; tidak menghapus jurnal |
| `TrialBalance/Aging/P&L` | entity/scope, as-of date, period/data freshness | read model dengan source journal version dan generated_at; ekspor async bila besar |

Close period memverifikasi **attestation** berkontrak dari Commercial/Operations, bukan query langsung ke DB mereka. Attestation menyebut entity, cutoff, counts dan hash/source watermark; stale/missing menolak close. Dua close/reopen bersamaan diserialkan pada period row. Interval fiscal period tidak boleh overlap; insert/update memakai transaksi SERIALIZABLE + retry, sesuai [ADR-0002](../adr/0002-fiscal-period-overlap.md). Report closed period immutable as-of watermark, sedangkan current period ditandai provisional/freshness.

## Contoh dan acceptance

Invoice sales 3 unit @200, PPN efektif 11%, cost snapshot 110/unit: Dr AR 666 / Cr Revenue 600 / Cr Output Tax 66; Dr COGS 330 / Cr In Transit 330. Customer membayar 400 → Dr Bank 400 / Cr AR 400, open AR 266. Vendor GRN 6 @100 → Dr Inventory 600 / Cr GRNI 600; vendor invoice 6 @100 + PPN 66 → Dr GRNI 600 / Dr Input Tax 66 / Cr AP 666. Supplier payment 300 → Dr AP 300 / Cr Bank 300, open AP 366. Trial balance menjumlah seluruh line posted per entity/period dan harus debit=credit; aging outstanding harus sama dengan AR/AP GL control account setelah item unapplied/suspense dan timing exceptions direkonsiliasi.

| Kegagalan terukur | Expected |
|---|---|
| Rule tax atau account mapping tidak aktif | 422, tidak ada invoice ISSUED/journal; source tetap retryable |
| Dua worker issue source portion sama | satu invoice dan satu journal; yang lain mengembalikan hasil pertama atau conflict aman |
| Payment 400 ke AR 266 tanpa unapplied policy | 422; tidak ada allocation berlebih |
| Period CLOSED menerima issue/reversal backdated | 422; Controller memilih reopen atau correction current period |
| Journal debit 100, kredit 99 | 422 unbalanced, no POSTED journal |
| Close period dengan POD pending Finance | 422 `PERIOD_CLOSE_RECONCILIATION_PENDING`, source IDs terlihat operator |

Rekonsiliasi harian mencocokkan posting intent→journal, invoice gross→AR/AP, payment allocation→open item, GRNI→unbilled GRN, inventory valuation→GL control, dan tax document→ERP invoice. Setiap mismatch mendapat owner, severity dan SLA, tidak disembunyikan dalam laporan. API/data/UX/test plan rinci di [planning gate](../planning-gate.md).
