# WO-001 — Urutan perintah AI dan checklist implementasi ERP

Gunakan bersama [TL-001 timeline](implementation-timeline.md), [prompt siap salin per ID](ai-work-order-prompts.md), [rekomendasi model per ID](ai-model-routing.md), [PRD](../enterprise-erp-prd.md), [standar engineering](../engineering/README.md), [kontrak API/event](../../contracts/openapi/README.md), dan [gate rollout](../operations/roadmap-rollout-and-runbook.md). **R-01 dan R-02 selesai sebagai paket perencanaan**; [audit R-01](r-01-audit.md) mencatat gap detail dan [register R-02](r-02-dependency-register.md) mencatat input aktual yang belum tersedia. G0 masih PARTIAL. Work order implementasi belum dicentang dan bukti kode/runtime belum ada. ID di bawah adalah urutan default yang aman; kerjakan satu ID per instruksi AI. Tim dapat mengerjakan beberapa ID paralel hanya jika prerequisite dan ownership datanya jelas.

## 1. Perintah yang dapat disalin untuk setiap paket

Ganti `<ID>` dengan ID checklist berikut, misalnya `B-01`:

> Kerjakan work order **<ID>** pada `docs/roadmap/ai-work-orders.md` sesuai `docs/roadmap/implementation-timeline.md`. Baca PRD, FSD, data, OpenAPI/event, UX, QA, ADR, dan standar engineering yang relevan. Audit keadaan repository lebih dulu; jangan mengulang pekerjaan yang sudah terbukti selesai. Kerjakan hanya output paket ini dan dependency minimum yang dibutuhkan. Untuk paket kode, sertakan migration schema/function/grant berversi dan backend Echo v5, web Metronic melalui wrapper, mobile Flutter bila relevan, test, dokumentasi, observability, dan runbook. Jalankan bukti penerimaan untuk alur normal, partial, duplicate, concurrency, auth/scope, failure/retry dan reconciliation yang berlaku. Ubah kontrak lebih dulu jika wire behavior berubah. Tandai kotak <ID> `[x]` hanya jika bukti penerimaan paket ini lulus; gate fase diperiksa terpisah sebelum maju ke fase berikutnya. Jika ada dependensi eksternal, teruskan bagian yang bisa dikerjakan lalu laporkan item tepat yang tertahan. Akhiri dengan file yang berubah, test/hasil, risiko, keputusan owner yang diperlukan, dan ID berikutnya yang siap. Jangan mengaktifkan produksi atau memakai data/credential nyata tanpa gate dan otorisasi yang berlaku.

**Aturan selesai untuk paket kode:** perubahan harus mempunyai ownership dan permission jelas; migration schema/function/grant aman dan function PostgreSQL untuk invariant lokal digunakan sesuai [ADR-0004](../adr/0004-versioned-database-functions.md); request/response/event kompatibel; audit/log tanpa PII/secret; tes relevan lulus; error/pending terlihat; `version`, idempotency, outbox/inbox dan reconciliation diuji bila berlaku; UX loading/empty/error/keyboard diuji; dokumentasi dan runbook diperbarui. [Definition of Ready/Done PRD](../enterprise-erp-prd.md#56-definition-of-ready) dan [QA-001](../quality/mvp-verification-plan.md) menjadi pagar umum. Bukti manusia seperti persetujuan pajak, lisensi dan UAT tidak boleh dicentang oleh AI atas nama owner.

## 2. T0 Mobilisasi — W01–04

Sumber: [PRD §53–56](../enterprise-erp-prd.md#53-mvp-definition-dan-prioritas-moscow), [gate desain](roadmap-planning-gate.md), dan [baseline workload](../engineering/slo-workload.md).

- [x] **R-01 — Backlog dan urutan dependency.** Pecah PRD/FSD menjadi issue vertical slice dengan owner, acceptance, dependency, contract/data/UX/QA link, perkiraan ukuran dan risiko. **Bukti:** [BL-001](implementation-backlog.md) 88 slice/38 WO, [TR-001](requirement-traceability.md) 99 ID FR/BR/NFR/US/AC, [audit R-01](r-01-audit.md) dan `python3 scripts/validate_backlog.py` lulus. G0 bagian scope lulus; G0 penuh menunggu R-02; tujuh slice NEEDS_SPEC pada enam kelompok gap tetap terbuka.
- [x] **R-02 — Input lingkungan dan aset.** Catat tenant/entity pilot, data sintetis, volume/perangkat/konektivitas, IdP, policy yang harus diaktifkan, serta jalur perolehan source/lisensi Metronic dan sandbox provider. **Bukti:** [REG-001](r-02-dependency-register.md) memuat 25 dependency dengan owner role, target W01–W04, status, fallback, bukti penutupan dan gate. Nilai/PIC/aset riil yang belum diberikan ditandai belum tersedia. G0 tetap PARTIAL sampai input aktual dan PIC disepakati.

## 3. T1 Platform teknik — W05–12

Sumber: [ADR arsitektur](../architecture/architecture-decisions.md), [ADR Echo/Metronic](../adr/0003-echo-metronic.md), [standar repository](../engineering/repository-standards.md), [database](../engineering/database-standards.md), [function/migration](../engineering/database-functions-and-migrations.md), [backend](../engineering/backend-standards.md).

- [ ] **B-01 — Scaffold dan CI.** Lanjutkan struktur `backend/golang/`, `frontend/nextjs/`, dan `mobile/flutter/` yang sudah disiapkan: buat deployable owner, aplikasi Next.js/Flutter, infra, pin toolchain/lockfile, CODEOWNERS, format/lint/build/test pipeline. Kontrak dan migration SQL awal sudah ada; scaffold runtime dan CI belum dibuat. **Bukti:** clean checkout membangun skeleton, CI memeriksa kontrak dan tidak memerlukan secret nyata.
- [ ] **B-02 — Runtime data dan event.** Implementasikan migration runner per owner DB, versioning dan grant function PostgreSQL, metadata/audit/idempotency/outbox/inbox, JetStream relay/consumer, transaction/retry/DLQ dan backup/restore awal. **Bukti:** duplicate/out-of-order/crash/replay tidak menggandakan fakta; migration/function signature+privilege+restore diuji; function/trigger lama di-hardening lewat migration baru bila diperlukan.
- [ ] **B-03 — Gateway, keamanan dan telemetry.** Terapkan Echo v5 adapter, OIDC/workload verification, tenant/entity scope, request/trace ID, stable error, rate/body/timeout, log redaksi dan SLO dashboard. **Bukti:** authz/IDOR/CSRF boundary, 409/412/422, timeout/panic, revoke dan trace lulus test integrasi.

## 4. T2 Foundation bisnis — W13–24

Sumber: [Foundation FSD](../features/foundation-fsd.md), [policy contract](../features/mvp-policy-contract.md), [master/data](../features/mvp-data-dictionary.md), [UX MVP](../features/mvp-ux-detail.md).

- [ ] **F-01 — Organisasi dan IAM.** Implementasikan tenant/company/entity/branch/warehouse, user/membership/role/scope, OIDC session version, SoD dasar dan audit. **Bukti:** cross-entity 404/403 benar, suspend/revoke sesuai target, scope tidak dapat dipalsukan.
- [ ] **F-02 — Master data.** Implementasikan SKU/UOM/conversion, party/customer/vendor account, versioned publish/snapshot, validasi dan import awal. **Bukti:** conversion/duplicate/overlap dan reference lintas owner lulus; data master tidak mengubah histori transaksi.
- [ ] **F-03 — Kebijakan dasar.** Implementasikan approval minimal, tax/price/credit policy, numbering melalui function DB atomik, document private storage dan simulasi policy. **Bukti:** threshold, SoD, effective version, missing policy fail closed, nomor/idempotency dan scan/URL dokumen diuji.
- [ ] **F-04 — Klien dasar.** Integrasikan Metronic Next.js berizin melalui wrapper, BFF OIDC/CSRF/session/entity switcher, generated API types; buat Flutter online shell/repository dasar. **Bukti:** vendor manifest, login/logout/switch scope, cache purge, keyboard/accessibility, authz server dan smoke build web/mobile lulus. Jika aset belum tersedia, status F-04 tetap terbuka meskipun BFF selesai.

## 5. T3 MVP vertical slices — W25–52

Sumber: [FSD P2P](../features/p2p-fsd.md), [inventory/WMS](../features/inventory-wms-fsd.md), [O2C](../features/o2c-fsd.md), [finance/GL](../features/finance-gl-fsd.md), [command MVP](../features/mvp-command-matrix.md), [QA-002](../quality/mvp-contract-vectors.md).

- [ ] **M-01 — PR/PO dan approval.** Implementasikan create/submit/approve/revise PR/PO, vendor/price/tax snapshot dan UI. **Bukti:** maker/checker, ETag, duplicate command, approved line snapshot dan PO limit lulus.
- [ ] **M-02 — GRN dan stok.** Implementasikan partial receipt, lot/serial/expiry, movement ledger, balance, moving average lewat function DB atomik milik Inventory dan adjustment dasar. **Bukti:** concurrent over-receipt/negative stock tertolak; ledger=balance dan cost snapshot dapat direkonsiliasi.
- [ ] **M-03 — GRNI, vendor invoice dan AP.** Hubungkan GRN ke posting intent/journal melalui function DB Finance yang memvalidasi balance/period/source, three-way match, vendor invoice dan supplier payment. **Bukti:** 6+4 receipt, invoice/AP/GRNI seimbang, duplicate/out-of-order event tidak menggandakan AP.
- [ ] **M-04 — Price, customer credit dan SO.** Implementasikan quotation/SO submit, price/tax snapshot, exposure bucket dengan function DB credit reservation atomik, approval dan override terkontrol. **Bukti:** dua SO serentak tidak melewati limit; missing policy/FX ditolak; revision dan SoD benar.
- [ ] **M-05 — Reservation dan WMS.** Implementasikan reservation/backorder, pick/pack, serial/lot checks, dispatch dan in-transit. **Bukti:** 100 reservation race, double pick/serial, partial dispatch, stock bucket dan event gap diuji.
- [ ] **M-06 — POD dan billing source.** Implementasikan accepted/rejected POD, correction fence, source portion dan pending Finance state. **Bukti:** qty accepted saja eligible invoice; correction setelah issued ditolak; retry/gap tidak double bill.
- [ ] **M-07 — AR, payment dan GL.** Implementasikan sales invoice/journal atomik Finance melalui function DB posting yang berversi, customer receipt/allocation/reversal, period close, trial balance dan AR/AP controls. **Bukti:** journal balance, payment partial/unapplied/reversal dan close pending guard lulus.
- [ ] **M-08 — Platform completion.** Selesaikan CSV preview/commit, notification, scoped search/report/dashboard dasar dan bukti dokumentasi operator. **Bukti:** import 100 baris/3 error, replay/dedup, report watermark dan permission/export diuji.

## 6. T4 Pilot MVP — W53–60

Sumber: [QA-001](../quality/mvp-verification-plan.md), [SLO/workload](../engineering/slo-workload.md), [runbook MVP](../operations/mvp-cutover-and-runbook.md).

- [ ] **M-09 — UAT dan cutover rehearsal.** Jalankan E2E O2C/P2P/R2R, partial/failure, security/accessibility/performance/restore, data rehearsal dan reconciled opening balance. **Bukti:** laporan test, defect, metrics, signed UAT/process owner dan go/no-go pilot.
- [ ] **M-10 — Pilot dan hypercare.** Aktifkan satu entity/cohort bertahap dengan rollback/forward-fix plan; pantau 2–4 minggu dan ukur target. **Bukti:** incident/exception tertutup, zero unexplained stock/GL delta, P0/P1 nol, keputusan perluasan disetujui owner.

## 7. T5 Phase 2 Operations — W61–80

Sumber: [FSD-P2](phase-2-fsd.md), [return](../features/returns-fsd.md), [mobile sync](../features/mobile-sync-protocol.md), [DATA/UX/QA roadmap](README.md).

- [ ] **P2-01 — RFQ dan blanket PO.** Vendor invitation/bid confidentiality, comparison, award split, contract cap melalui function DB claim kapasitas dan release PO. **Bukti:** score/FX/UOM, deadline/revision dan cap race tidak membuat award/PO ganda.
- [ ] **P2-02 — Sales/purchase return.** Return source eligibility, inspection, partial, credit/debit memo, tax/cost correction dan replacement. **Bukti:** before/after invoice, closed period, serial/source dan replay reconcile stok/AR/AP/GL.
- [ ] **P2-03 — Transfer, bin, wave, count.** Partial ship/receive/discrepancy dan count delta melalui function DB atomik, bin relocation, wave lease dan opname adjustment. **Bukti:** source→transit→destination dan counted delta cocok, tidak ada double allocation atau silent balance overwrite.
- [ ] **P2-04 — Field/mobile.** Route/visit, encrypted offline order queue, delta/tombstone/cursor reset, evidence upload, push preference dan device revoke. **Bukti:** airplane/restart/duplicate/clock skew/scope revoke diuji di perangkat; sync SLO pilot diukur.
- [ ] **P2-05 — Laporan dan rollout multi branch.** Expanded operations reports, formula/watermark, data rehearsal dan aktivasi per branch. **Bukti:** laporan cocok dengan owner, transfer/return exception terkendali, G5 lulus.

## 8. T6 Phase 3 Enterprise Controls — W81–102

Sumber: [FSD-P3](phase-3-fsd.md), [CMD-RM](roadmap-command-contract.md), [QA-RM](roadmap-test-vectors.md).

- [ ] **P3-01 — Approval graph.** DAG, quorum paralel, delegation, escalation dan source revision. **Bukti:** cycle/unreachable/SoD/quorum race serta stale source diuji.
- [ ] **P3-02 — Budget dan expense.** Versioned hard budget, commitment reserve/consume/release lewat function DB budget, expense claim/reimbursement. **Bukti:** available tidak negatif, actual+commitment benar, duplicate receipt dan closed period ditangani.
- [ ] **P3-03 — Promotion.** Typed rule, stacking/exclusion, quote explanation, cap concurrency dan snapshot SO. **Bukti:** deterministic price/tax, cap race, overlap dan hadiah barang tidak membentuk diskon tersembunyi.
- [ ] **P3-04 — Bank dan FX.** Statement import/match/reconciliation dan FX rate publish, period revaluation+inverse lewat function DB Finance yang berversi. **Bukti:** duplicate bank row/payment match, close equation, stale FX dan jurnal seimbang.
- [ ] **P3-05 — Scheduler dan adapter.** Report schedule, connector registry, HMAC/replay, mapping, checkpoint dan DLQ. **Bukti:** duplicate run/webhook tidak membuat side effect kedua; provider sandbox contract test dan secret rotation lulus.
- [ ] **P3-06 — Intercompany.** Two-entity approval, paired stock/finance legs, tax/transfer price/FX, pending/exception dan elimination report. **Bukti:** qty/due-from/due-to/tax cocok sebelum CLOSED; failure saga dan replay diuji; G6 owner sign-off.

## 9. T7 Enterprise Expansion — W103–122

Sumber: [FSD-EXP](enterprise-expansion-fsd.md), [DATA-RM](roadmap-data-dictionary.md), [UX-RM](roadmap-ux.md), [QA-RM](roadmap-test-vectors.md).

- [ ] **E-01 — Discrete assembly.** BOM effective version, WO reserve/issue melalui function DB inventory/manufacturing, partial completion, WIP, scrap/variance dan costing. **Bukti:** WIP+finished goods+variance reconcile; serial/period/duplicate tidak double consume.
- [ ] **E-02 — POS online.** Register/shift, cart price/tax, stock ack, claim sale atomik lewat function DB POS, provider auth/capture, receipt, refund dan cash close. **Bukti:** provider timeout/unknown dipulihkan tanpa double capture/sale; stock/journal/receipt/refund reconcile.
- [ ] **E-03 — TMS milestone.** Plan/assignment, carrier, append-only milestone, late/duplicate event dan evidence. **Bukti:** `DELIVERED` TMS tidak mengubah WMS POD/GL; source assignment dan charge tetap terkontrol.
- [ ] **E-04 — Reporting store dan metric.** CDC/event ingestion, checkpoint/watermark/hash melalui function DB checkpoint atomik, semantic formula, tenant isolation dan drill-down. **Bukti:** gap/replay membuat STALE, official export ditahan, parity dengan owner lulus.
- [ ] **E-05 — Forecasting.** Dataset lineage, model version, horizon, quality/drift, recommendation review. **Bukti:** no auto-posting, stale data diblokir, rekomendasi dapat dijelaskan dan diaudit.
- [ ] **E-06 — Keputusan service split.** Ukur volume, failure isolation dan cadence. Jika split layak, buat ADR expand/backfill/dual-run/cutover/rollback; jika tidak, catat keputusan tidak split. **Bukti:** tidak ada dual writer, invoice/journal pending terlihat, zero unexplained delta; G7 lulus.

## 10. T8 Finalisasi — W123–128

Sumber: [OPS-RM](../operations/roadmap-rollout-and-runbook.md), [PRD Definition of Done](../enterprise-erp-prd.md#57-definition-of-done).

- [ ] **Z-01 — Hardening lintas fase.** Jalankan regression, access review, load/security/accessibility/DR, migration rehearsal, retention dan data quality. **Bukti:** semua gate runtime terdokumentasi, P0/P1 nol, stock/GL unexplained delta=0, SLO/restore tercapai.
- [ ] **Z-02 — Rollout final dan handover.** Cohort/canary per entity, on-call/runbook/dashboard, training, support ownership, vendor/license evidence dan sign-off Product/Controller/Tax/Security/Ops. **Bukti:** go/no-go final, observability, rollback/forward-fix dan penutupan hypercare diterima owner.

## 11. Format laporan AI setelah setiap paket

```text
Work order: <ID> — DONE | PARTIAL | BLOCKED
Prasyarat yang diperiksa: ...
Perubahan dan file: ...
Bukti test (perintah, hasil, fixture): ...
Kontrak/data/UX/runbook yang diperbarui: ...
Reconciliation dan dampak keamanan: ...
Keputusan manusia atau aset yang masih diperlukan: ...
Checklist yang dicentang beserta bukti: ...
Work order berikutnya yang sudah siap: ...
```

Status **DONE** hanya untuk hasil yang benar-benar diuji. Jika gate phase gagal, jangan mencentang paket penutup fase atau mengaktifkan flag produksi; revisi estimasi di [TL-001](implementation-timeline.md) dan tetap kerjakan pekerjaan lain yang independen.
