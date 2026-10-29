# BL-001 — Backlog vertical slice seluruh roadmap

**Baseline R-01, 29 Oktober 2026.** R-01 menghasilkan backlog dan bukti audit; seluruh slice aplikasi masih belum diimplementasikan. Gunakan [work order](ai-work-orders.md), [traceability](requirement-traceability.md), dan [audit/gate/dependency](r-01-audit.md). ID `F-01.1` berarti slice work order F-01; berbeda dari fitur F-01 pada PRD §17.

## Cara mengeksekusi dan membaca sumber

Pilih satu work order yang prerequisite-nya lulus, lalu satu slice. Setiap slice bisnis mencakup command/query owner, migration schema/function/grant, API/event, web Next.js, Flutter bila kanalnya relevan, serta tes dan operasional. Owner di bawah adalah role penanggung jawab delivery bersama reviewer domain; penunjukan orang aktual masuk R-02, bukan dianggap sudah terjadi. Domain yang dipisah dengan `/` berkolaborasi tanpa SQL lintas owner. Web/Mobile dan QA mendampingi semua slice bisnis.

Setiap blok work order memberikan **profil sumber yang diwarisi semua slice**: FSD, kontrak HTTP/event, data, UX dan QA. Field acceptance menyebut kasus, tabel/aggregate/layar atau vektor spesifik untuk mempersempit bacaan; semua requirement ID merujuk [PRD](../enterprise-erp-prd.md). R-01/R-02 dan gate adalah pekerjaan delivery/operasional: API/data/UX merupakan objek audit, bukan endpoint baru. B-01/B-02 adalah enabler teknis dengan demonstrasi alur utuh.

**Urutan Foundation dan integrasi:** F-01/F-02/F-03 membangun feature UI pada skeleton B-01 dan menguji domain/API dengan identity sintetis. F-04 menyelesaikan BFF/login/entity-switch/Metronic dan demonstrasi klien terintegrasi sebelum G2; kelulusan feature test awal bukan bukti login end-to-end. Boundary yang implementasinya berada di paket berikut diuji dengan kontrak/fixture terlebih dulu, lalu wajib diuji dengan owner nyata pada slice integrasi yang disebut (M-05.1 untuk release, M-07.1 untuk invoice/correction).

**Ukuran relatif:** S=2–3, M=4–6, L=7–10 person-days gabungan implementasi/review/tes. Ini estimasi awal, bukan durasi AI atau komitmen kalender. L harus dipecah lagi bila tidak muat satu sprint squad; item NEEDS_SPEC perlu re-estimasi setelah detailnya ditutup. Waiting time lisensi/provider/UAT dan hypercare 2–4 minggu tidak termasuk effort. E-06.2 bersyarat dan harus diestimasi ulang bila split dipilih.

**Status:** DONE pada R-01/R-02 hanya membuktikan backlog dan register dependency selesai; READY berarti dapat dimulai sekarang; PLANNED menunggu dependency/gate; NEEDS_SPEC mempunyai gap wajib ditutup sebelum kode slice itu. Ketiadaan GAP bukan klaim semua detail runtime tersedia. Semua slice tetap memeriksa Definition of Ready PRD §56 sebelum coding.

**Acceptance bersama untuk semua slice kode:** authn/authz/scope dan SoD; ETag/idempotency; metadata `id/guid/created_at/by/updated_at/by/deleted_at/by/version` sesuai kelas mutable atau append-only; audit/log teredaksi; function atomik dan grant privilege minimum; retry/crash/replay/concurrency; UI loading/empty/error/pending/keyboard; migrasi upgrade/forward-fix/restore; kontrak dan runbook tersinkron. Untuk ledger/finance: source unik dan rekonsiliasi. Bukti ini ditambahkan pada acceptance spesifik, bukan digantikan olehnya.

**Dependency:** ID di kolom prasyarat harus DONE; dependency transitif ikut berlaku. Baseline ini sengaja serial di dalam paket agar aman bagi satu operator AI. Cabang antar-paket boleh paralel setelah prerequisite dan reviewer tersedia. Gate G0–G8 serta external prerequisites pada audit tetap wajib meski dependency graph sudah lulus.

## R-01

**Owner delivery:** PM/Architect. **Reviewer acceptance:** Product + domain leads.

**Sumber:** [FSD/aturan](../../docs/enterprise-erp-prd.md); Kontrak [platform](../../contracts/openapi/platform/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/engineering/repository-standards.md); [UX/operator](../../docs/roadmap/implementation-timeline.md); [QA](../../docs/roadmap/roadmap-planning-gate.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **R-01.1 — Audit baseline dan sumber** | NFR-MAIN-01 | — | S / DONE | Inventaris dokumen, kontrak, SQL dan absence runtime; setiap gap mempunyai ID dan owner di audit R-01. **Risiko:** Dokumen mengklaim runtime. |
| **R-01.2 — Backlog, dependency dan traceability** | NFR-MAIN-01 | R-01.1 | M / DONE | Semua ID PRD dan 38 WO terpetakan; setiap slice punya acceptance dan sumber; graph acyclic; G0 scope dinilai. **Risiko:** Requirement terlewat. |

## R-02

**Owner delivery:** PM/SRE. **Reviewer acceptance:** Product + Security.

**Sumber:** [FSD/aturan](../../docs/operations/mvp-cutover-and-runbook.md); Kontrak [platform](../../contracts/openapi/platform/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/engineering/slo-workload.md); [UX/operator](../../docs/features/mvp-ux-screen-map.md); [QA](../../docs/quality/mvp-verification-plan.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **R-02.1 — Register lingkungan dan kapasitas** | NFR-SCALE-01, NFR-UX-01 | R-01.2 | S / DONE | Catat tenant/entity, baseline KPI, volume, perangkat, jaringan, staffing dan owner bernama atau belum ditunjuk; status dan target/fallback eksplisit. Bukti: [REG-001 ENV-01–11](r-02-dependency-register.md#r-021--lingkungan-data-workload-dan-kpi). **Risiko:** Input pilot belum diberikan. |
| **R-02.2 — Register aset, provider dan policy** | FR-INT-01, FR-TAX-01 | R-02.1 | S / DONE | Metronic/IdP/provider/COA/tax/credit punya jalur perolehan, responsible role, target dan fallback; tidak menganggap register sebagai aset tersedia. Bukti: [REG-001 EXT-01–14](r-02-dependency-register.md#r-022--idp-policy-aset-metronic-dan-provider). **Risiko:** Lisensi dan credential belum tersedia. |

## B-01

**Owner delivery:** Platform/SRE. **Reviewer acceptance:** Architect + Web/Mobile leads.

**Sumber:** [FSD/aturan](../../docs/engineering/repository-standards.md); Kontrak [platform](../../contracts/openapi/platform/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/engineering/database-functions-and-migrations.md); [UX/operator](../../docs/engineering/target-module-structure.md); [QA](../../docs/quality/mvp-verification-plan.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **B-01.1 — Clean bootstrap tiga stack** | NFR-MAIN-01 | R-02.2 | L / PLANNED | Developer menjalankan skeleton Echo, Next.js dan Flutter di folder stack; lockfile dan README reproducible, source vendor hanya bila berizin. **Risiko:** Toolchain dan vendor template. |
| **B-01.2 — CI dan kontrak di clean workspace** | NFR-MAIN-01, NFR-INT-01 | B-01.1 | M / PLANNED | Build/lint/format/contract/examples dan generated clients drift diuji; CODEOWNERS role dipetakan ke reviewer aktual saat tersedia; CI tanpa secret riil. **Risiko:** Generated client drift. |

## B-02

**Owner delivery:** Platform/SRE. **Reviewer acceptance:** DBA + domain leads.

**Sumber:** [FSD/aturan](../../docs/engineering/backend-standards.md); Kontrak [platform](../../contracts/openapi/platform/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/engineering/database-functions-and-migrations.md); [UX/operator](../../docs/operations/mvp-cutover-and-runbook.md); [QA](../../docs/quality/mvp-verification-plan.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **B-02.1 — Migration/function dan metadata per owner** | NFR-DATA-01, FR-AUD-01 | B-01.2 | L / PLANNED | Runner checksum mengapply 11 SQL awal dan migration tambahan; empat DB, id/guid/audit/version, grant/function negative test dan upgrade/restore terbukti. **Risiko:** SQL awal belum runtime. |
| **B-02.2 — Commit sampai event diterima sekali secara bisnis** | FR-INT-01, NFR-REL-01 | B-02.1 | L / PLANNED | Command fixture commit+outbox; relay JetStream+inbox duplicate/gap/replay tidak mengganda fakta; operator melihat DLQ dan dapat replay berizin. **Risiko:** Crash, gap, poison event. |
| **B-02.3 — Backup dan pemulihan awal** | NFR-REC-01 | B-02.2 | M / PLANNED | SRE restore fixture dengan checksum, operation registry dan source uniqueness tetap utuh; waktu dan kehilangan data diukur, bukan klaim RPO produksi. **Risiko:** Backup belum dapat dipulihkan. |

## B-03

**Owner delivery:** Platform/Security. **Reviewer acceptance:** Security + SRE.

**Sumber:** [FSD/aturan](../../docs/features/foundation-fsd.md); Kontrak [platform](../../contracts/openapi/platform/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/mvp-ux-detail.md); [QA](../../docs/quality/mvp-verification-plan.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **B-03.1 — Request scoped dan error aman** | FR-IAM-01, BR-IAM-01, NFR-SEC-01 | B-02.3 | L / PLANNED | Echo memeriksa OIDC issuer/audience/key rotation, workload/user boundary dan scope; 401/403/404/409/412/422 serta timeout/body/rate limit teruji. **Risiko:** IDOR dan workload impersonation. |
| **B-03.2 — Trace dan audit dapat ditelusuri operator** | FR-AUD-01, NFR-AUD-01, NFR-OBS-01, NFR-PERF-01 | B-03.1 | M / PLANNED | Request fixture ditelusuri ke worker/outbox; request/correlation ID, redaksi, panic, dashboard lag/error dan alert/runbook diuji. **Risiko:** PII log atau trace hilang. |

## F-01

**Owner delivery:** Platform. **Reviewer acceptance:** Security + Org process owner.

**Sumber:** [FSD/aturan](../../docs/features/foundation-fsd.md); Kontrak [platform](../../contracts/openapi/platform/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/mvp-ux-screen-map.md); [QA](../../docs/quality/mvp-contract-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **F-01.1 — Admin mengaktifkan organisasi scoped** | FR-ORG-01, FR-ORG-02, BR-IAM-01 | B-03.2 | L / NEEDS_SPEC | Org node/assignment effective; cycle/overlap/entity mismatch ditolak; semua region/area/dimensi PRD dipetakan ke data/API/UX sebelum handler; histori as-was terjaga. **Risiko:** Hierarki PRD lebih luas dari detail FSD. **Gap:** GAP-01. |
| **F-01.2 — Admin memberi akses dan mencabut sesi** | FR-IAM-01, FR-IAM-02, BR-IAM-01, BR-IAM-02, AC-IAM-01, AC-IAM-02 | F-01.1 | L / PLANNED | Invite/grant/revoke + layar IAM; E-A tidak membuka E-B; self grant ditolak, session_version/suspend memutus akses maksimal 60 detik. **Risiko:** Self escalation. |

## F-02

**Owner delivery:** Platform. **Reviewer acceptance:** Master Data owner + Commercial.

**Sumber:** [FSD/aturan](../../docs/features/first-slice-fsd.md); Kontrak [master](../../contracts/openapi/master/v1.yaml), [platform](../../contracts/openapi/platform/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/mvp-ux-detail.md); [QA](../../docs/quality/mvp-contract-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **F-02.1 — Master owner publish SKU dan conversion** | FR-MDM-01, BR-MDM-01, AC-MDM-01 | F-01.2 | L / PLANNED | SKU/UOM publish dan history di web; import CSV master awal memakai command+external ID dedup sesuai IMP-001 (pipeline lengkap di M-08.1); 2 carton=24 pcs; base UOM tidak berubah setelah movement; duplicate/overlap ditolak. **Risiko:** Snapshot UOM berubah. |
| **F-02.2 — Master owner publish customer dan vendor** | FR-MDM-02, FR-MDM-03 | F-02.1 | L / NEEDS_SPEC | Party/account/address/alias dan proposal bank; mask, checker, blocked account dan merge diuji; histori snapshot tetap; atribut PRD yang belum wire-complete diselesaikan lebih dulu. **Risiko:** Bank/tax bocor atau account silang. **Gap:** GAP-02. |
| **F-02.3 — Lengkapi atribut product dan employee reference MVP** | FR-MDM-01, FR-IAM-01 | F-02.2 | M / NEEDS_SPEC | Category/brand/principal/barcode/attribute/basic variant dan employee GUID reference punya FSD/data/API/UX/QA eksplisit; barcode duplicate ditolak; variant matrix kompleks tetap deferred PRD53. **Risiko:** Requirement tersamar sebagai generic master. **Gap:** GAP-02. |

## F-03

**Owner delivery:** Platform/Finance. **Reviewer acceptance:** Controller + Tax + Security.

**Sumber:** [FSD/aturan](../../docs/features/mvp-policy-contract.md); Kontrak [workflows](../../contracts/openapi/workflows/v1.yaml), [accounting](../../contracts/openapi/accounting/v1.yaml), [sales](../../contracts/openapi/sales/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/mvp-ux-detail.md); [QA](../../docs/quality/mvp-contract-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **F-03.1 — Process owner simulate dan publish approval minimal** | FR-APP-01, BR-IAM-02, BR-APP-01, AC-APP-01, US-07 | F-02.3 | L / PLANNED | Policy version/approval instance+inbox; batas 10 juta dan 100 juta sesuai policy; maker ditolak, source revision membatalkan approval lama. **Risiko:** Threshold ambigu. |
| **F-03.2 — Tax, price dan credit policy aktif bertanggal** | FR-TAX-01, FR-PRC-01, FR-CRD-01, BR-PRC-01, BR-TIM-01 | F-03.1 | L / PLANNED | Simulate/publish tax termasuk withholding dan rounding, price precedence, credit; overlap/missing policy fail closed; fixture synthetic saja sebelum owner aktivasi. **Risiko:** Fallback policy diam-diam. |
| **F-03.3 — Nomor final dan dokumen privat** | FR-NUM-01, FR-DOC-01, FR-AUD-01 | F-03.2 | L / PLANNED | Function numbering concurrent menghasilkan satu nomor per operation; attachment version/checksum/quarantine/scan+download scoped; PENDING_SCAN tidak sah untuk POD. **Risiko:** Nomor ganda atau evidence belum clean. |
| **F-03.4 — Controller menyiapkan COA dan periode** | FR-ACC-01, BR-ACC-01, BR-TIM-01 | F-03.3 | L / PLANNED | COA/posting_rules/fiscal_period UI+API+DB; account code permanen, SERIALIZABLE overlap guard, simulasi posting dan open fixture; mapping kosong tidak autoaktif. **Risiko:** Period overlap dan mapping kosong. |

## F-04

**Owner delivery:** Web/Mobile. **Reviewer acceptance:** Security + UX.

**Sumber:** [FSD/aturan](../../docs/adr/0003-echo-metronic.md); Kontrak [platform](../../contracts/openapi/platform/v1.yaml), [master](../../contracts/openapi/master/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/mvp-ux-screen-map.md); [QA](../../docs/quality/mvp-verification-plan.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **F-04.1 — User login dan memilih entity di web** | FR-IAM-01, NFR-ACC-01 | F-01.2 | L / PLANNED | Next.js BFF OIDC/PKCE/session/CSRF, switch/logout purge; wrapper Metronic dengan vendor manifest resmi; keyboard/focus/loading/error teruji. **Risiko:** CSRF dan cache lintas scope. |
| **F-04.2 — User mobile online dan locale foundation** | NFR-I18N-01, NFR-ACC-01, FR-IAM-01 | F-04.1 | L / PLANNED | Flutter secure storage+repository+online read shell; logout/revoke, generated types dan build; fondasi ID/EN, date/timezone/currency di kedua klien. **Risiko:** Token storage dan decimal locale. |

## M-01

**Owner delivery:** Commercial. **Reviewer acceptance:** Procurement + Platform.

**Sumber:** [FSD/aturan](../../docs/features/p2p-fsd.md); Kontrak [requisition](../../contracts/openapi/requisition/v1.yaml), [purchase](../../contracts/openapi/purchase/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/mvp-ux-detail.md); [QA](../../docs/quality/mvp-contract-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **M-01.1 — Requester PR sampai PO draft** | FR-PUR-01, BR-IAM-02 | F-03.4, F-04.2 | L / PLANNED | UI PR create/submit/approve/convert; maker-checker dan stale ETag; total PO source tidak melampaui approved PR; cancellation diaudit. **Risiko:** PR portions terpakai dua kali. |
| **M-01.2 — Buyer submit/approve/revise PO** | FR-PUR-01, BR-APP-01, BR-PUR-01 | M-01.1 | L / PLANNED | PO snapshot/UOM/tax/number+event approved; duplicate sekali; amend setelah 6 receipt tidak turun di bawah 6; retired lines dan limit ack diuji. **Risiko:** Receipt limit lama. |

## M-02

**Owner delivery:** Operations. **Reviewer acceptance:** Warehouse + Controller.

**Sumber:** [FSD/aturan](../../docs/features/first-slice-fsd.md); Kontrak [inventory](../../contracts/openapi/inventory/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/web-screen-contract.md); [QA](../../docs/quality/mvp-contract-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **M-02.1 — Receiver post partial GRN dan valuation** | FR-PUR-02, FR-INV-01, BR-PUR-01, BR-INV-01, AC-PUR-02, AC-INV-02, US-04 | M-01.2 | L / PLANNED | PO10 receipt6+4 menghasilkan stok10 dan cost snapshot; +1 ditolak, out-of-order approved event tidak membuka limit stale; ledger=balance. **Risiko:** Concurrent over-receipt. |
| **M-02.2 — Receiver lot/serial dan inspector adjustment** | FR-INV-03, FR-INV-02, BR-INV-02, US-09 | M-02.1 | L / PLANNED | GRN lot/serial/expiry, hold/damaged dan adjustment berizin+history; negative sellable dan double serial ditolak; reverse append-only dan reason/approver dapat dibuka. **Risiko:** Expired stock atau reversal menghapus fakta. |

## M-03

**Owner delivery:** Finance. **Reviewer acceptance:** Controller + Procurement.

**Sumber:** [FSD/aturan](../../docs/features/p2p-fsd.md); Kontrak [finance](../../contracts/openapi/finance/v1.yaml), [accounting](../../contracts/openapi/accounting/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/mvp-ux-detail.md); [QA](../../docs/quality/mvp-contract-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **M-03.1 — Controller menerima GRNI dari stock event** | FR-ACC-01, BR-ACC-01, AC-ACC-01, US-06 | M-02.2 | L / PLANNED | Posting intent/function journal menerima GRN6+4: inventory/GRNI1000; duplicate/out-of-order source satu jurnal; missing period/mapping pending terlihat. **Risiko:** Journal ganda atau partial commit. |
| **M-03.2 — AP match dan issue vendor invoice** | FR-PUR-02, FR-FIN-01, BR-FIN-01, US-05 | M-03.1 | L / PLANNED | GRN6 invoice10 MATCH_EXCEPTION tanpa AP; setelah GRN4 issue net1000+tax110=AP1110; harga105 ditolak; match+AP/journal sekali. **Risiko:** Invoice sebelum receipt. |
| **M-03.3 — Treasury membayar supplier parsial** | FR-FIN-01, FR-PUR-02, AC-FIN-01 | M-03.2 | L / PLANNED | Checker approve payment600 atas AP1110 menyisakan510; retry bank ref satu jurnal; UI open item/unapplied dan reversal supplier bertaut. **Risiko:** Payee salah atau allocation race. |

## M-04

**Owner delivery:** Commercial. **Reviewer acceptance:** Sales + Credit Controller.

**Sumber:** [FSD/aturan](../../docs/features/o2c-fsd.md); Kontrak [sales](../../contracts/openapi/sales/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/mvp-ux-detail.md); [QA](../../docs/quality/mvp-contract-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **M-04.1 — Sales quotation/repeat sampai draft SO** | FR-SAL-01, FR-PRC-01, US-01 | F-03.4, F-04.2, M-02.2 | L / NEEDS_SPEC | Kontrak quotation conversion/expiry dan repeat order didefinisikan sebelum implementasi; SO2 carton=24 pcs, quote baru tidak menyalin nomor atau snapshot harga lama. **Risiko:** Quotation tidak punya lifecycle lengkap. **Gap:** GAP-03. |
| **M-04.2 — Sales submit, credit hold dan approval** | FR-CRD-01, FR-SAL-01, BR-CRD-01, AC-SAL-01, AC-SAL-02, US-02 | M-04.1 | L / PLANNED | Dua SO700 limit1000 hanya satu commitment; duplicate submit satu nomor; override single use/expiry/checker, missing FX/price fail closed. **Risiko:** Dua order menghabiskan limit sama. |
| **M-04.3 — Sales revise/cancel dengan release ack** | FR-SAL-01, BR-APP-01, BR-CRD-01 | M-04.2 | L / PLANNED | SO revision menunggu pending release; cancel source belum shipped; snapshots lama immutable, UI pending/exception dan retry aman. Uji kontrak release dengan fixture owner di sini; E2E release aktual wajib pada M-05.1 sebelum G3. **Risiko:** Credit dilepas sebelum owner commit. |

## M-05

**Owner delivery:** Operations. **Reviewer acceptance:** Warehouse + Commercial.

**Sumber:** [FSD/aturan](../../docs/features/inventory-wms-fsd.md); Kontrak [operations](../../contracts/openapi/operations/v1.yaml), [inventory](../../contracts/openapi/inventory/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/mvp-ux-detail.md); [QA](../../docs/quality/mvp-contract-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **M-05.1 — Allocator reserve, release dan expiry** | FR-INV-02, BR-INV-02, AC-INV-01 | M-04.3 | L / PLANNED | 100 request pada stok10 held tidak lebih10; FEFO dan backorder; expiry/cancel menghasilkan satu release, consumed tidak dilepas; buktikan E2E release/ack dari revision/cancel M-04.3. **Risiko:** Expiry/cancel race. |
| **M-05.2 — Picker scan, pack dan dispatcher ship** | FR-WMS-01, BR-WMS-01, AC-WMS-01, US-03 | M-05.1 | L / PLANNED | Task lease satu picker; picked≤allocated, serial satu pack; dispatch partial menunggu credit recheck dan stock consume ack; stock pindah in-transit tanpa revenue. **Risiko:** Double serial, credit berubah. |

## M-06

**Owner delivery:** Operations/Finance. **Reviewer acceptance:** Delivery owner + Controller.

**Sumber:** [FSD/aturan](../../docs/features/mvp-completion-contract.md); Kontrak [operations](../../contracts/openapi/operations/v1.yaml), [finance](../../contracts/openapi/finance/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/mvp-ux-detail.md); [QA](../../docs/quality/mvp-contract-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **M-06.1 — Driver POD accepted/rejected dengan evidence** | FR-WMS-01, FR-DOC-01, BR-SAL-01 | M-05.2, M-03.3 | L / PLANNED | Delivery5 POD3 accepted+1 rejected+1 transit menyimpan portions/cost; UI pending Finance; scan/checksum gagal menahan POD, duplicate tidak double source. **Risiko:** Evidence gagal tetapi revenue diakui. |
| **M-06.2 — Operator mengoreksi POD sebelum invoice** | BR-SAL-01, FR-SAL-02, NFR-REL-01 | M-06.1 | L / PLANNED | Finance correction claim dan invoice mengunci source sama; unknown tidak auto-expire; event koreksi menutup claim; sesudah issue hanya jalur return. **Risiko:** Invoice race dengan correction. |

## M-07

**Owner delivery:** Finance. **Reviewer acceptance:** Controller + Credit Controller.

**Sumber:** [FSD/aturan](../../docs/features/finance-gl-fsd.md); Kontrak [finance](../../contracts/openapi/finance/v1.yaml), [accounting](../../contracts/openapi/accounting/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/mvp-ux-detail.md); [QA](../../docs/quality/mvp-contract-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **M-07.1 — Finance issue AR dan tax evidence** | FR-SAL-02, FR-FIN-01, FR-TAX-01, BR-ACC-01 | M-06.2 | L / PLANNED | POD3 @200 tax11%: AR666 dan COGS330 sekali; uji invoice issue race dengan correction claim M-06.2; tax document manual status/evidence/history tercatat; missing tax/period meninggalkan pending. **Risiko:** Invoice/journal tidak atomik. |
| **M-07.2 — Cashier receipt, unapplied dan reversal** | FR-FIN-01, BR-FIN-01, BR-CRD-01, AC-FIN-01 | M-07.1 | L / PLANNED | Receipt400 atas AR666 sisa266; ApplyUnapplied journal reclass; reverse memakai Credit reversal_hold sampai ack, bukan TTL; retry/overallocate ditolak. **Risiko:** Reversal membuka credit sementara. |
| **M-07.3 — Controller manual journal, close/reopen dan GL** | FR-ACC-01, FR-ACC-02, BR-ACC-01, AC-ACC-01, US-06 | M-07.2 | L / PLANNED | Draft/checker/post/reversal, trial balance/P&L/aging drilldown; stale attestation/pending POD menolak close; debit=credit dan AR/AP controls reconcile. **Risiko:** Close dengan source belum final. |

## M-08

**Owner delivery:** Platform. **Reviewer acceptance:** Domain owners + UX.

**Sumber:** [FSD/aturan](../../docs/features/platform-workflows-fsd.md); Kontrak [workflows](../../contracts/openapi/workflows/v1.yaml), [platform](../../contracts/openapi/platform/v1.yaml), [accounting](../../contracts/openapi/accounting/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-data-dictionary.md); [UX/operator](../../docs/features/mvp-ux-screen-map.md); [QA](../../docs/quality/mvp-contract-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **M-08.1 — Operator CSV preview/commit/opening** | FR-IMP-01, AC-IMP-01 | M-07.3 | L / PLANNED | 100 row/3 error menjadi97 valid; file changed409; row external ID dedup; opening stock/AR/AP/COA via owner dengan reconcile dan audit. **Risiko:** Partial batch ganda. |
| **M-08.2 — User notification, audit lookup dan search** | FR-NOT-01, FR-SRH-01, FR-AUD-01, US-07 | M-08.1 | L / PLANNED | In-app/email event dedup; approval/low-stock/overdue/credit inbox; searchable redacted audit; entity filter sebelum pagination dan revoke melarang read. **Risiko:** Search/filter scope bocor. |
| **M-08.3 — Executive dashboard dan export scoped** | FR-RPT-01, NFR-PERF-02, US-10 | M-08.2 | L / PLANNED | Role dashboard stock valuation/aging/TB/P&L; as-of/watermark dan CSV/XLSX/PDF export async+download auth; stale/expired/PII/formula injection diuji. **Risiko:** Report disajikan realtime palsu. |

## M-09

**Owner delivery:** QA/SRE. **Reviewer acceptance:** Product + Controller + Security.

**Sumber:** [FSD/aturan](../../docs/operations/mvp-cutover-and-runbook.md); Kontrak [finance](../../contracts/openapi/finance/v1.yaml), [operations](../../contracts/openapi/operations/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-import-templates.md); [UX/operator](../../docs/features/mvp-ux-detail.md); [QA](../../docs/quality/mvp-verification-plan.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **M-09.1 — QA membuktikan alur dan NFR pilot** | NFR-PERF-01, NFR-SCALE-01, NFR-SEC-01, NFR-ACC-01, NFR-UX-01, NFR-REL-01, NFR-OBS-01 | M-08.3 | L / PLANNED | E2E O2C/P2P/R2R, fault/concurrency, accessibility/security/load; p95 dan scope tests sesuai QA-001; laporan actual/expected, defect dan UAT manusia. **Risiko:** Fixture tidak mewakili pilot. |
| **M-09.2 — SRE rehearsal data, restore dan cutover** | NFR-REC-01, NFR-DATA-01 | M-09.1 | L / PLANNED | Import masked/synthetic sesuai lingkungan; stock/GL zero unexplained delta, RPO≤15min/RTO≤4h diukur, rehearsal rollback dan go/no-go owner tersimpan. **Risiko:** Opening balance salah. |

## M-10

**Owner delivery:** SRE/Product. **Reviewer acceptance:** Sponsor + Controller + Ops.

**Sumber:** [FSD/aturan](../../docs/operations/mvp-cutover-and-runbook.md); Kontrak [platform](../../contracts/openapi/platform/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/features/mvp-import-templates.md); [UX/operator](../../docs/features/mvp-ux-screen-map.md); [QA](../../docs/quality/mvp-verification-plan.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **M-10.1 — Ops pilot cohort satu entity** | NFR-AVAIL-01, NFR-OBS-01 | M-09.2 | L / PLANNED | Setelah G3, M-09 dan go/no-go pilot yang berlaku, cohort/flag/rollback+alert berjalan; catat evidence aktivasi, insiden dan reconciliation per hari. **Risiko:** Cutover tanpa sign-off. |
| **M-10.2 — Product hypercare dan exit pilot** | NFR-AVAIL-01, NFR-DATA-01, NFR-UX-01 | M-10.1 | M / PLANNED | 2–4 minggu nyata, P0/P1 nol, KPI dan delta stock/GL, keputusan perluasan owner; ukuran M adalah effort, bukan mengganti waktu observasi. **Risiko:** Waktu observasi dipercepat fiktif. |

## P2-01

**Owner delivery:** Commercial. **Reviewer acceptance:** Procurement + Finance.

**Sumber:** [FSD/aturan](../../docs/roadmap/phase-2-fsd.md); Kontrak [purchase](../../contracts/openapi/purchase/v1.yaml), [requisition](../../contracts/openapi/requisition/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **P2-01.1 — Buyer RFQ dan comparison/award** | FR-PUR-01, AC-RFQ-01 | M-10.2 | L / PLANNED | QA-RM P2-01/02/03: quote2 carton=24pcs, bid vendor lain tersembunyi, award7+6 terhadap PR10 tidak melebihi10; satu PO per award. **Risiko:** Bid confidentiality dan cap race. |
| **P2-01.2 — Buyer release blanket contract** | FR-PUR-01, AC-RFQ-01, BR-PUR-01 | P2-01.1 | L / PLANNED | QA-RM P2-04: cap100, release60+40 lalu1 ditolak; cancel hanya sisa belum consumed; function lock qty/value dan expiry terlihat. **Risiko:** Release capacity ganda. |

## P2-02

**Owner delivery:** Commercial/Operations/Finance. **Reviewer acceptance:** Sales Ops + Tax + Controller.

**Sumber:** [FSD/aturan](../../docs/features/returns-fsd.md); Kontrak [returns](../../contracts/openapi/returns/v1.yaml), [purchase](../../contracts/openapi/purchase/v1.yaml), [finance](../../contracts/openapi/finance/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **P2-02.1 — Sales return inspection hingga memo/refund** | FR-SAL-02, FR-FIN-01, BR-SAL-01, AC-RET-01, AC-RET-02 | M-10.2 | L / PLANNED | QA-RM P2-05/07: return3 dari10 sebelum invoice membatasi7; setelah invoice memo666/cost330 sekali; refund/offset/replacement SO tertaut. **Risiko:** Invoice vs return race. |
| **P2-02.2 — Buyer return vendor sampai debit memo** | FR-PUR-02, FR-FIN-01, BR-FIN-01 | P2-02.1 | L / PLANNED | QA-RM P2-06: return3 @100 memberi debit net300 tax33; pre-invoice GRNI dan post-invoice AP, serial/cumulative source, closed-period correction diuji. **Risiko:** AP/tax/stock beda source. |

## P2-03

**Owner delivery:** Operations. **Reviewer acceptance:** Warehouse + Controller.

**Sumber:** [FSD/aturan](../../docs/roadmap/phase-2-fsd.md); Kontrak [operations](../../contracts/openapi/operations/v1.yaml), [inventory](../../contracts/openapi/inventory/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **P2-03.1 — Warehouse transfer partial dan discrepancy** | FR-TRF-01, FR-INV-03, BR-TRF-01, AC-TRF-01 | M-10.2 | L / PLANNED | QA-RM P2-08/09: ship10 receive7+hold2+discrepancy1 sisakan transit1; race receive7+7 tidak melebihi10; cross-entity wajib intercompany. **Risiko:** Transit hilang. |
| **P2-03.2 — Picker bin relocation dan wave lease** | FR-WMS-01, BR-WMS-01, US-03 | P2-03.1 | L / PLANNED | QA-RM P2-10/11: relocate5 capacity4 ditolak; paired movements menjaga total; wave memakai reservation existing, lease dua picker satu pemenang. **Risiko:** Double allocation. |
| **P2-03.3 — Auditor blind count dan adjustment** | FR-INV-03, BR-INV-01, US-09 | P2-03.2 | L / PLANNED | QA-RM P2-12: expected10 second count9 menghasilkan adjustment−1 setelah checker; freeze watermark dan movement selama count tidak hilang. **Risiko:** Balance ditimpa hasil count. |

## P2-04

**Owner delivery:** Commercial/Mobile/Platform. **Reviewer acceptance:** Sales Ops + Security.

**Sumber:** [FSD/aturan](../../docs/features/mobile-sync-protocol.md); Kontrak [sync](../../contracts/openapi/sync/v1.yaml), [sales](../../contracts/openapi/sales/v1.yaml), [platform](../../contracts/openapi/platform/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **P2-04.1 — Sales Ops employee assignment dan target** | FR-MDM-04, FR-SAL-03 | M-10.2 | L / NEEDS_SPEC | Effective position/supervisor/department/branch/territory dan target/attribution punya schema/API/UX/QA; overlap/scope/target version teruji sebelum route memakai assignment. **Risiko:** Referensi employee belum master contract. **Gap:** GAP-04. |
| **P2-04.2 — Salesman route/visit online dan offline** | FR-SAL-03, BR-TIM-01 | P2-04.1 | L / PLANNED | Route publish/check-in/out via web/mobile dan server timestamp; assignment/window/device validated; consent GPS opsional, target dihitung event authoritative. **Risiko:** GPS dianggap authorization. |
| **P2-04.3 — Salesman offline order dan delta sync** | NFR-MOB-01, BR-MOB-01, AC-MOB-01, US-08 | P2-04.2 | L / PLANNED | QA-RM P2-13: SQLite draft+outbox atomik, delta+tombstone+cursor atomik; restart/retry satu SO; price conflict NEEDS_REVIEW, financial actions online-only. **Risiko:** Crash setelah commit kehilangan draft. |
| **P2-04.4 — Device evidence, push dan revoke** | FR-DOC-01, FR-NOT-01, NFR-SEC-01, NFR-MOB-01 | P2-04.3 | L / PLANNED | QA-RM P2-14: encrypted upload/checksum/scan, quiet hours+dedup, revoke cache lock/purge; click reauth, clock skew/cursor reset dan sync95%≤15min diuji perangkat. **Risiko:** Cache atau push bocor. |

## P2-05

**Owner delivery:** Platform/Finance. **Reviewer acceptance:** Operations + Controller + UX.

**Sumber:** [FSD/aturan](../../docs/roadmap/phase-2-fsd.md); Kontrak [workflows](../../contracts/openapi/workflows/v1.yaml), [accounting](../../contracts/openapi/accounting/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **P2-05.1 — Controller expanded statements dan reports** | FR-ACC-02, FR-RPT-01, US-10 | P2-01.2, P2-02.2, P2-03.3, P2-04.4 | L / NEEDS_SPEC | Balance sheet/cash-flow mapping berversi dan operations fill-rate/return/transfer/visit/RFQ; QA-RM P2-15 stale event visible; statement reconcile GL dan opening/closing cash. **Risiko:** Formula laporan belum detail. **Gap:** GAP-05. |
| **P2-05.2 — Operator XLSX dan locale lengkap** | FR-IMP-01, NFR-I18N-01 | P2-05.1 | L / NEEDS_SPEC | Kontrak XLSX sheet/header/type/limit dilengkapi dahulu; preview/commit tidak ganda; web/mobile ID/EN, decimal/timezone dan export roundtrip tidak mengubah nilai. **Risiko:** Parser/locale mengubah angka. **Gap:** GAP-06. |
| **P2-05.3 — Ops rehearsal dan rollout multi branch** | NFR-DATA-01, NFR-UX-01 | P2-05.2 | L / PLANNED | Semua P2 scope termasuk gap ditutup; G5 return/transfer/offline metrics, per-branch rehearsal/flag/rollback dan sign-off aktual. **Risiko:** Branch go-live sebelum sync siap. |

## P3-01

**Owner delivery:** Platform. **Reviewer acceptance:** Security + Process owner.

**Sumber:** [FSD/aturan](../../docs/roadmap/phase-3-fsd.md); Kontrak [workflows](../../contracts/openapi/workflows/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **P3-01.1 — Process owner publish approval graph** | FR-APP-01, BR-APP-01 | P2-05.3 | L / PLANNED | QA-RM P3-01: simulate cycle/unreachable/quorum, publish immutable; 2-of-3 concurrent maju sekali, old source callback diabaikan. **Risiko:** DAG impossible atau stale revision. |
| **P3-01.2 — Approver delegation dan escalation** | FR-IAM-02, FR-APP-01, BR-IAM-02 | P3-01.1 | L / PLANNED | QA-RM P3-02: maker delegator tetap denied; subset scope/expiry/revoke, due escalation dan inbox audit kedua actor tanpa mengubah prior decision. **Risiko:** Delegation bypass SoD. |

## P3-02

**Owner delivery:** Finance. **Reviewer acceptance:** Controller + Expense owner.

**Sumber:** [FSD/aturan](../../docs/roadmap/phase-3-fsd.md); Kontrak [finance](../../contracts/openapi/finance/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **P3-02.1 — Budget owner reserve/consume/release** | FR-BUD-01, BR-BUD-01, AC-BUD-01, AC-BUD-02 | P3-01.2 | L / PLANNED | QA-RM P3-03:100−commit40, actual20 mengganti20 commitment, available60; cancel20 available80; transfer budget seimbang maker/checker. **Risiko:** Budget overspend race. |
| **P3-02.2 — Employee expense sampai reimbursement** | FR-FIN-02, BR-FIN-01 | P3-02.1 | L / PLANNED | QA-RM P3-04: checksum/receipt duplicate exception, advance offset, approve/post/pay melalui Finance, closed period correction dan payment reference unik. **Risiko:** Duplicate receipt/payable. |

## P3-03

**Owner delivery:** Commercial. **Reviewer acceptance:** Sales + Tax.

**Sumber:** [FSD/aturan](../../docs/roadmap/phase-3-fsd.md); Kontrak [sales](../../contracts/openapi/sales/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **P3-03.1 — Sales simulate/publish promotion** | FR-PRC-01, FR-SAL-01, BR-PRC-01 | P3-01.2 | L / PLANNED | QA-RM P3-05: percent10 vs fixed5 exclusion hanya satu; quote explanation dan version, overlap ditolak, uang decimal bukan float. **Risiko:** Stacking/tax ambigu. |
| **P3-03.2 — SO memakai promotion cap dan gift line** | FR-PRC-01, BR-INV-01 | P3-03.1 | L / PLANNED | QA-RM P3-06: dua SO70 cap100 paling banyak satu; submit recheck cap, gift line punya cost/tax movement dan snapshot immutable. **Risiko:** Promo cap concurrent. |

## P3-04

**Owner delivery:** Finance. **Reviewer acceptance:** Controller + Treasury.

**Sumber:** [FSD/aturan](../../docs/roadmap/phase-3-fsd.md); Kontrak [finance](../../contracts/openapi/finance/v1.yaml), [accounting](../../contracts/openapi/accounting/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **P3-04.1 — Treasury statement match dan close** | FR-FIN-02, BR-FIN-01 | P3-01.2 | L / PLANNED | QA-RM P3-07/08:100+50−20=130; duplicate row dan dua match satu payment ditolak; exceptions/timing/GL/checker tercatat. **Risiko:** Suggestion membuat posting. |
| **P3-04.2 — Controller FX publish/revalue/inverse** | FR-ACC-01, FR-FIN-02, BR-ACC-01, BR-TIM-01 | P3-04.1 | L / PLANNED | QA-RM P3-09:USD100 carry1.5juta close15200 delta20000 sekali lalu inverse periode OPEN; source invoice tidak diubah, missing FX menahan close. **Risiko:** Rate stale atau jurnal ganda. |

## P3-05

**Owner delivery:** Platform/Integration. **Reviewer acceptance:** Security + Provider owner.

**Sumber:** [FSD/aturan](../../docs/roadmap/phase-3-fsd.md); Kontrak [platform](../../contracts/openapi/platform/v1.yaml), [workflows](../../contracts/openapi/workflows/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **P3-05.1 — Operator report schedule scoped** | FR-RPT-01, NFR-INT-01 | P3-01.2 | L / PLANNED | QA-RM P3-10: satu run per schedule+instant, IANA timezone, lease/retry, scope recheck saat run/download, output expiry. **Risiko:** Dua workers atau scope revoked. |
| **P3-05.2 — Integration owner connector dan recovery** | FR-INT-01, BR-INT-01 | P3-05.1 | L / PLANNED | QA-RM P3-11: HMAC/raw body/replay/rotation, allowlist/mapping/checkpoint/DLQ; duplicate satu owner command, invalid signature nol write; sandbox actual evidence saat tersedia. **Risiko:** Forged webhook dan provider mismatch. |

## P3-06

**Owner delivery:** Commercial/Operations/Finance. **Reviewer acceptance:** Controller + Tax.

**Sumber:** [FSD/aturan](../../docs/roadmap/phase-3-fsd.md); Kontrak [operations](../../contracts/openapi/operations/v1.yaml), [finance](../../contracts/openapi/finance/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **P3-06.1 — Dua entity approve/ship/receive pair** | FR-TRF-01, BR-TRF-01, BR-ACC-01 | P3-02.2, P3-03.2, P3-04.2, P3-05.2 | L / PLANNED | QA-RM P3-12:dua approval,5 unit cost100 price120, stock legs dan due-from/to600; timeout tetap pending, replay satu destination, no cross-entity SQL. **Risiko:** Saga satu sisi atau tax missing. |
| **P3-06.2 — Controller close dan elimination report** | FR-ACC-02, NFR-DATA-01 | P3-06.1 | L / PLANNED | Pair qty/tax/FX/amount reconcile sebelum CLOSED; elimination hanya report; G6 mencakup seluruh P3, mapping/Tax/Security sign-off aktual. **Risiko:** Menghapus buku entity. |

## E-01

**Owner delivery:** Operations/Finance. **Reviewer acceptance:** Manufacturing owner + Controller.

**Sumber:** [FSD/aturan](../../docs/roadmap/enterprise-expansion-fsd.md); Kontrak [manufacturing](../../contracts/openapi/manufacturing/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **E-01.1 — Planner BOM dan WO reserve/issue** | FR-INV-01, BR-INV-02 | P3-06.2 | L / PLANNED | FSD-EXP1, QA-RM EXP-01/02:effective BOM/WO, reserve lalu issue6B+3C untuk3A bernilai75; concurrent serial satu diterima. **Risiko:** Double component/serial. |
| **E-01.2 — Production partial completion dan variance** | FR-ACC-01, BR-ACC-01 | E-01.1 | L / PLANNED | Complete2A value50 menyisakan WIP25; scrap/variance rule dan journal source, missing mapping fail closed, period/reversal baru dan stock/WIP/GL reconcile. **Risiko:** WIP tidak reconcile. |

## E-02

**Owner delivery:** Commercial/Finance. **Reviewer acceptance:** Store owner + Controller.

**Sumber:** [FSD/aturan](../../docs/roadmap/enterprise-expansion-fsd.md); Kontrak [pos](../../contracts/openapi/pos/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **E-02.1 — Cashier shift dan checkout online** | FR-SAL-01, FR-FIN-01 | P3-06.2 | L / PLANNED | QA-RM EXP-03:one active shift,cart2x100 tax22 total222; stock+payment ack, timeout query provider sebelum retry; satu capture/receipt/journal. **Risiko:** Capture berhasil tetapi response hilang. |
| **E-02.2 — Cashier refund dan cash close** | FR-SAL-02, FR-FIN-02, BR-FIN-01 | E-02.1 | L / PLANNED | QA-RM EXP-04:refund100 lalu123 atas222 tidak melebihi222; return source eligible, counted/expected difference reason/checker dan journal. **Risiko:** Over-refund atau self close. |

## E-03

**Owner delivery:** Operations. **Reviewer acceptance:** Transport owner + Finance.

**Sumber:** [FSD/aturan](../../docs/roadmap/enterprise-expansion-fsd.md); Kontrak [tms](../../contracts/openapi/tms/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **E-03.1 — Dispatcher plan dan assignment** | FR-WMS-01 | P3-06.2 | M / PLANNED | FSD-EXP3: carrier/driver/stops dari dispatched GUID; revoked carrier dan duplicate assignment ditolak; tidak mengubah stok atau revenue. **Risiko:** Shipment belum dispatched. |
| **E-03.2 — Carrier milestone dan exception evidence** | FR-INT-01, BR-INT-01 | E-03.1 | L / PLANNED | QA-RM EXP-05:late/out-of-order event tetap append-only/dedup; TMS DELIVERED tanpa WMS POD tidak issue invoice; charge via PO/AP owner. **Risiko:** Delivered TMS dianggap POD. |

## E-04

**Owner delivery:** Platform/Data. **Reviewer acceptance:** Controller + Operations + Security.

**Sumber:** [FSD/aturan](../../docs/roadmap/enterprise-expansion-fsd.md); Kontrak [analytics](../../contracts/openapi/analytics/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **E-04.1 — Data operator ingest/replay reporting store** | FR-RPT-01, NFR-DATA-01 | E-01.2, E-02.2, E-03.2 | L / PLANNED | QA-RM EXP-06:checkpoint/hash/watermark function atomik, gap STALE export ditahan; replay parity Finance/Operations, reporting role tidak menulis ledger. **Risiko:** Gap dianggap data lengkap. |
| **E-04.2 — Executive semantic metrics dan drilldown** | FR-RPT-01, NFR-PERF-02, US-10 | E-04.1 | L / PLANNED | Gross/net/COGS/DSO/fill-rate/turnover/return/FX formula version, as-of/lag dan authorized drilldown; export checksum dan tenant isolation diuji. **Risiko:** Formula atau entity scope salah. |

## E-05

**Owner delivery:** Platform/Data. **Reviewer acceptance:** Sales Ops + Model reviewer.

**Sumber:** [FSD/aturan](../../docs/roadmap/enterprise-expansion-fsd.md); Kontrak [analytics](../../contracts/openapi/analytics/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **E-05.1 — Data scientist forecast reproducible** | FR-RPT-01, NFR-DATA-01 | E-04.2 | L / PLANNED | FSD-EXP4: dataset lineage/train cutoff/model version/horizon/quality/drift; stale/gap blocked, reproducible run dan retention/PII scope. **Risiko:** Data leakage/stale lineage. |
| **E-05.2 — Planner review recommendation** | FR-PUR-01, NFR-AUD-01 | E-05.1 | M / PLANNED | QA-RM EXP-07:tanpa purchase permission hanya saran terbaca; approval+normal command diperlukan; no auto-post stock/price/PO, keputusan diaudit. **Risiko:** Saran langsung membuat PO. |

## E-06

**Owner delivery:** Architect/SRE. **Reviewer acceptance:** Domain leads + Controller.

**Sumber:** [FSD/aturan](../../docs/roadmap/enterprise-expansion-fsd.md); Kontrak [accounting](../../contracts/openapi/accounting/v1.yaml), [finance](../../contracts/openapi/finance/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/operations/roadmap-rollout-and-runbook.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **E-06.1 — Architect keputusan split dari metrik** | NFR-SCALE-01, NFR-MAIN-01 | E-05.2 | M / PLANNED | FSD-EXP5: ukur throughput/failure/cadence, bandingkan biaya; ADR split atau no-split disertai evidence G7, tanpa runtime metrik tetap terbuka. **Risiko:** Split spekulatif. |
| **E-06.2 — Conditional split dan compatibility proof** | NFR-REL-01, NFR-INT-01, NFR-REC-01 | E-06.1 | L / PLANNED | Jika ADR split:backfill/dual-read/cutover/rollback satu writer, QA-RM EXP-08 pending invoice saat journal timeout; bila no-split, catat N/A beralasan dan regression boundary tetap lulus. **Risiko:** Dual writer dan partial invoice. |

## Z-01

**Owner delivery:** QA/SRE/Security. **Reviewer acceptance:** All domain leads + Controller.

**Sumber:** [FSD/aturan](../../docs/operations/roadmap-rollout-and-runbook.md); Kontrak [platform](../../contracts/openapi/platform/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/engineering/database-functions-and-migrations.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **Z-01.1 — QA hardening seluruh roadmap** | NFR-SEC-01, NFR-ACC-01, NFR-PERF-01, NFR-SCALE-01, NFR-REL-01, NFR-DATA-01 | E-06.2 | L / PLANNED | Regression semua FR/BR/AC dan gap audit, scope/accessibility/load/security, P0/P1 nol, stock/GL zero unexplained delta; evidence actual bukan checklist saja. **Risiko:** Gap desain dianggap selesai. |
| **Z-01.2 — SRE DR, retention dan operasi** | NFR-REC-01, NFR-AVAIL-01, NFR-OBS-01, NFR-AUD-01 | Z-01.1 | L / PLANNED | Migration upgrade/forward-fix/restore dan DR drill, RPO/RTO; audit retention/legal hold, redaction, alert/on-call, SLO dashboard; data quality terukur. **Risiko:** Restore atau retention merusak evidence. |

## Z-02

**Owner delivery:** Product/SRE. **Reviewer acceptance:** Sponsor + Controller + Tax + Security + Ops.

**Sumber:** [FSD/aturan](../../docs/operations/roadmap-rollout-and-runbook.md); Kontrak [platform](../../contracts/openapi/platform/v1.yaml); [event producer/consumer](../../contracts/events/README.md); [data](../../docs/roadmap/roadmap-data-dictionary.md); [UX/operator](../../docs/roadmap/roadmap-ux.md); [QA](../../docs/roadmap/roadmap-test-vectors.md).

| Slice / outcome untuk actor | Requirement PRD | Prasyarat | Size / status | Acceptance spesifik dan risiko |
|---|---|---|---|---|
| **Z-02.1 — Release owner rollout final** | NFR-DATA-01, NFR-AVAIL-01 | Z-01.2 | L / PLANNED | G8, cohort/canary per entity dengan actual owner approval, reconciliation dan rollback/forward-fix; vendor/license evidence tersimpan. **Risiko:** Go/no-go tanpa bukti. |
| **Z-02.2 — Ops menerima handover dan hypercare final** | NFR-MAIN-01, NFR-UX-01 | Z-02.1 | M / PLANNED | Runbook/dashboard/training/support ownership, sign-off Product/Controller/Tax/Security/Ops aktual, hypercare closed, residual backlog diterima owner. **Risiko:** Training/support belum diterima. |
