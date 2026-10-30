# Indeks kesiapan seluruh roadmap ERP

**Baseline desain:** 29 Oktober 2026. [PRD §54](../enterprise-erp-prd.md#54-product-roadmap) menjadi sumber urutan: Foundation → MVP → Phase 2 Operations → Phase 3 Enterprise Controls → Enterprise Expansion. Paket ini membatasi arti “tahap final” pada ekstensi yang disebut PRD: manufacturing/POS/TMS, analytics/forecasting, reporting store, dan pemisahan service selektif. Fitur di luar batas ini memerlukan perubahan PRD dan business case baru.

**Mulai eksekusi:** [TL-001 timeline W01–W128](implementation-timeline.md) memberi urutan fase, asumsi durasi dan gate; [WO-001 perintah AI dan checklist](ai-work-orders.md) memberi ID paket yang bisa dijalankan satu per satu; [PROMPT-001](ai-work-order-prompts.md) memberi prompt siap salin per ID; [MR-001](ai-model-routing.md) memberi rekomendasi model dan reasoning effort. Minggu bersifat relatif terhadap kickoff implementasi dan dikalibrasi dari hasil sprint nyata.

**Hasil mobilisasi:** [88 slice backlog](implementation-backlog.md), [pemetaan requirement](requirement-traceability.md), [audit G0/gap R-01](r-01-audit.md), dan [register dependency R-02](r-02-dependency-register.md). R-01/R-02 selesai sebagai dokumen; G0 penuh masih menunggu input pilot/PIC aktual. Tujuh slice memiliki NEEDS_SPEC sebelum coding, sehingga status SIAP pada baseline di bawah berlaku hanya pada bagian yang sudah memenuhi DoR.

| Tahap | FSD dan keputusan | Data/kontrak/UX/QA | Gate desain |
|---|---|---|---|
| Foundation+MVP | [FSD dan MVP completion](../features/README.md) | [DATA-003](../features/mvp-data-dictionary.md), [API](../../contracts/openapi/README.md), [event](../../contracts/events/README.md), [QA-002](../quality/mvp-contract-vectors.md) | [Planning gate](../planning-gate.md) |
| Phase 2 Operations | [FSD-P2](phase-2-fsd.md), [return](../features/returns-fsd.md), [mobile sync](../features/mobile-sync-protocol.md) | [Roadmap data](roadmap-data-dictionary.md), [command/API map](roadmap-command-contract.md), [UX](roadmap-ux.md), [QA](roadmap-test-vectors.md) | [Roadmap gate](roadmap-planning-gate.md) |
| Phase 3 Enterprise Controls | [FSD-P3](phase-3-fsd.md) | Roadmap data/command/API/UX/QA yang sama | Roadmap gate |
| Enterprise Expansion | [FSD-EXP](enterprise-expansion-fsd.md) | Roadmap data/command/API/UX/QA yang sama | Roadmap gate |

Setiap fitur memakai standar [Go/Echo](../engineering/backend-standards.md), [Next.js + shadcn-admin](../engineering/frontend-standards.md), [Flutter](../engineering/mobile-standards.md), dan [PostgreSQL](../engineering/database-standards.md). Kontrak API per owner berada di `contracts/openapi`; event producer/consumer dan contoh di `contracts/events`. Dokumen roadmap menentukan baseline perilaku sehingga implementer tidak menebak business rule. Nilai hukum/pajak/akun/kontrak vendor riil dan lisensi aset UI tetap perlu bukti sebelum aktivasi lingkungan nyata; fixture sintetis cukup untuk implementasi dan pengujian.

Urutan kerja tetap per vertical slice. “Siap direncanakan sampai final” berarti setiap tahap memiliki scope, invariant, owner, data, kontrak, layar, dan tes yang dapat diimplementasikan. Keberadaan dokumen tidak menyatakan bahwa service, UI, worker, integrasi eksternal, atau adaptasi shadcn-admin sudah tersedia.
