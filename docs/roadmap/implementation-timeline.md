# TL-001 — Timeline implementasi ERP dari awal sampai rilis final

**Baseline perencanaan:** 29 Oktober 2026. **W1** adalah minggu kickoff implementasi, bukan tanggal kalender yang sudah disetujui. Cakupan mengikuti [PRD §54–57](../enterprise-erp-prd.md#54-product-roadmap) dan [gate desain seluruh roadmap](roadmap-planning-gate.md). Ini timeline **membangun, menguji, merilis, dan menstabilkan** produk; baseline desain tersedia, gap detail mengikuti audit R-01/DoR per slice, aplikasi belum dibangun. Eksekusi rinci dengan checkbox dan perintah AI ada di [WO-001](ai-work-orders.md).

## 1. Asumsi dan cara membaca waktu

- Baseline **128 minggu (~30 bulan)**: tiga squad domain (Commercial, Operations, Finance/Platform), QA/SRE/Security bersama, product/process owner aktif, sprint dua minggu, dan satu pilot legal entity. Ini **estimasi kerja internal**, bukan angka dari sumber eksternal atau komitmen tanggal. Jika hanya satu operator yang mengarahkan satu AI tanpa kapasitas review/UAT setara, durasi harus dihitung ulang.
- Rentang awal **96–160 minggu** mencerminkan ketidakpastian integrasi, kualitas data, kapasitas reviewer, kebutuhan regulasi, dan pembelian aset. Re-estimasi setelah W4, W12, setiap gate fase, serta ketika scope/vendor berubah. Jangan menjumlahkan kecepatan generasi kode AI sebagai pengganti review bisnis, pengujian, atau migrasi data.
- Sprint dua minggu adalah pilihan proyek untuk inspeksi rutin; [Scrum Guide](https://scrumguides.org/scrum-guide.html) menetapkan sprint satu bulan atau kurang dan backlog item yang bisa selesai dalam satu sprint. Setiap sprint menghasilkan increment yang bisa diuji, demonstrasi, dan backlog yang diperbarui.
- Jalur kritis: **identity/scope → master/policy → PO/GRN/stock/GRNI → SO/reservation/WMS/POD → invoice/payment/GL → pilot → fase lanjut**. Modul dalam satu fase boleh berjalan paralel hanya setelah prasyarat owner/kontrak lulus; integrasi akhir tetap diperiksa berurutan.
- Default feature flag **OFF** untuk capability baru. Pengujian internal, pilot, perluasan cohort, dan produksi mengikuti [OPS-RM](../operations/roadmap-rollout-and-runbook.md). SLO dan delivery metrics diukur, bukan diasumsikan; acuan [SRE Workbook](https://sre.google/workbook/canarying-releases/) dan [DORA metrics](https://dora.dev/guides/dora-metrics/).

## 2. Jadwal dasar dan hasil yang harus tampak

| Jendela | Fase / work order | Hasil utama | Gate akhir |
|---|---|---|---|
| W01–04 | **T0 Mobilisasi** · R-01–R-02 | Backlog vertical slice, repo ownership, environment, data sintetis, daftar aset/konfigurasi nyata | Scope pilot, kapasitas, risiko, dan dependency tercatat; source template shadcn-admin/IdP/provider punya owner dan tanggal target |
| W05–12 | **T1 Platform teknik** · B-01–B-03 | Scaffold Go/Echo, Next.js/Flutter, CI, DB migration/function tooling, outbox/inbox, gateway/OIDC, telemetry, backup awal | Build/CI, auth scope, idempotency, migration+function+restore dan failure path terbukti pada slice teknis |
| W13–24 | **T2 Foundation bisnis** · F-01–F-04 | Org/IAM, master SKU/UOM/party, policy/numbering/price/tax/document, shadcn-admin BFF shell dan mobile online dasar | User scoped dapat bekerja pada entity pilot; master/policy versioned, authz/audit dan UI keyboard/accessibility dasar lulus |
| W25–52 | **T3 MVP vertical slices** · M-01–M-08 | PR/PO→GRN→stock/GRNI/AP; SO/credit→reservation→WMS/POD→AR/payment/GL; import/report/notification dasar | O2C/P2P/R2R end-to-end dengan partial, duplicate, failure/retry dan koreksi; stock/GL unexplained delta=0 |
| W53–60 | **T4 Pilot MVP** · M-09–M-10 | UAT, data migration rehearsal, security/performance/restore, cutover satu entity, 2–4 minggu hypercare | Product/Controller/Ops/Security sign-off; KPI dan support incident; keputusan lanjut multi branch |
| W61–80 | **T5 Phase 2 Operations** · P2-01–P2-05 | RFQ/blanket, sales/purchase return, transfer/bin/wave/count, route/visit, mobile offline/push, expanded reports | Return/stock reconciliation nol unexplained; offline sync target PRD pada jaringan pilot; multi branch rollout terkontrol |
| W81–102 | **T6 Phase 3 Controls** · P3-01–P3-06 | Approval graph, budget/expense, promotion, bank reconcile/FX, scheduler/adapter, intercompany | SoD/quorum/budget/bank/FX/intercompany invariant dan contract test provider lulus; owner control sign-off |
| W103–122 | **T7 Enterprise Expansion** · E-01–E-06 | Discrete assembly, POS online, TMS milestone, reporting store, analytics/forecasting; keputusan service split berbasis metrik | WIP/stock/GL/POS provider reconcile; TMS tidak mengubah POD; reporting watermark/lineage cocok; forecast tetap rekomendasi |
| W123–128 | **T8 Finalisasi** · Z-01–Z-02 | Cross-phase regression, security/performance/DR, data quality, dokumentasi operasional, rollout final dan handover | Tidak ada P0/P1, unexplained ledger/stock delta=0, SLO/restore/UAT terbukti, owner menerima operasi final |

Jendela fase adalah **timebox perencanaan**, bukan izin menutup pekerjaan dengan checklist yang gagal. Jika gate belum lulus, capability tetap OFF dan rencana diperbarui dengan penyebab, owner, dan dampak pada milestone berikutnya. Service split pada E-06 **opsional**; keputusan “tidak perlu split” dengan bukti metrik juga memenuhi paket itu.

## 3. Gerbang yang harus dilalui sebelum fase berikutnya

### G0 — Mobilisasi ke platform teknik (akhir W04)

- [x] Backlog dipecah menurut [work order](ai-work-orders.md), owner, dependency, acceptance dan perkiraan ukuran. Bukti R-01: [BL-001](implementation-backlog.md) dan [audit](r-01-audit.md); [REG-001](r-02-dependency-register.md) mencatat PIC/kapasitas aktual yang masih perlu ditunjuk.
- [ ] Tenant/entity pilot, data sintetis, volume/perangkat/jaringan uji dan baseline KPI dicatat. [REG-001](r-02-dependency-register.md) mencatat fixture desain dan input aktual yang belum diberikan; item ini tetap terbuka sampai profil pilot dan rencana baseline KPI disepakati.
- [ ] Source resmi dan lisensi MIT shadcn-admin, IdP, policy tax/COA/credit dan provider eksternal mempunyai owner serta jalur perolehan; yang belum tersedia ditandai dependency konkret. REG-001 mencatat owner role, jalur, target relatif dan fallback; PIC aktual serta beberapa pilihan provider masih perlu ditetapkan. Commit template dipin saat F-04.
- [x] Semua perubahan scope pada baseline R-01 menautkan PRD/FSD/kontrak/data/UX/QA terkait melalui [TR-001](requirement-traceability.md) dan profil BL-001. Gap detail ditandai NEEDS_SPEC; aturan ini diperiksa ulang untuk setiap perubahan scope berikutnya.

### G1 — Platform teknik ke Foundation (akhir W12)

- [ ] CI memeriksa format/lint/build, migration per schema **termasuk function/grant PostgreSQL**, sqlc generate/drift, OpenAPI/event, dependency scan dan tes yang sudah ada.
- [ ] Echo HTTP boundary, OIDC/workload auth, tenant/entity scope, stable error, ETag/idempotency dan audit bekerja dalam uji integrasi.
- [ ] PostgreSQL owner DB, function DB berversi dengan privilege minimum, outbox/inbox/JetStream replay, backup/restore awal, tracing/log redaksi dan dashboard error/pending terbukti.
- [ ] Batas wrapper UI dan sumber shadcn-admin MIT terdokumentasi; adaptasi visual, manifest commit/hash/file dan uji aksesibilitas diselesaikan pada F-04/G2.

### G2 — Foundation ke MVP (akhir W24)

- [ ] IAM/org/master/policy/numbering/document/price/tax dasar lulus permission, SoD, version dan tenant isolation.
- [ ] Web BFF/session/CSRF/entity switcher serta mobile online dasar memakai kontrak yang sama; tidak ada direct DB/vendor demo auth.
- [ ] Process owner menyetujui policy pilot yang akan diaktifkan; fixture sintetis tetap dipakai sebelum itu.

### G3 — MVP ke pilot (akhir W52)

- [ ] PR→PO→GRN→AP→payment dan SO→reservation→pick/dispatch/POD→invoice→receipt→GL lulus E2E, termasuk partial, stale version, retry dan reversal.
- [ ] Source stock, credit, AR/AP, GRNI dan jurnal balance direkonsiliasi; unexplained delta=0.
- [ ] OpenAPI/event contract tests, migration schema/function/grant forward/rollback/restore proof, serta uji function DB pada PostgreSQL asli tersedia untuk slice yang dikodekan.

### G4 — Pilot ke Phase 2 (akhir W60)

- [ ] UAT process owner, accessibility/security/performance dan DR sesuai [QA-001](../quality/mvp-verification-plan.md) lulus; sign-off tersimpan.
- [ ] Cutover dan 2–4 minggu hypercare selesai; tidak ada P0/P1 terbuka; backlog produksi dikalibrasi dari telemetry.
- [ ] Rollout Phase 2 memiliki flag, data rehearsal dan owner per branch.

### G5 — Phase 2 ke Phase 3 (akhir W80)

- [ ] Return sales/purchase tidak double credit/debit; transfer shipped/received dan count adjustment reconcile, termasuk function cap/stock yang dipanggil pada race.
- [ ] Offline valid order mencapai target sync PRD pada pilot; revoke/cursor reset/duplicate upload diuji pada perangkat dan jaringan nyata.
- [ ] Multi branch rollout, laporan watermark dan exception queue diterima Operations/Sales/Controller.

### G6 — Phase 3 ke Expansion (akhir W102)

- [ ] Approval parallel/delegation/SoD, hard budget, expense posting, promotion cap, bank matching, FX inverse dan intercompany pair diuji race/failure melalui Go dan function DB terkait.
- [ ] Connector signature/replay, provider sandbox, scheduler dedup dan DLQ/replay lulus contract tests.
- [ ] Controller/Tax/Security dan integration owner menandatangani control/mapping aktual yang diaktifkan.

### G7 — Expansion ke rilis final (akhir W122)

- [ ] Assembly WIP/finished goods/variance dan POS capture/stock/journal/receipt/refund reconcile satu kali; function DB untuk issue/sale/checkpoint lulus tes concurrency dan privilege.
- [ ] TMS milestone tidak menggantikan WMS POD; analytics store watermark dan metric formula cocok dengan owner.
- [ ] Forecast mempunyai lineage/quality/drift dan approval manusia; tidak membuat PO/posting otomatis.
- [ ] Keputusan service split berdasarkan metrik dan ADR dicatat; jika split dilakukan, dual-run dan rollback lulus.

### G8 — Rilis dan handover final (akhir W128)

- [ ] Regression lintas fase, migration rehearsal, backup restore, DR, load/security/accessibility dan UAT akhir lulus.
- [ ] Dashboard SLO, alert, runbook, on-call, support handover, data retention dan lisensi/kontrak vendor tersedia.
- [ ] Go/no-go per legal entity terdokumentasi; rollout bertahap tanpa P0/P1 dan tanpa unexplained stock/GL delta.

## 4. Ritme pengendalian

Setiap dua minggu: pilih work order yang prerequisite-nya lulus, ukur selesai vs rencana, demo alur bisnis, audit bukti tes, dan perbarui risiko serta estimasi. Setiap akhir fase: reforecast sisa minggu berdasarkan throughput dan defect nyata. Catat **change lead time, deployment frequency, change fail rate, failed deployment recovery time, dan rework rate** sesuai definisi [DORA](https://dora.dev/guides/dora-metrics/); gunakan angka itu untuk memperbaiki alur kerja, bukan sebagai alasan melewati gate domain. Untuk rilis, gunakan cohort/canary dan pantau SLO seperti pada [SRE Workbook](https://sre.google/workbook/canarying-releases/).
