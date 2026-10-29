# Enterprise ERP — Audit Kesiapan Implementasi PRD

**Tanggal:** 29 Oktober 2026  
**Sumber:** [Master PRD](enterprise-erp-prd.md) versi 1.3.1, [keputusan baseline bisnis MVP](decisions/mvp-business-policy.md), [paket spesifikasi fitur](features/README.md), dan standar kode.  
**Hasil audit terbaru:** [R-01](roadmap/r-01-audit.md) menyelesaikan backlog dan traceability seluruh roadmap, sekaligus menemukan enam kelompok gap detail pada tujuh slice. [R-02](roadmap/r-02-dependency-register.md) mencatat input lingkungan, aset dan provider beserta status/fallback; nilai serta PIC aktual masih terbuka. [BL-001](roadmap/implementation-backlog.md) menandai NEEDS_SPEC sebelum kode terkait; label BASELINE SET di bawah tetap keputusan desain, bukan klaim semua scope siap coding. G0 penuh masih menunggu input pilot/PIC. Sebelas migration awal merupakan subset SQL; handler, UI/mobile, CI dan bukti runtime belum tersedia.

## 1. Keputusan teknis yang telah diselaraskan

| ID | Keputusan baseline | Lokasi rujukan |
|---|---|---|
| T-01 | `id BIGINT` adalah PK lokal, `guid UUIDv7` adalah identitas publik/lintas owner; GUID bukan otorisasi. | PRD §25; [database standard](engineering/database-standards.md) |
| T-02 | Entitas mutable memiliki created/updated/deleted metadata dan optimistic `version`; ledger/audit append-only punya pengecualian eksplisit. | PRD §25; database standard |
| T-03 | Dedup bisnis memakai `business_operation_guid` unik permanen pada registry/header operasi dan source portion+leg key unik untuk line; entity `version` hanya untuk concurrency. | PRD §25, §32 |
| T-04 | SO reservation final adalah saga setelah approval; stock check sebelum submit hanya indikasi; WMS menunggu konfirmasi reservation. | PRD §30–32 |
| T-05 | Invoice MVP `ISSUED` hanya jika journal posted dalam transaksi lokal Finance Core; kegagalan rollback ke draft. | PRD §26, §29 |
| T-06 | WMS MVP boleh memakai lokasi default tanpa bin; bin scan wajib bila fitur bin P2 aktif. | PRD F-06 dan §53 |
| T-07 | Mobile offline order masuk Phase 2; metrik/skenario offline bukan gate pilot MVP. | PRD OBJ-06, US-08, §53–54 |
| T-08 | Gross invoice dan credited return dihitung terpisah, sehingga retur setelah invoice tidak membatalkan validitas invoice asal. | PRD BR-SAL-01 |
| T-09 | OpenAPI/event schema kanonik di `contracts/`; browser web memakai BFF cookie session; detail ada di standar per layer. | [repository standard](engineering/repository-standards.md), [frontend standard](engineering/frontend-standards.md) |

## 2. Status keputusan dan pekerjaan turunan

`BASELINE SET` berarti keputusan desain dan contoh sudah ada. `SLICE-001 READY` adalah label historis untuk subset SKU→PO→GRN; [planning gate](planning-gate.md) sekarang menjadi keputusan keseluruhan Foundation+MVP. Label kesiapan dokumen tidak berarti aplikasi sudah dibangun atau uji end-to-end lulus. Aktivasi pada data riil tetap melalui gate approval di [keputusan bisnis MVP](decisions/mvp-business-policy.md#aturan-aktivasi-dan-bukti-penutupan).

| ID / prioritas | Gap implementasi | Artefak dan contoh bukti minimum | Owner / gate |
|---|---|---|---|
| G-01 BASELINE SET | Tenant/Company/LegalEntity/Branch/Warehouse dan CustomerAccount dipisah. | [Cardinality, ownership dan fixture](decisions/mvp-business-policy.md#g-01--tenant-company-legalentity-branch-warehouse). | Platform/DB mengimplementasikan; Sponsor mengaktifkan tenant |
| G-02 BASELINE SET | Moving weighted average per entity+SKU+ownership; COGS pada accepted delivery. | [Rumus, jurnal dan contoh return](decisions/mvp-business-policy.md#g-02--valuasi-persediaan-dan-waktu-cogs). | Inventory/Finance mengimplementasikan; Controller mengaktifkan |
| G-03 BASELINE SET | Kendali default berpindah pada POD accepted; dispatch menjadi in transit; period close memeriksa pending. | [Sequence dan cut-off](decisions/mvp-business-policy.md#g-03--kendali-barang-pendapatan-cut-off). | Operations/Finance mengimplementasikan; Controller mengaktifkan |
| G-04 BASELINE SET | Baseline Indonesia PPN rule versioned, 5+ contoh, withholding dan e-Faktur reconciliation. | [Tax matrix](decisions/mvp-business-policy.md#g-04--pajak-indonesia-dan-pembulatan). | Tax/Finance mengimplementasikan; Tax Lead mengaktifkan |
| G-05 BASELINE SET | Bucket kredit mutually exclusive, deposit posted, guarantee nol default, buffer FX dan override fail-closed. | [Formula/concurrency/contoh](decisions/mvp-business-policy.md#g-05--kredit-fx-deposit-override). | Commercial mengimplementasikan; Credit Controller mengaktifkan |
| G-06 BASELINE SET | Batas approval inklusif, SoD, diskon, receipt tolerance nol dan simulasi. | [Policy matrix](decisions/mvp-business-policy.md#g-06--approval-sod-diskon-receipt). | Policy/Domain mengimplementasikan; Process Owner mengaktifkan |
| G-07 BASELINE SET | Three-way match exact untuk stok, invoice-before-receipt ditahan, landed cost dialokasi. | [P2P match dan jurnal](decisions/mvp-business-policy.md#g-07--three-way-match-vendor-invoice-dan-landed-cost). | Buyer/Finance mengimplementasikan; Controller mengaktifkan |
| G-08 BASELINE SET | Return sebelum/sesudah invoice, replacement, tax/cost reversal dan source eligibility. | [FSD return](features/returns-fsd.md), [FSD-P2](roadmap/phase-2-fsd.md), [OpenAPI return](../contracts/openapi/returns/v1.yaml), [DATA-RM](roadmap/roadmap-data-dictionary.md), dan migration awal Sales/Operations/Finance. Migration/handler tambahan dibuat saat slice Phase 2. | Sales Ops + Controller, sebelum aktivasi return |
| G-09 SLICE-001 READY | Model data, nullability, FK lokal, unique constraints, actor, precision dan migration sequence. | [Logical model](features/mvp-data-model.md) + [DDL domain](../backend/golang/services/operations/migrations/inventory/000001_receipt_stock.up.sql), [Finance GRNI](../backend/golang/services/finance/migrations/accounting/000001_grni_posting.up.sql) dan [runtime metadata](../backend/golang/services/operations/migrations/runtime/000001_runtime.up.sql) pada tiap service; migration slice berikutnya saat fiturnya dimulai. | DB/Domain Leads, sebelum persistence code tiap slice |
| G-10 SLICE-001 READY | Request/response, required/null, enum, decimal string, permission/status, idempotency, ETag/cursor dan error. | [OpenAPI Master/Purchase/Inventory](../contracts/openapi/README.md) lulus syntax lint; consumer review dan contract tests menyertai handler. | API/Domain Leads, sebelum handler/client tiap slice |
| G-11 SLICE-001 READY | Payload, owner/consumer, operation ID, compatibility, retry/DLQ dan version gap. | [Empat JSON Schema event + matriks consumer](../contracts/events/README.md); outbox/inbox tests menyertai worker. | Service Owners, sebelum async integration tiap slice |
| G-12 SLICE-001 READY | Guard, side effect, permission/error, partial qty, race dan reconciliation. | [FSD slice pertama](features/first-slice-fsd.md) + [matriks command MVP](features/mvp-command-matrix.md); transaction tests menyertai code. | Domain Leads, sebelum transaction code tiap slice |
| G-13 BASELINE SET | Delta/tombstone, reset cursor, atomic ack, conflict, revoke dan unggah bukti POD. | [Protokol sync](features/mobile-sync-protocol.md) + [OpenAPI sync](../contracts/openapi/sync/v1.yaml); storage adapter, malware scan dan device tests saat Phase 2. | Mobile/Platform, sebelum offline order P2 |
| G-14 BASELINE SET | Route/screen per role, validasi, action visibility, state async dan export. | [Kontrak layar + wireframe tekstual slice pertama](features/web-screen-contract.md); desain visual per fitur saat UI dibangun. | Product Design + Web, sebelum UI feature |
| G-15 BASELINE SET | Kelas endpoint, SLI/SLO, workload, hardware/network, error budget dan top-5 UAT. | [Workload dan SLO baseline](engineering/slo-workload.md); benchmark sungguhan sebelum perf/UAT gate. | SRE/QA/Product, sebelum perf/UAT gate |
| G-16 BASELINE SET | Region Indonesia, retensi keuangan 10 tahun, jadwal data lain, GPS MVP nonaktif, legal hold. | [Retention dan residency](decisions/mvp-business-policy.md#g-16oq-09--data-retensi-dan-lokasi-operasi-indonesia). | Security/Legal mengaktifkan jadwal produksi |

## 3. Paket spesifikasi minimum per vertical slice

Satu vertical slice memakai **baseline desain siap coding** bila semua item berikut memiliki kontrak/contoh. Migration executable, test runtime dan sign-off tenant diselesaikan sebagai bagian implementasi dan gate aktivasi slice:

1. **Business FSD:** actor, entity ownership, valid transition, guard, approval, price/tax/credit/stock math, partial/cancel/reversal, contoh numeric dan expected journal/movement.
2. **Command matrix:** command, source/destination state, permission+scope, input schema, idempotency key, expected version, transaction boundary, emitted event, audit, notification dan error code.
3. **Data design:** logical ownership, tipe/constraint/index/precision/actor/retention, reconciliation dan urutan migration; DDL executable ditulis sebelum persistence handler pada slice yang bersangkutan.
4. **Contract:** OpenAPI request/response+examples dan event schemas; daftar consumer, compatibility rule dan contract tests.
5. **UX/mobile:** daftar layar, field/validation, role action visibility, pending/empty/error states, accessibility; sync protocol bila offline.
6. **Verification:** unit property/invariant, PostgreSQL concurrency test, API auth/scope/idempotency test, E2E happy/partial/failure, logging/audit, performance budget dan UAT scenario.

### Contoh command matrix yang harus dibuat sebelum SO submit

| Command | Guard minimum | Atomic write | Hasil/failure |
|---|---|---|---|
| `SubmitSalesOrder` | DRAFT, customer aktif, line/UOM valid, price/tax snapshot, credit policy, scope, expected version | SO state+document number+operation ID+outbox+audit | WAITING_APPROVAL atau APPROVED; 409 duplicate mismatch, 412 stale, 422 rule failure |
| `ApproveSalesOrder` | Pending step, approver permission/scope, maker-checker, policy version | Approval decision+SO state+outbox+audit | APPROVED_PENDING_RESERVATION; concurrent decision tidak mengganda |
| `ReserveStock` | SO approved, qty unreserved, stock sellable dan warehouse scope | Reservation+balance+outbox+audit dalam Operations | ALLOCATABLE atau BACKORDERED; retry operation ID sama menghasilkan hasil sama |

Tabel ini **contoh struktur** untuk SO; kontrak konkret slice pertama tersedia di [FSD-001](features/first-slice-fsd.md). Angka dan rumus default mengikuti [keputusan bisnis MVP](decisions/mvp-business-policy.md); slice baru harus menyalin policy version dan contoh yang berlaku.

## 4. Urutan kerja yang memungkinkan kemajuan aman

1. Standar struktur kode/folder/database/API/logging sudah ditetapkan dalam `docs/engineering/`; scaffold dibuat per vertical slice.
2. M0 memakai baseline G-01–G-07 dan G-16 untuk auth, organization, master, CI, observability, dan command domain. Aktivasi transaksi riil memerlukan policy per legal entity yang disetujui pemilik bisnis.
3. Foundation+MVP telah memiliki [paket per capability](planning-gate.md#2-traceability-capability); mulai dari SKU/UOM→PO→GRN→stock ledger lalu implementasikan IAM/org/policy dan handler/worker sesuai dependency, dengan concurrency, contract dan reconciliation test per slice.
4. Lanjutkan SO→reservation→delivery→invoice→payment→journal memakai policy version dari baseline, [MVP-003](features/mvp-completion-contract.md), [DATA-003](features/mvp-data-dictionary.md) dan [QA-002](quality/mvp-contract-vectors.md).
5. Implementasikan Phase 2 → Phase 3 → Enterprise Expansion menurut [paket roadmap](roadmap/README.md), satu vertical slice per owner, dengan flag dan [OPS-RM](operations/roadmap-rollout-and-runbook.md). Protokol mobile, return, transfer, kontrol enterprise, dan bounded final scope sudah mempunyai desain; nilai vendor/tenant riil dipenuhi saat aktivasi.

**Aturan perubahan:** gap ditutup dengan keputusan yang memiliki owner, tanggal, contoh input/output, dampak ke PRD, API/data/event dan test. Jangan menandai gap selesai hanya karena ada kalimat umum. Jika keputusan berubah, perbarui PRD, FSD, ADR, kontrak dan migration plan dalam satu perubahan terkoordinasi.

## 5. Bukti pemeriksaan lokal dan batasnya

- Enam belas OpenAPI 3.1.1 dengan 258 operasi dan 585 contoh langsung lulus `postman spec lint --issueType=syntax --no-report-events`, validator OpenAPI dan validasi JSON Schema contoh lokal. Governance lint Postman memerlukan login workspace dan belum dijalankan.
- Sebelas migration SQL (empat runtime, empat domain slice pertama, tiga return) berhasil di-apply ulang pada empat database layanan PostgreSQL 18 lokal; kolom PO `vendor_account_guid` terverifikasi. Constraint race/receipt/period/return yang diuji sebelumnya tetap menjadi bukti subset, bukan pengganti tes transaction handler baru.
- Empat puluh tiga event JSON Schema dan 43 contoh payload lulus Draft 2020-12 serta format checker. Contract test producer/consumer, replay duplikat dan out-of-order dijalankan bersama implementasi worker.
- Belum ada handler, UI, mobile runtime, CI, benchmark, atau UAT yang dapat diuji. [Gerbang dokumen](roadmap/roadmap-planning-gate.md) menyatakan kesiapan rencana seluruh roadmap sesuai batasnya, bukan bukti aplikasi berfungsi.
