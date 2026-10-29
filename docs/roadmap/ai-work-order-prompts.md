# PROMPT-001 — Prompt siap pakai untuk seluruh work order ERP

**Status:** katalog perintah, 29 Oktober 2026. Pilih satu ID dari [WO-001](ai-work-orders.md), set model dan reasoning menurut [MR-001](ai-model-routing.md), lalu salin **hanya blok prompt** pada ID tersebut ke Codex di root repository. Prompt dibuat singkat tetapi menyebut outcome, sumber, batas, dan bukti; detail acceptance tetap milik work order, FSD, kontrak, serta [AGENTS.md](../../AGENTS.md). [Panduan prompting OpenAI](https://learn.chatgpt.com/docs/prompting) menganjurkan tujuan, konteks, batas, dan cara verifikasi yang jelas tanpa menyalin seluruh dokumen ke tiap prompt.

Setiap prompt hanya mengotorisasi pekerjaan untuk ID itu. AI harus memeriksa status aktual lebih dulu, mengerjakan dependency minimum, menguji sesuai acceptance, dan melaporkan bukti. Kotak checklist hanya boleh dicentang jika bukti paket tersebut benar-benar lulus. Aktivasi produksi, UAT/sign-off manusia, aset berlisensi, serta kredensial nyata mengikuti gate dan otorisasi terkait; prompt tidak menganggapnya sudah tersedia.

## T0 — Mobilisasi

### R-01 — Backlog dan urutan dependency

**Model:** Astra · Medium

```text
Kerjakan hanya work order R-01 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Audit dokumen dan repository; pecah PRD/FSD seluruh roadmap menjadi backlog vertical slice yang dapat ditelusuri ke requirement, owner, acceptance, dependency, kontrak, data, UX, dan QA. Tandai jalur kritis, perkiraan ukuran, serta risiko tanpa mengklaim runtime sudah ada. Periksa kelengkapan terhadap gate G0, centang R-01 hanya bila bukti backlog memenuhi kriterianya, lalu laporkan file, bukti, keputusan terbuka, dan ID berikutnya yang siap.
```

### R-02 — Input lingkungan dan aset

**Model:** Sol · Medium

```text
Kerjakan hanya work order R-02 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca PRD, gate G0, dan runbook; buat register dependency untuk tenant/entity pilot, data sintetis, volume/perangkat/jaringan, IdP, policy aktif, source/lisensi Metronic, serta sandbox provider. Isi owner, target waktu, status, dan fallback pengujian yang diketahui; tandai data yang belum diberikan sebagai belum tersedia, bukan menebak. Jangan menyalin aset berlisensi atau credential. Centang R-02 hanya jika bukti register memenuhi acceptance; laporkan input yang masih perlu owner dan pekerjaan berikutnya.
```

## T1 — Platform teknik

### B-01 — Scaffold dan CI

**Model:** Sol · Medium

```text
Kerjakan hanya work order B-01 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Audit struktur yang sudah ada, lalu scaffold deployable Go/Echo, Next.js, Flutter, infra lokal, toolchain/lockfile, CODEOWNERS, dan CI format/lint/build/test/kontrak menurut docs/engineering/. Pertahankan 11 migration SQL dan kontrak yang ada; isolasi Metronic di wrapper, tanpa menyalin vendor source bila belum berlisensi. Buktikan clean checkout dapat membangun skeleton dan CI tidak memerlukan secret nyata. Centang hanya jika bukti lulus; laporkan hasil, gap, dan ID berikutnya.
```

### B-02 — Runtime data dan event

**Model:** Astra · High

```text
Kerjakan hanya work order B-02 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Audit SQL/runtime yang ada; implementasikan migration runner per owner dengan role/grant terpisah, versioning function DB, audit/idempotency/outbox/inbox, JetStream relay-consumer, retry/DLQ, serta backup/restore awal menurut standar database dan ADR-0004. Jangan edit migration yang sudah pernah dijalankan; perubahan memakai migration baru. Uji PostgreSQL asli untuk privilege, duplicate, out-of-order, crash/replay, dan restore tanpa fakta ganda. Centang B-02 hanya setelah bukti lengkap; laporkan file, command/hasil, risiko, dan ID berikutnya.
```

### B-03 — Gateway, keamanan, dan telemetry

**Model:** Astra · High

```text
Kerjakan hanya work order B-03 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Implementasikan batas HTTP Echo v5, verifikasi OIDC/workload, tenant/entity scope, stable error, request/trace ID, rate/body/timeout limit, log ber-redaksi, dan telemetry dasar sesuai backend standards serta threat model. Uji gateway nyata untuk authz/IDOR, revoke, 401/403/404, 409/412/422, panic, timeout, dan trace propagation; jangan memakai credential produksi. Centang hanya jika acceptance dan bukti integrasi lulus; laporkan temuan, hasil, serta paket berikutnya.
```

## T2 — Foundation bisnis

### F-01 — Organisasi dan IAM

**Model:** Astra · High

```text
Kerjakan hanya work order F-01 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca Foundation FSD, policy kontrak, Platform OpenAPI, dan standar database; implementasikan tenant/company/entity/branch/warehouse, user/membership/role/scope, session version, SoD dasar, serta audit dengan migration berversi. Uji cross-entity isolation, self-escalation, suspend/revoke, dan scope yang dipalsukan melalui API nyata. Jangan aktifkan policy tenant riil tanpa owner. Centang F-01 hanya bila seluruh bukti lulus; laporkan file, tes, gap, dan ID berikutnya.
```

### F-02 — Master data

**Model:** Sol · High

```text
Kerjakan hanya work order F-02 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca first-slice FSD, DATA-003, Master/Platform OpenAPI, lalu implementasikan SKU/UOM/conversion, product, party/customer/vendor account, versioned publish/snapshot, validasi, dan import awal dalam owner Platform. Tambah migration dan tes untuk duplicate, overlap effective date, konversi, serta referensi lintas owner tanpa mengubah histori transaksi. Gunakan data sintetis. Centang F-02 hanya jika acceptance terbukti; laporkan command/hasil, file, dan ID berikutnya.
```

### F-03 — Kebijakan dasar

**Model:** Astra · High

```text
Kerjakan hanya work order F-03 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca MVP policy contract, Foundation FSD, standar migration/function, dan ADR terkait; implementasikan approval minimal, tax/price/credit policy berversi, numbering atomik lewat function DB, serta metadata dokumen dengan private storage/scan. Uji threshold, SoD, effective version, missing-policy fail closed, idempotency nomor, dan akses/URL dokumen. Konfigurasi riil tetap tidak aktif tanpa owner. Centang hanya jika bukti lulus; laporkan hasil dan pekerjaan berikutnya.
```

### F-04 — Klien dasar

**Model:** Sol · High

```text
Kerjakan hanya work order F-04 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca standar frontend/mobile, ADR Echo–Metronic, dan kontrak UI; bangun BFF Next.js dengan OIDC/session/CSRF/entity switcher, generated API types, serta Flutter online shell/repository dasar. Integrasikan Metronic hanya dari paket dan lisensi yang sah melalui wrapper dengan vendor manifest. Uji login/logout, scope switch/cache purge, keyboard/accessibility, authz server, dan build web/mobile. Bila aset vendor belum tersedia, kerjakan bagian independen dan biarkan F-04 terbuka; laporkan bukti dan gap.
```

## T3 — MVP vertical slices

### M-01 — PR/PO dan approval

**Model:** Sol · High

```text
Kerjakan hanya work order M-01 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca P2P FSD, command matrix, Requisition/Purchase OpenAPI, data dan UX; implementasikan create/submit/approve/revise PR/PO beserta UI, snapshot vendor/price/tax, migration, audit, dan event owner. Uji maker-checker, stale ETag, duplicate idempotency key, approved-line snapshot, dan batas PO melalui API/UI. Centang M-01 hanya setelah hasil normal/failure/concurrency yang relevan lulus; laporkan file, tes, rekonsiliasi, dan ID berikutnya.
```

### M-02 — GRN dan stok

**Model:** Astra · High

```text
Kerjakan hanya work order M-02 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca first-slice serta inventory/WMS FSD, DATA-003, Inventory API, dan standar function DB; implementasikan partial GRN, lot/serial/expiry, immutable movement ledger, balance, moving-average cost, dan adjustment dasar melalui function atomik owner Operations. Uji concurrent over-receipt, negative sellable, duplicate source, reversal, dan ledger=balance/cost snapshot pada PostgreSQL asli. Centang hanya jika seluruh invariant terbukti; laporkan hasil, gap, dan paket berikutnya.
```

### M-03 — GRNI, vendor invoice, dan AP

**Model:** Astra · High

```text
Kerjakan hanya work order M-03 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca P2P dan Finance/GL FSD, posting matrix, Finance/Accounting API, serta standar function DB; implementasikan GRN→posting intent/journal, three-way match, vendor invoice, AP, dan supplier payment dalam owner Finance. Uji periode, balance, source uniqueness, receipt 6+4, duplicate/out-of-order event, dan rekonsiliasi AP/GRNI/GL. Gunakan migration baru bila schema/function berubah. Centang hanya bila bukti PostgreSQL dan integrasi lulus; laporkan hasil dan ID berikutnya.
```

### M-04 — Harga, kredit, dan SO

**Model:** Astra · High

```text
Kerjakan hanya work order M-04 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca O2C FSD, policy contract, Sales API, dan aturan credit/pricing; implementasikan quotation/SO submit, price/tax snapshot, exposure bucket, reservasi credit atomik lewat function DB, approval, dan override terkontrol. Uji dua SO serentak terhadap limit, stale policy/FX, revision, SoD, idempotency, dan audit. Total final tetap server authoritative. Centang hanya bila acceptance dan race test lulus; laporkan file, command/hasil, dan ID berikutnya.
```

### M-05 — Reservation dan WMS

**Model:** Astra · High

```text
Kerjakan hanya work order M-05 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca inventory/WMS FSD, Operations/Inventory API, data model, dan test vectors; implementasikan stock reservation/backorder, pick/pack, serial/lot guard, dispatch, serta in-transit dengan migration/function owner. Uji 100 reservation race, double pick/serial, partial dispatch, stock bucket, event gap/replay, dan scope warehouse. Centang M-05 hanya jika ledger serta status fisik dapat direkonsiliasi dan tes lulus; laporkan bukti serta pekerjaan berikutnya.
```

### M-06 — POD dan billing source

**Model:** Astra · High

```text
Kerjakan hanya work order M-06 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca O2C dan Finance/GL FSD, delivery event, serta command matrix; implementasikan POD accepted/rejected, correction fence, source portion, dan pending Finance state tanpa SQL lintas owner. Uji hanya qty accepted yang eligible invoice, koreksi setelah issued tertolak, partial POD, retry/gap event, dan pencegahan double billing. Tampilkan status pending/exception di API dan UI terkait. Centang hanya setelah bukti lintas owner lulus; laporkan rekonsiliasi dan ID berikutnya.
```

### M-07 — AR, payment, dan GL

**Model:** Astra · High

```text
Kerjakan hanya work order M-07 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca Finance/GL FSD, posting matrix, Finance/Accounting OpenAPI, serta standar database/function; implementasikan sales invoice dan journal atomik Finance, AR receipt/allocation/reversal, period close, trial balance, dan controls. Uji journal balance, payment partial/unapplied/reversal, closed period, pending guard, duplicate source, dan rekonsiliasi AR/AP/GL pada PostgreSQL asli. Centang hanya jika semua bukti keuangan lulus; laporkan file, hasil, dan ID berikutnya.
```

### M-08 — Platform completion

**Model:** Sol · Medium

```text
Kerjakan hanya work order M-08 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca Platform workflows FSD, import templates, report/notification contracts, dan UX; selesaikan CSV preview/validate/commit, notification, scoped search, laporan/dashboard dasar, serta dokumentasi operator. Uji import 100 baris dengan 3 error, dedup/replay, permission filter, watermark/as-of, dan export scoped. Jangan menjadikan report sebagai sumber posting. Centang hanya bila acceptance lulus; laporkan file, command/hasil, dan paket berikutnya.
```

## T4 — Pilot MVP

### M-09 — UAT dan cutover rehearsal

**Model:** Astra · High

```text
Kerjakan hanya work order M-09 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca QA-001, runbook MVP, dan gate G3/G4; jalankan E2E O2C/P2P/R2R, partial/failure, security, accessibility, performance, restore, data rehearsal, dan rekonsiliasi opening balance pada lingkungan yang tersedia. Buat laporan defect, metrik, dan bukti go/no-go; jangan mengarang UAT atau tanda tangan process owner. Jika lingkungan/persetujuan belum ada, selesaikan rehearsal yang mungkin dan biarkan M-09 terbuka. Laporkan bukti tepat serta langkah berikutnya.
```

### M-10 — Pilot dan hypercare

**Model:** Sol · High

```text
Kerjakan hanya work order M-10 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca cutover/runbook, gate G4, serta hasil M-09; siapkan dan, hanya setelah go/no-go serta otorisasi yang berlaku, jalankan pilot satu entity/cohort dengan flag, rollback/forward-fix, observability, dan hypercare 2–4 minggu. Catat insiden, exception, metrik, stock/GL delta, serta keputusan perluasan dari owner. Jangan menandai aktivitas yang belum terjadi sebagai lulus. Centang M-10 hanya dengan bukti pilot nyata dan sign-off; laporkan status dan blocker konkret.
```

## T5 — Phase 2 Operations

### P2-01 — RFQ dan blanket PO

**Model:** Sol · High

```text
Kerjakan hanya work order P2-01 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-P2, Purchase API, DATA-RM, UX-RM, dan QA-RM; implementasikan vendor invitation, bid confidentiality, comparison/award split, blanket contract cap, serta release PO lewat function DB atomik Commercial. Uji deadline/revision, normalisasi FX/UOM, score, concurrent award/release, idempotency, dan permission vendor. Centang hanya jika cap serta kerahasiaan terbukti lewat tes; laporkan migration, API/UI, hasil, dan ID berikutnya.
```

### P2-02 — Sales dan purchase return

**Model:** Astra · High

```text
Kerjakan hanya work order P2-02 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca Return FSD, FSD-P2, Returns OpenAPI, DATA-RM, dan QA-RM; implementasikan source eligibility, inspection, partial return, credit/debit memo, tax/cost correction, serta replacement melalui owner Sales, Operations, dan Finance. Uji jalur sebelum/sesudah invoice, closed period, serial/source, race, replay, dan rekonsiliasi stok/AR/AP/GL. Jangan edit posting lama; gunakan dokumen koreksi. Centang hanya dengan bukti lintas owner lengkap; laporkan hasil dan ID berikutnya.
```

### P2-03 — Transfer, bin, wave, dan count

**Model:** Astra · High

```text
Kerjakan hanya work order P2-03 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-P2, Operations API, DATA-RM, dan QA-RM; implementasikan partial transfer ship/receive/discrepancy, bin relocation, wave lease, stock count dan adjustment melalui function DB Operations yang atomik. Uji source→transit→destination, lot/serial, over-capacity, double allocation, count watermark, concurrent claim, serta selisih yang memerlukan review. Centang hanya bila ledger dan qty/value reconcile tanpa silent overwrite; laporkan migration, tes, dan ID berikutnya.
```

### P2-04 — Field dan mobile offline

**Model:** Astra · High

```text
Kerjakan hanya work order P2-04 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-P2, SYNC-001, Sync OpenAPI, standar mobile, UX-RM, dan QA-RM; implementasikan route/visit, encrypted offline order queue, delta/tombstone/cursor reset, evidence upload, push preference, dan device revoke. Uji di perangkat/emulator: airplane mode, restart/crash, duplicate retry, clock skew, price/stock conflict, scope revoke, dan sync SLO. Server tetap authoritative untuk order/stock/credit. Centang hanya dengan bukti perangkat dan kontrak; laporkan hasil serta ID berikutnya.
```

### P2-05 — Laporan dan rollout multi branch

**Model:** Sol · Medium

```text
Kerjakan hanya work order P2-05 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-P2, UX-RM, QA-RM, serta gate G5; implementasikan expanded operations reports dengan formula version, as-of/watermark, export scoped, dan penanganan exception. Siapkan data rehearsal serta rollout per branch; aktifkan branch hanya setelah gate dan otorisasi owner. Uji parity laporan dengan source owner serta return/transfer exception. Centang hanya bila bukti runtime dan rollout yang disyaratkan tersedia; laporkan gap dan langkah berikutnya.
```

## T6 — Phase 3 Enterprise Controls

### P3-01 — Approval graph

**Model:** Astra · High

```text
Kerjakan hanya work order P3-01 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-P3, workflow contract, DATA-RM, dan QA-RM; implementasikan approval DAG, quorum paralel, delegation, escalation, dan binding source revision/policy version di owner Platform. Uji cycle, unreachable stage, impossible SoD, duplicate decision, quorum race, stale revision, dan audit actor/delegator. Perubahan policy tidak menulis ulang instance lama. Centang hanya jika invariant dan permission terbukti; laporkan hasil serta ID berikutnya.
```

### P3-02 — Budget dan expense

**Model:** Astra · High

```text
Kerjakan hanya work order P3-02 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-P3, Finance API, DATA-RM, QA-RM, dan standar function DB; implementasikan hard budget version, reserve/consume/release commitment atomik, expense claim, serta reimbursement melalui Finance. Uji available tidak negatif saat race, actual+commitment, duplicate receipt, approval/SoD, closed period, payment/journal, dan replay. Centang hanya bila saldo serta jurnal reconcile pada PostgreSQL asli; laporkan migration, hasil, dan ID berikutnya.
```

### P3-03 — Promotion

**Model:** Sol · High

```text
Kerjakan hanya work order P3-03 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-P3, Sales/price contracts, DATA-RM, UX-RM, dan QA-RM; implementasikan typed promotion rule, stacking/exclusion, deterministic quote explanation, cap concurrent, serta snapshot SO. Uji overlap/effective window, urutan prioritas, tax base, dua submit terhadap cap, hadiah barang sebagai line nyata, dan idempotency. Jangan hitung uang final dengan float klien. Centang hanya jika test vectors dan concurrency lulus; laporkan hasil serta ID berikutnya.
```

### P3-04 — Bank dan FX

**Model:** Astra · High

```text
Kerjakan hanya work order P3-04 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-P3, Finance/Accounting API, DATA-RM, QA-RM, dan posting matrix; implementasikan bank statement import/match/reconciliation, FX rate publish, period revaluation, serta inverse journal melalui function DB berversi. Uji duplicate row, dua operator match payment sama, close equation, stale/missing FX, closed period, source uniqueness, dan journal balance. Centang hanya bila ledger dan bukti PostgreSQL lulus; laporkan hasil serta ID berikutnya.
```

### P3-05 — Scheduler dan adapter

**Model:** Sol · High

```text
Kerjakan hanya work order P3-05 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-P3, connector/event contracts, threat model, dan QA-RM; implementasikan report schedule, connector registry, HMAC/signature verification, mapping version, checkpoint, retry/DLQ, dan replay berizin. Uji duplicate scheduled run/webhook, timestamp/replay window, secret rotation, timeout, serta contract test terhadap sandbox provider bila tersedia. Tanpa credential riil, gunakan stub dan catat gap aktivasi. Centang hanya jika acceptance yang berlaku terbukti; laporkan hasil serta ID berikutnya.
```

### P3-06 — Intercompany

**Model:** Astra · High

```text
Kerjakan hanya work order P3-06 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-P3, DATA-RM, CMD-RM, UX-RM, QA-RM, serta policy tax/FX; implementasikan approval dua entity, paired stock/finance legs, pending/exception saga, dan elimination report tanpa SQL transaction lintas entity. Uji partial/timeout/replay, due-to/from, tax/transfer price/FX, permission kedua entity, dan closure hanya setelah reconcile. Konfigurasi riil menunggu sign-off owner. Centang hanya jika gate G6 dan bukti invariant lulus; laporkan hasil serta ID berikutnya.
```

## T7 — Enterprise Expansion

### E-01 — Discrete assembly

**Model:** Astra · High

```text
Kerjakan hanya work order E-01 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-EXP, Manufacturing OpenAPI, DATA-RM, UX-RM, dan QA-RM; implementasikan effective BOM, WO reserve/issue, WIP, partial completion, scrap/variance, serta costing melalui owner Operations dan posting intent Finance. Gunakan function DB atomik untuk material issue/source uniqueness. Uji serial/component race, closed period, duplicate command, dan WIP+finished goods+variance reconciliation. Centang hanya bila bukti stock/journal lulus; laporkan hasil dan ID berikutnya.
```

### E-02 — POS online

**Model:** Astra · High

```text
Kerjakan hanya work order E-02 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-EXP, POS OpenAPI, DATA-RM, UX-RM, dan QA-RM; implementasikan register/shift, cart price/tax, stock ack, claim sale atomik, provider auth/capture, receipt, refund, dan cash close. Uji provider timeout/unknown, double capture/sale, stock race, shift SoD, refund source limit, serta stock/GL/receipt reconciliation. Bila sandbox/provider belum tersedia, uji stub dan catat aktivasi yang tertahan. Centang hanya bila acceptance lengkap terbukti; laporkan hasil serta ID berikutnya.
```

### E-03 — TMS milestone

**Model:** Sol · High

```text
Kerjakan hanya work order E-03 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-EXP, TMS OpenAPI/event, DATA-RM, UX-RM, dan QA-RM; implementasikan transport plan/assignment, carrier reference, append-only milestone, evidence, serta penanganan late/duplicate event. Uji source assignment, revoked carrier, out-of-order projection, dan pastikan status DELIVERED TMS tidak mengubah WMS POD, invoice eligibility, atau GL. Centang hanya jika batas ownership serta charge flow terbukti; laporkan hasil dan ID berikutnya.
```

### E-04 — Reporting store dan metric

**Model:** Astra · High

```text
Kerjakan hanya work order E-04 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-EXP, Analytics OpenAPI/event, DATA-RM, UX-RM, QA-RM, dan standar database; implementasikan dedicated reporting store read-only, event/CDC ingestion, atomic checkpoint/watermark/hash function DB, semantic metric version, dan scoped drill-down. Uji gap/replay menandai STALE dan menahan official export, tenant isolation, serta parity numerik dengan source owner. Jangan beri reporting store hak command/ledger. Centang hanya jika bukti rekonsiliasi lulus; laporkan hasil serta ID berikutnya.
```

### E-05 — Forecasting

**Model:** Sol · High

```text
Kerjakan hanya work order E-05 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca FSD-EXP, Analytics contract, DATA-RM, UX-RM, dan QA-RM; implementasikan dataset lineage, model/version, train cutoff, horizon, quality/drift metrics, serta recommendation review yang berizin. Uji input stale/gap, tenant scope, reproducibility, audit keputusan, dan pastikan tidak ada jalur auto-posting PO, stock, atau price. Centang hanya jika hasil dapat dijelaskan dan test vectors lulus; laporkan bukti dan ID berikutnya.
```

### E-06 — Keputusan service split

**Model:** Astra · High

```text
Kerjakan hanya work order E-06 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Ukur throughput, deployment cadence, ownership, serta failure isolation dari runtime; baca FSD-EXP dan standar repository. Jika split layak, tulis ADR dan implementasikan expand/backfill/dual-run/cutover/rollback dengan satu writer, pending/exception state, dan rekonsiliasi zero unexplained delta. Jika tidak layak, catat keputusan mempertahankan deployable berdasarkan metrik. Tanpa metrik nyata, jangan memutuskan secara spekulatif atau mencentang checklist. Laporkan bukti, risiko, dan gate G7.
```

## T8 — Finalisasi

### Z-01 — Hardening lintas fase

**Model:** Astra · High

```text
Kerjakan hanya work order Z-01 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca QA-RM, OPS-RM, TL-001, dan gate G8; jalankan regression lintas fase, access review, load/security/accessibility/DR, migration rehearsal, retention, data quality, serta stock/GL reconciliation. Perbaiki temuan dalam scope hardening dan ulangi bukti terkait; jangan menyebut tes yang belum dijalankan sebagai lulus. Centang hanya bila P0/P1 nol, delta tak terjelaskan nol, SLO/restore dan seluruh gate runtime terbukti. Laporkan bukti serta gap final.
```

### Z-02 — Rollout final dan handover

**Model:** Astra · High

```text
Kerjakan hanya work order Z-02 sesuai docs/roadmap/ai-work-orders.md dan AGENTS.md. Baca OPS-RM, hasil Z-01, dan gate G8; siapkan cohort/canary per entity, on-call, runbook/dashboard, training, support ownership, vendor/license evidence, serta rollback/forward-fix. Jalankan rollout hanya setelah go/no-go dan otorisasi owner yang berlaku; pantau hypercare dan catat bukti sign-off Product/Controller/Tax/Security/Ops yang benar-benar diberikan. Jangan menandatangani atas nama mereka. Centang hanya jika handover final dan gate terbukti; laporkan hasil serta item yang masih terbuka.
```
