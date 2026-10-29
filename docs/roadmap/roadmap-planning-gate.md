# GATE-RM — Kesiapan desain seluruh roadmap sebelum coding

**Audit diperbarui setelah R-02, 29 Oktober 2026. Keputusan: baseline roadmap, backlog dan register dependency tersedia; kesiapan coding dinilai per slice.** [Audit R-01](r-01-audit.md) menemukan enam kelompok gap detail pada tujuh slice (organisasi/master/quotation/employee-target/statement/XLSX-locale). Item tersebut NEEDS_SPEC sampai FSD/kontrak/data/UX/QA dilengkapi. [Register R-02](r-02-dependency-register.md) mencatat input pilot/aset aktual yang belum tersedia. Kelengkapan artefak per fase di bawah tidak berarti seluruh requirement sudah memenuhi DoR. G0 penuh masih menunggu input aktual dan PIC; aplikasi dan bukti runtime belum ada.

## Kelengkapan per fase

| Fase | Scope dan invariant | Data, API/event, UX, QA | Status desain |
|---|---|---|---|
| Foundation+MVP | [FSD fitur](../features/README.md), [MVP-003](../features/mvp-completion-contract.md), [policy](../decisions/mvp-business-policy.md) | [DATA-003](../features/mvp-data-dictionary.md), [OpenAPI](../../contracts/openapi/README.md), [event](../../contracts/events/README.md), [UX-003](../features/mvp-ux-detail.md), [QA-002](../quality/mvp-contract-vectors.md) | BASELINE; GAP-01–03 sebelum kode terkait; rincian [gate MVP](../planning-gate.md) |
| Phase 2 Operations | [FSD-P2](phase-2-fsd.md), [return](../features/returns-fsd.md), [sync](../features/mobile-sync-protocol.md) | [DATA-RM](roadmap-data-dictionary.md), [CMD-RM](roadmap-command-contract.md), API/event, [UX-RM](roadmap-ux.md), [QA-RM](roadmap-test-vectors.md) | BASELINE; GAP-04–06 sebelum kode terkait |
| Phase 3 Enterprise Controls | [FSD-P3](phase-3-fsd.md), termasuk approval, budget, bank, FX, adapter dan intercompany | DATA-RM, CMD-RM, API/event, UX-RM, QA-RM | BASELINE; bergantung G5 dan DoR slice |
| Enterprise Expansion | [FSD-EXP](enterprise-expansion-fsd.md): discrete assembly ringan, POS online, TMS milestone, analytics/forecasting, reporting store, split opsional berbasis metrik | DATA-RM, CMD-RM, API/event, UX-RM, QA-RM | BASELINE bounded final scope; bergantung G6 dan DoR slice |

Setiap command memiliki owner, input/guard, state/efek, error domain, idempotency dan version; [OpenAPI](../../contracts/openapi/README.md) menyediakan bentuk wire, permission dan contoh. [Event contract](../../contracts/events/README.md) menetapkan envelope, payload, producer/consumer dan replay. [DATA-RM](roadmap-data-dictionary.md) memberi owner/tabel/constraint/migration order; [UX-RM](roadmap-ux.md) memberi route/screen/role/state; [QA-RM](roadmap-test-vectors.md) memberi contoh numerik, race dan failure. [ADR Echo/Metronic](../adr/0003-echo-metronic.md), [ADR migration/function](../adr/0004-versioned-database-functions.md), dan [standar engineering](../engineering/README.md) menentukan cara implementasi. [OPS-RM](../operations/roadmap-rollout-and-runbook.md) menentukan aktivasi dan pemulihan.

## Bukti pemeriksaan statis

- **API:** 16 dokumen OpenAPI 3.1.1, 258 operasi dan 585 contoh langsung lulus validator OpenAPI/schema contoh lokal; 16 spec lulus `postman spec lint --issueType=syntax --no-report-events`. Governance lint berbasis workspace belum dijalankan karena memerlukan login/konfigurasi organisasi.
- **Event:** 43 JSON Schema Draft 2020-12 dan 43 contoh lulus schema dan format check. Event final dari operasi async hanya diterbitkan pada state terminal yang ditetapkan, bukan ketika response `202` dikirim.
- **SQL subset:** 11 migration awal untuk Foundation/first slice/return pernah di-apply pada empat database owner PostgreSQL 18 lokal; tabel berikutnya sudah dirancang di DATA-003/DATA-RM dan ditulis/test saat slice dikerjakan. Audit statis ini tidak membuktikan migration yang belum dibuat.
- **Traceability:** PRD §53–56 → FSD per fase → command/API/event → data → UI/mobile → vektor uji → rollout. Implementasi harus menambah tes runtime, contract tests producer/consumer, migration/rollback, security/accessibility/performance dan UAT pada merge/release gate.

## Kondisi eksternal yang tetap harus dipenuhi saat aktivasi

1. **Metronic:** dapatkan paket Next.js resmi dan lisensi sesuai kanal distribusi/SKU yang dipilih. Catat versi, hash, komponen yang dipakai dan batas redistribusi di vendor manifest sebelum source vendor di-copy. Design system/wrapper dan kontrak layar sudah disiapkan; visual integration tidak dapat divalidasi tanpa paket tersebut.
2. **Konfigurasi nyata:** policy pajak, COA, pricing/credit/approval/budget/intercompany dan retention per legal entity harus diterbitkan oleh process owner; konfigurasi belum aktif harus fail closed.
3. **Sistem eksternal:** endpoint, kredensial, sandbox, sertifikat/signature, mapping dan SLA bank/payment/tax/carrier/marketplace/IdP disetujui owner. Adapter dapat dikodekan terhadap kontrak dan stub; aktivasi provider memerlukan contract test terhadap vendor terpilih.
4. **Produksi:** backup/restore, DR, SLO, data migration rehearsal, reconciled ledger/stock, UAT, security review, accessibility review, lisensi dan go/no-go pada [OPS-RM](../operations/roadmap-rollout-and-runbook.md) harus terbukti sebelum go-live tiap fase.

Scope final PRD menyebut kategori ekstensi, bukan produk manufaktur/POS/TMS tanpa batas. FSD-EXP menetapkan batas implementable sekarang. Perluasan di luar batas, perubahan hukum/kontrak aktual, atau pemisahan service tanpa metrik adalah perubahan produk/ADR baru. **Status planning tidak menyatakan implementasi atau go-live bebas dependensi.**
