# MR-001 — Rekomendasi model untuk setiap work order ERP

**Baseline:** 29 Oktober 2026. Gunakan bersama [WO-001](ai-work-orders.md), [TL-001](implementation-timeline.md), [PROMPT-001](ai-work-order-prompts.md), dan [AGENTS.md](../../AGENTS.md). Dokumen ini hanya memilih **model utama dan reasoning effort** untuk pekerjaan AI; tidak mengubah urutan, scope, acceptance, gate, atau keputusan owner. Model yang dapat dipilih bergantung pada akun, client, dan rollout.

## Cara membaca pilihan model

| Singkatan | Pilihan di Codex | Kegunaan |
|---|---|---|
| **Astra** | `gpt-6-astra` | Keputusan lintas owner, keamanan, migration/ledger, concurrency, rekonsiliasi, dan gate berisiko tinggi. |
| **Sol** | `gpt-6.1-sol` **jika tersedia**; jika belum, `gpt-6-sol` | Implementasi lintas file/stack dengan FSD dan acceptance yang sudah jelas. |
| **Luna** | `gpt-6-luna` | Subtask kecil dan terukur: ekstraksi requirement, perbaikan format/link, boilerplate sempit, atau ringkasan bukti. Tidak dijadikan model utama untuk satu work order ERP penuh. |

**Medium** adalah titik awal untuk penalaran dan coding multi-langkah; **High** dipakai saat perlu menjaga beberapa invariant, dependency, atau failure path. Pecah work order menjadi slice kecil sebelum menaikkan ke `xhigh`/`max`; gunakan level itu hanya bila hasil evaluasi menunjukkan manfaat yang nyata. Ini mengikuti [panduan pemilihan model OpenAI](https://developers.openai.com/api/docs/guides/model-selection), [model untuk Codex](https://learn.chatgpt.com/docs/models?surface=web), dan [panduan reasoning effort](https://developers.openai.com/api/docs/guides/deployment-checklist). Pada work order yang menyentuh data/uang/akses, model lain dapat membantu subtask, tetapi hasil akhir tetap diuji dan direview terhadap kontrak yang sama.

## T0 — Mobilisasi

| ID | Model utama | Reasoning | Alasan utama |
|---|---|---|---|
| R-01 — Backlog dan dependency | Astra | Medium | Menelusuri PRD/FSD/kontrak lintas seluruh roadmap dan menyusun jalur kritis. |
| R-02 — Lingkungan dan aset | Sol | Medium | Menyusun register dependency, owner, fallback, dan status berdasarkan input nyata. |

## T1 — Platform teknik

| ID | Model utama | Reasoning | Alasan utama |
|---|---|---|---|
| B-01 — Scaffold dan CI | Sol | Medium | Integrasi tiga stack, toolchain, build, lint, dan kontrak dengan acceptance konkret. |
| B-02 — Runtime data dan event | Astra | High | Migration/function/grant, idempotency, outbox/inbox, replay, dan restore harus konsisten. |
| B-03 — Gateway dan keamanan | Astra | High | OIDC, scope, IDOR, error, rate limit, dan telemetry lintas boundary. |

## T2 — Foundation bisnis

| ID | Model utama | Reasoning | Alasan utama |
|---|---|---|---|
| F-01 — Organisasi dan IAM | Astra | High | Tenant/entity isolation, role/scope, revoke, dan SoD adalah fondasi keamanan. |
| F-02 — Master data | Sol | High | SKU/UOM/party, versioned publish, import, dan referensi lintas owner. |
| F-03 — Kebijakan dasar | Astra | High | Approval, tax/price/credit, numbering atomik, dokumen privat, fail closed. |
| F-04 — Klien dasar | Sol | High | BFF/session/CSRF, wrapper shadcn-admin, generated types, dan Flutter online shell. |

## T3 — MVP vertical slices

| ID | Model utama | Reasoning | Alasan utama |
|---|---|---|---|
| M-01 — PR/PO dan approval | Sol | High | Dokumen/revisi/approval dan snapshot dengan kontrak yang sudah dirinci. |
| M-02 — GRN dan stok | Astra | High | Receipt parsial, ledger, costing, stok negatif, dan function DB concurrent. |
| M-03 — GRNI dan AP | Astra | High | Three-way match serta keseimbangan AP/GRNI/journal pada replay event. |
| M-04 — Harga, kredit, SO | Astra | High | Price snapshot, reservasi exposure atomik, race dua order, dan override. |
| M-05 — Reservation dan WMS | Astra | High | Allocation/pick/serial/lot, race stok, dan event gap. |
| M-06 — POD dan billing source | Astra | High | Source portion, koreksi, urutan POD→invoice, dan pencegahan double bill. |
| M-07 — AR, payment, GL | Astra | High | Posting/journal atomik, reversal, period close, dan rekonsiliasi. |
| M-08 — Platform completion | Sol | Medium | Import, notifikasi, search, dashboard, dan report scoped dengan tes jelas. |

## T4 — Pilot MVP

| ID | Model utama | Reasoning | Alasan utama |
|---|---|---|---|
| M-09 — UAT/cutover rehearsal | Astra | High | Sintesis bukti E2E, security, restore, opening balance, dan defect kritis. |
| M-10 — Pilot/hypercare | Sol | High | Runbook, metrik, insiden, exception, dan laporan cohort; keputusan go/no-go tetap milik owner. |

## T5 — Phase 2 Operations

| ID | Model utama | Reasoning | Alasan utama |
|---|---|---|---|
| P2-01 — RFQ/blanket PO | Sol | High | Bid confidentiality, FX/UOM, award split, dan cap kontrak concurrent. |
| P2-02 — Sales/purchase return | Astra | High | Koreksi stok/tax/cost/AR/AP/GL sebelum dan sesudah invoice. |
| P2-03 — Transfer/bin/wave/count | Astra | High | Partial transit, movement berpasangan, wave lease, dan count delta atomik. |
| P2-04 — Field/mobile | Astra | High | Offline outbox, cursor/tombstone, konflik, revoke, dan recovery perangkat. |
| P2-05 — Laporan/multi-branch | Sol | Medium | Formula/watermark, rehearsal data, serta rollout dan exception per branch. |

## T6 — Phase 3 Enterprise Controls

| ID | Model utama | Reasoning | Alasan utama |
|---|---|---|---|
| P3-01 — Approval graph | Astra | High | DAG/quorum/SoD/delegation dan race revision. |
| P3-02 — Budget/expense | Astra | High | Commitment/actual, function DB, reimbursement, dan closed period. |
| P3-03 — Promotion | Sol | High | Rule deterministik, stacking, cap concurrent, dan price snapshot. |
| P3-04 — Bank/FX | Astra | High | Duplicate match, close equation, revaluation/inverse, dan jurnal. |
| P3-05 — Scheduler/adapter | Sol | High | Signature/replay, mapping, checkpoint, DLQ, dan sandbox contract test. |
| P3-06 — Intercompany | Astra | High | Dua entity, stock/finance legs, tax/FX, saga failure, dan elimination. |

## T7 — Enterprise Expansion

| ID | Model utama | Reasoning | Alasan utama |
|---|---|---|---|
| E-01 — Discrete assembly | Astra | High | BOM/WIP/serial, material issue, variance, dan costing/journal. |
| E-02 — POS online | Astra | High | Provider timeout, stock/payment ack, receipt, refund, dan one-capture invariant. |
| E-03 — TMS milestone | Sol | High | Event late/duplicate, evidence, dan batas TMS versus WMS POD. |
| E-04 — Reporting store | Astra | High | CDC/event gap, checkpoint, watermark/hash, scope, dan parity owner. |
| E-05 — Forecasting | Sol | High | Lineage, kualitas/drift, recommendation review, dan larangan auto-posting. |
| E-06 — Service split decision | Astra | High | ADR, ownership, dual-run, cutover/rollback, dan zero unexplained delta. |

## T8 — Finalisasi

| ID | Model utama | Reasoning | Alasan utama |
|---|---|---|---|
| Z-01 — Hardening lintas fase | Astra | High | Regression, keamanan, DR, migration, retensi, SLO, dan rekonsiliasi. |
| Z-02 — Rollout/handover final | Astra | High | Menilai kelengkapan bukti lintas fase dan kesiapan operasi; sign-off tetap milik owner. |

## Aturan penggunaan saat memberi perintah AI

1. Pilih ID work order pada [WO-001](ai-work-orders.md), lalu pilih model/effort dari tabel ini. Jangan meminta satu model mengerjakan seluruh roadmap sekaligus.
2. Untuk work order besar, berikan satu vertical slice atau acceptance cluster per giliran. Model utama boleh memakai Luna untuk subtask mekanis, tetapi keputusan bisnis, security, dan correctness tetap diuji serta ditinjau pada level work order.
3. Jika pilihan model yang tercantum tidak tersedia di pemilih akun, gunakan model terdekat yang tersedia dan catat perubahan pada laporan kerja. Jangan menganggap perbedaan model sebagai alasan melompati tes, gate, atau persetujuan owner.
4. Evaluasi ulang pemetaan ini ketika model/paket akun berubah atau bila bukti dari beberapa work order menunjukkan model lain menghasilkan kualitas yang sama dengan biaya/waktu lebih rendah.
