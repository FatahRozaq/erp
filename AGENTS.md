# Instruksi agent — Enterprise ERP

Dokumen ini berlaku untuk seluruh repository. Instruksi yang lebih spesifik berada di `backend/`, `frontend/`, dan `mobile/`, lalu di direktori stack masing-masing. File ini adalah peta bacaan dan aturan kerja; requirement lengkap tetap berada di dokumen yang ditautkan, jadi baca sumber yang relevan sebelum mengubah kode.

## Sumber kebenaran

1. [Master PRD](docs/enterprise-erp-prd.md) menetapkan tujuan, scope, proses bisnis, dan roadmap. [Keputusan bisnis MVP](docs/decisions/mvp-business-policy.md) menetapkan policy baseline; [implementation readiness](docs/implementation-readiness.md) dan [planning gate](docs/planning-gate.md) menjelaskan batas bukti.
2. [Indeks spesifikasi fitur](docs/features/README.md) menunjuk FSD, command matrix, model/data dictionary, UX, mobile sync, dan vektor QA per slice. [Indeks roadmap](docs/roadmap/README.md) menunjuk spesifikasi Phase 2, Phase 3, dan Enterprise Expansion.
3. [Timeline](docs/roadmap/implementation-timeline.md), [work order AI](docs/roadmap/ai-work-orders.md), [prompt per ID](docs/roadmap/ai-work-order-prompts.md), dan [roadmap planning gate](docs/roadmap/roadmap-planning-gate.md) menetapkan urutan, checklist, serta kriteria selesai. Kerjakan satu work order terpilih beserta dependency minimumnya; jangan mencentang `[x]` tanpa bukti.
4. [Indeks standar engineering](docs/engineering/README.md), [struktur repository](docs/engineering/repository-standards.md), dan [peta struktur seluruh modul](docs/engineering/target-module-structure.md) menetapkan batas owner, folder, kontrak, keamanan, dan lokasi modul sampai tahap final. Baca standar backend/frontend/mobile/database yang berlaku untuk file yang diubah.
5. `contracts/openapi/` dan `contracts/events/` adalah kontrak wire kanonik. [Indeks keputusan arsitektur](docs/architecture/architecture-decisions.md) dan ADR di `docs/adr/` mencatat keputusan; periksa yang terkait sebelum mengganti pola yang sudah diputuskan.

Jika sumber bertentangan atau sebuah perilaku belum dijelaskan, identifikasi letak konflik dan perbaiki dokumen/kontrak yang berwenang sebelum implementasi terkait. Jangan mengarang kebijakan bisnis dari contoh UI atau nama kolom.

**Status eksekusi:** [backlog BL-001](docs/roadmap/implementation-backlog.md), [traceability TR-001](docs/roadmap/requirement-traceability.md), dan [audit R-01](docs/roadmap/r-01-audit.md) merinci slice, dependency dan gap sebelum coding. Jangan mengartikan label desain lama SIAP sebagai kelulusan slice NEEDS_SPEC atau gate runtime.

## Alur wajib saat mengerjakan kode

- Baca work order, FSD, keputusan bisnis, kontrak, standar engineering, dan gate yang relevan; periksa keadaan repository agar tidak mengulang pekerjaan.
- Implementasikan per vertical slice dengan batas owner yang jelas. Ubah kontrak lebih dulu bila wire behavior berubah; sinkronkan handler, migration/function, klien, tes, dan dokumentasi yang terkena.
- Pertahankan `id` internal database, `guid` publik, `created_at/by`, `updated_at/by`, `deleted_at/by`, `version`, audit, dan logging sesuai [standar database](docs/engineering/database-standards.md). Gunakan migration SQL berversi dan function DB untuk invariant atomik sesuai [standar migration/function](docs/engineering/database-functions-and-migrations.md). Jangan edit migration yang pernah dijalankan.
- Jalankan bukti yang relevan: format/lint/build, kontrak, PostgreSQL migration/function/integration, unit, UI/mobile, security/scope, duplicate/retry/concurrency, dan reconciliation. Laporkan perintah dan hasil yang benar-benar dijalankan; pekerjaan yang belum terbukti tetap terbuka.
- Jaga secret dan data produksi keluar dari repository serta log. Authorization, tenant/legal entity scope, audit, dan redaksi log adalah tanggung jawab server; UI hanya menampilkan affordance.

## Direktori stack

Implementasi aktif berada di `backend/golang/` (Go + Echo v5), `frontend/nextjs/` (Metronic Next.js), dan `mobile/flutter/` (Flutter). `contracts/` dan `docs/` tetap bersama sebagai sumber lintas stack. Alternatif teknologi kelak memakai direktori saudara baru dan ADR/standar stack tersendiri; penambahan direktori tidak mengubah requirement maupun pilihan implementasi aktif.

Postman CLI tersedia untuk pekerjaan API bila diperlukan; OpenAPI di repository tetap sumber kontrak.
