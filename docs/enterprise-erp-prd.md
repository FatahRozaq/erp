# Enterprise ERP — Product Requirements Document

**Versi:** 1.3.2 (keputusan template frontend)
**Tanggal:** 30 Oktober 2026
**Status:** Baseline implementasi bertahap; gap detail per slice mengikuti audit R-01 dan Definition of Ready; aktivasi bisnis per tenant menunggu persetujuan owner  
**Pemilik:** Product Management bersama Finance, Sales, Purchasing, Warehouse, dan Technology  
**Domain awal:** Distribution / FMCG / Trading  
**Bahasa:** Indonesia; kode entitas, event, permission, dan API menggunakan bahasa Inggris.

> **Cara membaca:** `MUST`, `SHOULD`, `COULD`, `WON'T` adalah prioritas MoSCoW untuk *target rilis* yang tertulis. ID stabil (`FR`, `BR`, `NFR`, `AC`) menghubungkan requirement, desain, dan pengujian. Target numerik di dokumen ini merupakan asumsi awal yang harus dikonfirmasi dengan baseline volume dan kebijakan perusahaan. Dokumen ini adalah master PRD, sehingga API rinci, DDL, UI dan test case akan diturunkan darinya tanpa mengubah aturan bisnis diam-diam.

**Perubahan v1.1:** menyelaraskan `id`/`guid`, dedup operasi, invoice-journal MVP, reservasi async, bin MVP, retur setelah invoice, dan fase mobile offline. [Audit kesiapan implementasi](implementation-readiness.md) memisahkan keputusan bisnis yang masih perlu sign-off dari standar teknis yang sudah dapat ditetapkan.

**Perubahan v1.2:** G-01–G-06 mendapat [keputusan baseline bisnis MVP](decisions/mvp-business-policy.md) dengan contoh angka dan kontrol aktivasi per legal entity. Pendapatan dan COGS mengikuti perpindahan kendali yang dibuktikan POD accepted untuk profil kontrak default; dispatch memindahkan stok ke in transit. Angka policy adalah default implementasi, bukan pengesahan kebijakan perusahaan.

**Perubahan v1.3:** Seluruh tahap sampai bounded Enterprise Expansion mempunyai [paket desain](roadmap/README.md) dan [gerbang kesiapan](roadmap/roadmap-planning-gate.md). Backend HTTP memakai [Echo v5](adr/0003-echo-metronic.md); OIDC/BFF dan owner database ERP tetap menjadi sumber otoritas. Schema dan function PostgreSQL dipasang lewat [migration berversi](adr/0004-versioned-database-functions.md). Nilai vendor, pajak, COA, lisensi dan bukti runtime masih merupakan gate aktivasi.

**Perubahan v1.3.1 (R-01):** [Backlog dan audit](roadmap/r-01-audit.md) memetakan seluruh roadmap, mengungkap gap detail sebelum kode slice terkait, menyelaraskan label fase approval/delegasi/expense/bank/search dengan §54 dan work order, serta memperbaiki referensi BR yang tidak terdefinisi pada §14. Scope bisnis tetap mengacu requirement di bawah.

**Perubahan v1.3.2:** Template frontend diganti menjadi [shadcn-admin MIT](adr/0005-shadcn-admin-frontend.md) sebagai acuan UI. Source Vite diadaptasi ke Next.js yang tetap menjadi stack aktif; syarat pengadaan Metronic dihapus dari gate dan work order mendatang.

## Daftar isi

1. [Part 1 — Product & Business Requirement](#part-1--product--business-requirement)
2. [Part 2 — ERP Modules & Business Process](#part-2--erp-modules--business-process)
3. [Part 3 — Functional Requirements](#part-3--functional-requirements)
4. [Part 4 — Domain & Data Model](#part-4--domain--data-model)
5. [Part 5 — Technical Architecture](#part-5--technical-architecture)
6. [Part 6 — Security, DevOps & Observability](#part-6--security-devops--observability)
7. [Part 7 — Non Functional Requirements](#part-7--non-functional-requirements)
8. [Part 8 — MVP & Roadmap](#part-8--mvp--roadmap)

---

# Part 1 — Product & Business Requirement

## 1. Executive Summary

Enterprise ERP Platform menyatukan master data, Order to Cash (O2C), Procure to Pay (P2P), stok, keuangan, dan pelaporan lintas legal entity, cabang, dan gudang. Sasaran pertama adalah perusahaan distribusi/FMCG/trading yang memerlukan stok dapat dipercaya, kontrol kredit, dokumen terlacak, serta jurnal berpasangan. Satu sumber kebenaran dimiliki oleh setiap domain; tampilan lintas domain dibangun dari API atau proyeksi event.

Produk dibangun sebagai **modular service platform**: batas domain dan kepemilikan data jelas sejak awal, tetapi hanya beberapa deployable yang dipisahkan ketika beban, tim, atau reliabilitas menuntutnya. MVP menutup satu alur bisnis nyata sampai invoice, penerimaan pembayaran, dan jurnal; fungsi lanjutan bertahap. Tidak ada komitmen bahwa satu rilis mendukung semua tipe industri secara penuh.

## 2. Product Vision

> Setiap transaksi operasional menghasilkan status, stok, piutang/utang, dan jejak audit yang bisa ditelusuri dari dokumen sumber sampai laporan keuangan; pengguna tetap dapat bekerja aman di banyak perusahaan, cabang, dan perangkat.

Prinsip keputusan: integritas sebelum kecepatan fitur; konfigurasi untuk kebijakan bisnis, kode untuk invariant; konsistensi kuat pada transaksi stok dan jurnal lokal; integrasi lintas domain memakai kontrak, outbox, dan rekonsiliasi; akses selalu dievaluasi di server; desain sederhana sampai kebutuhan skala terukur.

## 3. Business Context

**Model bisnis target:** distributor dengan 2–20 legal entity, puluhan cabang/gudang, ribuan SKU dan customer, multi UOM, pengiriman parsial, diskon/price list, tempo pembayaran, dan akuntansi per entity. Angka ini asumsi kapasitas untuk rancangan awal, bukan batas lisensi. Retail POS, MRP/manufaktur, dan TMS tingkat lanjut memerlukan fase tersendiri.

**Value stream utama:** Supplier → Purchasing → Receiving → Inventory/Warehouse → Sales → Delivery → Customer → Collection → Finance/Accounting. Dimensi organisasi, IAM, pajak, dokumen, approval, audit, dan reporting berlaku lintas value stream.

## 4. Business Problems

| ID | Masalah teramati/hipotesis | Dampak yang ingin dihilangkan |
|---|---|---|
| BP-01 | Data item/customer/vendor tersebar dan tidak memiliki pemilik | Order salah harga, alamat, UOM, atau pajak |
| BP-02 | Stok dokumen dan stok fisik berbeda, reservasi ganda | Overselling, stockout, koreksi manual |
| BP-03 | Approval melalui pesan di luar sistem | Tidak ada bukti pembuat, penyetuju, dan alasan |
| BP-04 | Invoice, penerimaan uang, dan jurnal dibuat ulang | Duplikasi, keterlambatan closing, salah saldo |
| BP-05 | Akses data cabang/entitas tidak seragam | Kebocoran data dan kesalahan posting lintas entity |
| BP-06 | Koneksi lapangan tidak stabil | Kunjungan dan order terlambat masuk |
| BP-07 | Laporan memerlukan konsolidasi manual | Keputusan terlambat dan angka tidak cocok |

## 5. Objectives

| ID | Tujuan | Ukuran keberhasilan yang diusulkan |
|---|---|---|
| OBJ-01 | Satu master dan status transaksi yang dapat ditelusuri | ≥99,5% transaksi MVP memiliki referensi source→ledger lengkap |
| OBJ-02 | Stok operasional akurat | Selisih kuantitas hasil cycle count pada SKU aktif <0,5% setelah stabilisasi |
| OBJ-03 | Mempercepat siklus O2C dan P2P | Median waktu SO disetujui turun 30%; receipt→vendor invoice turun 25% dari baseline |
| OBJ-04 | Closing akuntansi bisa direkonsiliasi | 100% jurnal posted seimbang; nol double posting terkonfirmasi |
| OBJ-05 | Aman untuk lintas entity/cabang | Nol temuan akses lintas scope pada uji otorisasi rilis |
| OBJ-06 | Lapangan tetap produktif (Phase 2) | ≥95% order offline valid tersinkron ≤15 menit setelah koneksi stabil pada pilot mobile Phase 2 |

**Metode:** catat baseline 4–8 minggu sebelum pilot; dashboard metrik menampilkan pembilang, penyebut, interval, pemilik, dan kualitas data. Jangan menyatakan peningkatan tanpa baseline.

## 6. Success Metrics

| Metrik | Definisi operasional | Target / fase | Owner |
|---|---|---:|---|
| Order conversion | SO fulfilled / SO approved dalam cohort bulan | baseline +10% | Sales Ops |
| OTIF | Delivery tepat waktu dan lengkap / delivery jatuh tempo | ≥95% | Warehouse Ops |
| Stock accuracy | 1 − \|qty fisik − qty buku\| / max(qty fisik,1), agregat SKU-lokasi | ≥99,5% | Inventory Controller |
| Auto-journal coverage | Dokumen posting yang menghasilkan jurnal valid / dokumen posting eligible | 100% | Controller |
| AR overdue | Outstanding lewat jatuh tempo / total AR | baseline −15% | Finance |
| Approval SLA | Persentase approval selesai sebelum tenggat konfigurasi | ≥90% | Process Owner |
| API availability | Successful eligible request / total eligible request | ≥99,9% bulanan | SRE |
| Sync success | Perintah offline yang accepted / perintah offline valid yang dikirim | ≥99,5% pada pilot mobile Phase 2 | Mobile Lead |

## 7. Stakeholders

Sponsor: CEO/COO/CFO. Process owner: Sales Director, Purchasing Manager, Warehouse/Inventory Manager, Finance Controller, Tax Lead. Delivery: PM, BA, Architect, Web/Mobile/Backend, QA, DevOps/SRE, Security, Data. Governance: internal audit, legal/privacy, customer support. **RACI minimum:** Product owner menyetujui scope; process owner menyetujui aturan domain; Finance Controller menyetujui posting/reconciliation; Security menyetujui model akses; Architect menyetujui kontrak/boundary; QA mengesahkan bukti acceptance; Operations menyetujui kesiapan runbook dan DR.

## 8. Personas

| Persona | Pekerjaan utama | Kebutuhan/risiko |
|---|---|---|
| Salesman | Rute, kunjungan, order | Mobile offline, harga yang berlaku, status kredit |
| Sales Supervisor | Target, pengecualian, approval | Inbox jelas, alasan keputusan, scope wilayah |
| Buyer | PR/RFQ/PO | Perbandingan vendor, lead time, sisa pesanan |
| Warehouse Staff | Receive, putaway, pick, dispatch | Scanner, bin, batch/expiry, kontrol selisih |
| Inventory Controller | Opname, adjustment, rekonsiliasi | Movement immutable dan approval nilai tinggi |
| AR/AP Officer | Tagihan dan pembayaran | Alokasi parsial, aging, anti-duplikasi |
| Finance Controller | Posting, closing, laporan | Period lock, reversal, trail sampai sumber |
| Executive | KPI lintas entity | Definisi angka sama, drill-down sesuai scope |
| IT/Security Admin | User, konfigurasi, audit | SoD, delegasi berakhir otomatis, observability |

## 9. Product Scope

**In-scope platform:** multi legal entity/company, branch/region/area, department, cost/profit center, warehouse/stock point; IAM dan data scope; master; sales/purchase; inventory/WMS; AR/AP; GL; credit, price, approval, budget, tax, document, notification, reporting, integration; web dan mobile terpilih. Setiap transaksi memakai satu `legal_entity_guid` dan `transaction_currency`; intercompany adalah proses eksplisit.

**Pemisahan istilah:** `Company` adalah group/tenant administrasi, `LegalEntity` adalah pembuku dan subjek pajak, `Branch` adalah unit operasi, `Warehouse` adalah lokasi stok; satu warehouse berada pada tepat satu legal entity pada satu waktu. Bila pelanggan memakai istilah “company” untuk legal entity, label UI boleh disesuaikan tanpa mengubah model kanonik.

## 10. Out of Scope

| Fase awal (`WON'T` pada MVP) | Alasan |
|---|---|
| Manufacturing/MRP/BOM/work orders | Bounded context dan costing berbeda; dirancang sebagai ekspansi |
| Retail POS dan loyalty | Kebutuhan latency/offline kasir berbeda |
| Payroll dan HRIS lengkap | Hanya employee master dan assignment yang diperlukan |
| TMS route optimization dan live fleet telemetry | Mobile delivery dasar cukup dulu |
| Konsolidasi IFRS otomatis lintas entity, FX hedge | Memerlukan policy finance tersendiri |
| AI forecasting/autonomous actions | Butuh kualitas data historis dan governance |
| Integrasi WhatsApp/bank/tax spesifik vendor | Bergantung kontrak, izin, dan aturan lokal |

## 11. Assumptions

1. Satu tenant dapat memiliki banyak legal entity; transaksi finansial dan stok tidak bercampur antar legal entity tanpa dokumen intercompany.
2. Base currency ditetapkan per legal entity dan tidak berubah setelah posting; transaksi dapat memakai mata uang lain dengan kurs tersimpan/sumber kurs terekam.
3. Satu SKU memiliki **base UOM** stabil; konversi UOM menggunakan rasio rasional/decimal berversi, tidak mengubah pergerakan lama.
4. Costing MVP memakai moving weighted average per legal entity+SKU+ownership; metode khusus hanya lewat kelas valuasi terbit dan tidak mengubah histori.
5. Baseline yurisdiksi MVP adalah Indonesia dengan tax/retention policy berversi dari [keputusan bisnis MVP](decisions/mvp-business-policy.md); transaksi khusus tanpa rule aktif ditolak.
6. Negative stock dilarang untuk stok sellable di MVP; backorder diperbolehkan sebagai order demand tanpa reservasi.
7. Batas approval IDR <10 juta, 10–100 juta, >100 juta menjadi default implementasi dengan batas inklusif dan perhitungan gross setelah pajak; aktivasi nilai produksi ditandatangani process owner.
8. Data historis tersedia dalam Excel/legacy ERP dan dapat diekstrak; kualitasnya harus diprofilkan sebelum tanggal cutover diputuskan.
9. Web memakai Next.js 16.x Active LTS pada tanggal dokumen, dengan patch stable terbaru yang lolos security review; versi dipin pada lockfile dan diuji sebelum upgrade. [Kebijakan dukungan Next.js](https://nextjs.org/support-policy), [rilis Next.js 16.4](https://nextjs.org/blog/next-16-4).
10. PostgreSQL 18 menjadi baseline yang diuji; kandidat major baru tidak dipakai sebelum status stabil dan kompatibilitas terbukti. [Dokumentasi PostgreSQL](https://www.postgresql.org/docs/).

## 12. Constraints

Stack wajib: Go dengan Echo v5 pada HTTP adapter, PostgreSQL dengan SQL migration dan function DB berversi untuk invariant lokal atomik, Redis, broker, REST eksternal, Next.js/TypeScript dengan acuan UI shadcn-admin MIT, Flutter/Dart. Deploy lokal Docker Compose; production dapat menuju Kubernetes. Batas penyimpanan data pribadi, lokasi hosting, SLA, dan lisensi komponen ditetapkan saat discovery pelanggan. Tidak ada direct SQL lintas owner database. Semua posting finance dan inventory harus memiliki jejak sumber dan mekanisme reversal.

## 13. ERP Module Map dan Business Capability Map

| Capability | Modul pemilik | Fase target | Prioritas |
|---|---|---|---|
| Organize & secure | Organization, IAM, configuration, audit | MVP | MUST |
| Govern master data | Product, customer, vendor, employee reference | MVP | MUST |
| Sell & fulfill | Quotation, SO, credit check, reservation, pick/pack, delivery, invoice | MVP/Phase 2 | MUST |
| Source & receive | PR, PO, receipt, vendor invoice | MVP/Phase 2 | MUST |
| Control stock | Ledger, balances, transfer, adjustment, count, batch | MVP/Phase 2 | MUST |
| Settle & account | AR, AP, bank/cash, journal, GL, trial balance, statements | MVP/Phase 2 | MUST |
| Govern decisions | Approval, pricing, budget, tax | Minimal MVP, lengkap Phase 3 | MUST/SHOULD |
| Inform & integrate | Notification, reports, search, import/export, APIs | MVP dasar, lanjut Phase 3 | MUST/SHOULD |
| Optimize | forecasting, advanced WMS, manufacturing/POS adapter | Enterprise | COULD |

## 14. Requirement taxonomy dan traceability

`FR-xx` fitur, `BR-xx` aturan bisnis, `NFR-xx` kualitas, `AC-xx` acceptance. Satu requirement dinyatakan lengkap jika memiliki owner, prioritas, fase, kondisi diterima, serta bukti test. Matriks inti: `FR-SAL-01` → `BR-CRD-01`/`BR-INV-02` → `AC-SAL-01` → contract Sales API → E2E O2C; `FR-PUR-02` → `BR-PUR-01` → `AC-PUR-02` → P2P; `FR-ACC-01` → `BR-ACC-01` → `AC-ACC-01` → close test. ID turunan tidak boleh digunakan ulang jika aturan dihapus.

---

# Part 2 — ERP Modules & Business Process

## 15. Functional Requirements dan Detailed Module Requirements

Kolom *deliverable* adalah perilaku yang dapat diuji; setiap baris adalah major requirement. Detail flow fitur paling kritikal ada pada Part 3. `MVP` berarti harus tersedia sebelum pilot; `P2` dan `P3` adalah fase setelah pilot.

| ID | Modul | Deliverable / invariant | Prioritas / fase |
|---|---|---|---|
| FR-ORG-01 | Organization | Hierarki node `Company→Region→Area→Branch` yang dapat dikonfigurasi; tipe dan parent yang diizinkan divalidasi; legal entity assignment eksplisit | MUST/MVP |
| FR-ORG-02 | Organization | Warehouse, stock point, department, division, cost/profit center aktif dengan effective dates; histori perubahan assignment tetap dapat dibaca | MUST/MVP |
| FR-IAM-01 | IAM | User terhubung employee opsional; role + permission + company/branch/warehouse scope; deny by default dan server enforcement | MUST/MVP |
| FR-IAM-02 | IAM | Maker-checker, SoD, suspend, session/device revoke, delegasi sementara dengan expiry dan alasan | MUST/MVP (delegasi P3) |
| FR-MDM-01 | Product | SKU, category, brand, principal, attribute/variant, barcode unik per tenant, UOM dasar dan conversion berversi; batch/serial policy per SKU | MUST/MVP |
| FR-MDM-02 | Customer | Alamat billing/shipping, group/channel/territory/salesman, credit/term, tax, price level; status block mencegah order baru | MUST/MVP |
| FR-MDM-03 | Vendor | Kategori, term, lead time, tax, rekening terenkripsi, relasi product-supplier dan status block | MUST/MVP |
| FR-MDM-04 | Employee | Posisi, supervisor, department, branch, territory, effective-dated assignment | SHOULD/P2 |
| FR-SAL-01 | Sales | Quotation→SO; multi-line/UOM, price snapshot, diskon/promo, pajak, credit & customer checks, approval, history, repeat order | MUST/MVP (promo P3) |
| FR-SAL-02 | Sales | Sales return, credit/debit memo, invoice, payment allocation dan alasan koreksi | MUST/P2 (invoice/payment MVP) |
| FR-SAL-03 | Sales Ops | Target salesman, effective call, visit, route plan, performance dan attribution | SHOULD/P2 |
| FR-PUR-01 | Purchase | PR→RFQ→vendor quotation→comparison→PO, kontrak/blanket PO, toleransi penerimaan dan lead time | MUST/P2 (PR/PO MVP) |
| FR-PUR-02 | Purchase | Receipt parsial, return, vendor invoice match, pembayaran; over/under receipt memerlukan policy dan alasan | MUST/MVP (return P2) |
| FR-INV-01 | Inventory | Setiap perubahan fisik/status stok menghasilkan movement immutable; saldo turunan konsisten per SKU-lokasi-batch-ownership | MUST/MVP |
| FR-INV-02 | Inventory | Reservation, allocation, available, in transit, damaged, expired; larangan negative sellable dan duplicate movement | MUST/MVP |
| FR-INV-03 | Inventory | Opname, adjustment, transfer antar gudang/cabang, discrepancy dan reconciliation | MUST/P2 (adjustment MVP) |
| FR-WMS-01 | WMS | Receive→putaway→pick→pack→dispatch dengan scan/konfirmasi lokasi, bin transfer dan status task | MUST/MVP (bin/wave P2) |
| FR-TRF-01 | Transfer | Request→approve→pick→ship→receive; pengiriman/penerimaan parsial, damage, selisih dan closure | MUST/P2 |
| FR-FIN-01 | AR/AP | Outstanding, due date, aging as-of, receipt/payment parsial, allocation, refund dan unapplied cash | MUST/MVP (refund P2) |
| FR-FIN-02 | Cash & Expense | Bank/cash register, expense/reimbursement, statement import, reconciliation | SHOULD/P3 (POS register Expansion) |
| FR-ACC-01 | Accounting | COA per legal entity, fiscal period, journal type, posting double entry, immutable posted journal, GL, trial balance | MUST/MVP |
| FR-ACC-02 | Accounting | Balance sheet, P&L, cash flow, period lock, reversal/adjustment; drill-down ke source | MUST/P2 (P&L MVP) |
| FR-CRD-01 | Credit | Exposure tak terduplikasi, limit/term, hold, approval override berakhir otomatis, aging input | MUST/MVP |
| FR-PRC-01 | Pricing | Prioritas harga deterministik (special customer→customer→group→channel→regional→base); effective dates, currency, UOM, tie-break dan price snapshot | MUST/MVP (promo P3) |
| FR-APP-01 | Approval | Policy versioned menurut amount, branch, department, role, doc, discount, exposure; sequence/parallel, reject/revise, escalation, delegation, history | MUST/MVP (parallel/escalation P3) |
| FR-BUD-01 | Budget | Anggaran tahunan/bulanan per branch/department/cost center, commitment, actual, available dan override trail | SHOULD/P3 |
| FR-TAX-01 | Tax | Tax code/rule versioned per jurisdiction, inclusive/exclusive, withholding, tax snapshot pada dokumen | MUST/MVP |
| FR-DOC-01 | Document | Attachment berizin, checksum, scan malware, object storage, metadata, versioning untuk penggantian non-finansial | MUST/MVP |
| FR-NOT-01 | Notification | Inbox in-app untuk approval, low stock, overdue, credit; email/push melalui worker, dedup dan preference; WhatsApp hanya lewat adapter berizin | MUST/MVP (push P2) |
| FR-RPT-01 | Reporting | Dashboard per role dan definisi KPI; ekspor CSV/XLSX/PDF; report berat async; waktu refresh jelas | MUST/MVP (scheduled P3) |
| FR-AUD-01 | Audit | Audit privileged action, status, master, posting dan login dengan actor, before/after redacted, IP/device, time, correlation | MUST/MVP |
| FR-NUM-01 | Numbering | Prefix/pola per entity-branch-type-period dengan counter atomik, nomor final sekali pada submit/post | MUST/MVP |
| FR-SRH-01 | Search | Global search customer/SKU/SO/PO/invoice/vendor dengan permission filter; PostgreSQL FTS awal | SHOULD/MVP (sesuai M-08) |
| FR-IMP-01 | Import/export | Template versioned, upload→preview→validate→commit, duplikasi, error per baris, async besar dan audit | MUST/MVP (master CSV; XLSX P2) |
| FR-INT-01 | Integration | `/api/v1`, OAuth client, webhook signed+retry, event/CSV adapter, external ID map dan reconciliation | MUST/MVP (adapters P3) |

### Hierarki organisasi dan scope

`OrgNode(guid,type,parent_id,legal_entity_guid?,valid_from,valid_to)` mendukung hierarki Region/Area/Branch yang dipilih per tenant. `parent_id` adalah FK BIGINT lokal di owner organisasi; representasi API memakai `parent_guid`. `Department` dan `Division` berada pada struktur functional terpisah; branch dan employee assignment dapat banyak-ke-banyak dengan tanggal berlaku. Warehouse dan stock point melekat pada legal entity dan branch melalui relasi efektif. Perubahan parent tidak memindahkan kepemilikan stok/jurnal historis. Query scope memakai closure table atau materialized path versioned untuk membaca descendant; setiap API tetap memeriksa grant `company/legal_entity/branch/warehouse` secara eksplisit. Pelaporan historis dapat memilih **as-was** atau **as-is** hierarchy.

Baseline cardinality: tenant adalah batas isolasi; company adalah grup pelaporan; legal entity adalah pemilik stok/AR/AP/jurnal; branch dan warehouse melekat pada tepat satu legal entity. Customer party dapat dipakai lintas legal entity melalui `CustomerAccount` per entity dengan kredit/pajak/term terpisah. Constraint dan contoh dua legal entity ada di [G-01](decisions/mvp-business-policy.md#g-01--tenant-company-legalentity-branch-warehouse).

### Aturan stok kanonik

Pada key `(legal_entity, warehouse, stock_point/bin, SKU, batch/serial, ownership, inventory_status, base_uom)`, ledger movement adalah sumber audit; saldo agregat ditransaksikan bersamaan dan dapat direkonstruksi. `physical_on_hand = sellable + quality_hold + damaged + expired` di gudang saat ini. `reserved` adalah komitmen order belum dipick; `allocated` adalah bagian reserved yang sudah diikat ke task/bin dan **bukan pengurang kedua**. `available_to_promise = max(0, sellable − reserved − safety_stock − other_holds)`; `pickable = max(0, sellable − allocated − other_holds)` sesuai lokasi. `in_transit` berada pada akun/lokasi transit sendiri dan tidak dihitung sebagai sellable asal/tujuan. Expiry diturunkan dari tanggal dan status saat proses; job penandaan expiry harus membuat status movement yang bisa diaudit. Semua kuantitas disimpan dalam base UOM dengan baseline `NUMERIC(20,6)`; hasil konversi yang tidak dapat direpresentasikan persis pada skala itu ditolak, bukan dibulatkan diam-diam. Kebutuhan skala SKU lebih tinggi harus diputuskan sebelum migration; rasio konversi dan input UOM disimpan di dokumen.

### Aturan kredit kanonik

`Exposure = posted_AR + approved_unshipped + shipped_unaccepted + accepted_unbilled + approved_other_commitments − eligible_deposits`. Nilai gross termasuk pajak per source portion berpindah bucket saat ship/POD/invoice sehingga **tidak dihitung dua kali**; guarantee tidak mengurangi exposure secara default. `available_credit = limit − exposure`. Perhitungan memakai currency legal entity dengan kurs snapshot dan buffer default 5% untuk komitmen terbuka non-IDR; pembayaran pending tidak mengurangi AR sampai berhasil diposting. Lock/snapshot kredit dilakukan saat submit, approval, dan sebelum release delivery; override default nonaktif dan bila diterbitkan harus bernilai maksimum, scope, expiry, reason, serta dua approver berbeda. [Rumus, contoh angka, dan concurrency G-05](decisions/mvp-business-policy.md#g-05--kredit-fx-deposit-override).

### Prioritas pricing dan promotion

Filter rule aktif menurut legal entity, channel, region, customer, SKU, currency, UOM, quantity, tanggal transaksi; pilih specificity tertinggi: contracted/special customer > customer > group > channel > regional > base. Tie-break: priority numerik, effective_from terbaru, lalu rule ID; overlap konflik pada level sama ditolak saat publish. Promo dievaluasi sesudah base price, lalu diskon manual dengan cap dan approval. Snapshot `rule_version`, komponen diskon, taxable base, dan nilai akhir disimpan di setiap SO line. Reprice hanya tindakan eksplisit sebelum approval.

Tipe promo P3: percentage, fixed discount, buy-X-get-Y, tiered, bundle dan minimum purchase. Rule menentukan eligibility, cap, budget promo, stacking/exclusion group, prioritas dan tanggal berlaku; engine menghitung kandidat, memilih kombinasi deterministik yang diizinkan dan menunjukkan explanation per line. Perubahan aturan tidak menilai ulang order approved. Diskon total tidak boleh melebihi gross line; hadiah barang tetap menghasilkan movement bernilai sesuai policy costing/tax; override melewati approval.

## 16. Business Process dan Workflow end-to-end

### Order to Cash (O2C)

1. Customer aktif dan alamat/credit policy valid; salesman membuat SO dari web/mobile, harga/UOM/pajak dihitung dan disnapshot.
2. Submit memvalidasi permission, nomor, credit exposure, policy diskon, status pelanggan. Approval dipilih dari policy version; maker tidak menjadi approver dokumennya.
3. Setelah approved, saga meminta reservation inventori. Bila stok kurang, SO `BACKORDERED` atau ditolak sesuai policy; tidak ada delivery task untuk qty tak ter-reserve.
4. WMS memilih batch FEFO untuk SKU expiry, pick/pack, scan ulang, dispatch; dispatch memindahkan stok ke in transit tanpa mengakui pendapatan/COGS pada profil kontrak default.
5. POD accepted menetapkan qty yang benar-benar diterima. Invoice dibuat dari accepted delivered quantity; Finance Core mem-post AR/revenue/tax dan COGS/in-transit untuk source portion yang sama. POD gagal mengembalikan stok transit tanpa pendapatan/COGS. Profil transfer kendali lain memerlukan kontrak dan policy terbit.
6. Receipt kas dialokasikan ke invoice, mendukung partial/overpayment; AR dan jurnal diperbarui. Retur/credit memo melakukan dokumen lawan dan movement terpisah.

### Procure to Pay (P2P)

1. Requester membuat PR; approver menyetujui. Buyer dapat meminta RFQ, membandingkan harga, term, lead time, kemudian membuat PO.
2. PO approved mengikat committed budget bila modul budget aktif. Supplier mengirim parsial atau penuh.
3. Receiving mencocokkan PO line, UOM, batch/expiry, toleransi. Qty lolos QC masuk stock sellable; qty bermasalah ke quality_hold/damaged. Receipt berulang dengan external delivery ID yang sama ditolak/idempotent.
4. AP mencocokkan vendor invoice ke PO+goods receipt (2/3-way match sesuai policy), merekam selisih/approval; jurnal inventory/GRNI/AP/tax diposting.
5. Payment proposal diperiksa SoD, bank detail diverifikasi, pembayaran diposting dan dialokasikan; refund/return memakai dokumen koreksi.

### Inventory Transfer

Transfer request hanya untuk dua warehouse dalam legal entity yang sama pada MVP. Approval→pick→ship menurunkan sellable sumber dan menambah in_transit; receive menaikkan sellable/quality_hold tujuan sesuai hasil; discrepancy menghasilkan claim/adjustment yang memerlukan approval. Partial shipment dan partial receipt memiliki line-level quantities dan transfer tetap terbuka sampai sisa diselesaikan/cancel. Perpindahan antar legal entity pada fase lanjut memakai pasangan dokumen intercompany, pajak dan jurnal, bukan satu movement internal.

### Record to Report (R2R)

Source business document → posting intent unik → balanced journal di accounting owner → GL → trial balance → financial statement. Journal posted immutable; koreksi lewat reversal dengan referensi original, lalu journal baru. Period close memblok tanggal posting pada periode tertutup; backdated entry memerlukan reopen berizin dan audit. Setiap angka laporan memiliki as-of, currency, legal entity, versi chart/map, dan drill-down ke source.

### Siklus retur

Customer return memerlukan referensi delivery/invoice (pengecualian berizin), reason dan inspeksi: resellable masuk sellable, rusak masuk damaged; credit memo hanya atas accepted qty. Purchase return menurunkan inventory/GRNI/AP sesuai status vendor invoice. Tidak ada edit saldo langsung.

---

# Part 3 — Functional Requirements

## 17. Kontrak fitur besar

Setiap kontrak menjadi sumber FSD, API contract, UI, dan test case. Exception tidak boleh mengubah ledger tanpa dokumen baru. Error code stabil; pesan dapat diterjemahkan.

### F-01 — Organisasi dan akses (FR-ORG-01, FR-IAM-01; MUST/MVP)

- **Objective:** pengguna hanya melihat/mengubah legal entity, branch, warehouse, dan aksi yang diizinkan.
- **Actor:** Tenant Admin, Security Admin, manager pemilik scope.
- **Preconditions:** tenant aktif; legal entity dan role catalog tersedia.
- **Trigger:** admin membuat node organisasi, role/scope assignment, atau suspend user.
- **Main Flow:** validasi parent/effective date → simpan assignment berversi → audit → setiap request memeriksa permission dan data scope di server.
- **Alternative Flow:** role sementara berakhir otomatis; reassignment tidak mengubah ownership transaksi lama.
- **Exception Flow:** parent cycle, scope di luar pemberi, SoD conflict, warehouse lintas entity ditolak atomik.
- **Business Rules:** deny by default; maker ≠ checker; admin tidak bisa menaikkan haknya sendiri; session version memutus token lama.
- **Validation:** code unik per tenant/type, no circular hierarchy, scope grant subset.
- **Permissions:** `organization.manage`, `iam.role.assign`, `iam.user.suspend`, `iam.audit.view`.
- **State Transition:** user `INVITED→ACTIVE→SUSPENDED→ACTIVE/DEACTIVATED`; node `DRAFT→ACTIVE→INACTIVE`.
- **Audit Requirement:** before/after redacted, actor/checker, reason, IP/device, request/trace.
- **Notification:** user dan security admin menerima perubahan privilege.
- **API Requirement:** `/api/v1/org-nodes`, `/users/{guid}/role-assignments`, aksi `suspend`/`revoke-sessions`; update memakai version/ETag.
- **Data Requirement:** `OrgNode`, `OrgClosure`, `LegalEntity`, `Role`, `Permission`, `ScopeGrant`, `Session`.
- **Acceptance Criteria:** AC-IAM-01 user branch A menerima 403 untuk order branch B via URL langsung; AC-IAM-02 suspend memutus akses ≤60 detik.

### F-02 — Master produk, customer, vendor (FR-MDM-01/02/03; MUST/MVP)

- **Objective:** transaksi memakai identitas master dan kebijakan yang valid pada tanggalnya.
- **Actor:** Master Data Steward, Sales/Purchasing Ops.
- **Preconditions:** legal entity, tax code, UOM, category tersedia.
- **Trigger:** create/update/import SKU, customer, vendor.
- **Main Flow:** draft → validasi kode/barcode, tax, alamat, UOM conversion → checker untuk field sensitif → publish versi aktif.
- **Alternative Flow:** merge duplicate membuat alias legacy; price/credit baru hanya berlaku pada transaksi baru.
- **Exception Flow:** conversion nonpositif, version overlap, referenced master dihapus, bank account tidak tervalidasi ditolak.
- **Business Rules:** base UOM immutable setelah movement pertama; master yang telah direferensikan dipensiunkan.
- **Validation:** field wajib per tipe, barcode unik per tenant, rekening terenkripsi dan dual approval saat berubah.
- **Permissions:** `master.product.manage`, `master.customer.manage`, `master.vendor.manage`, `master.sensitive.approve`.
- **State Transition:** `DRAFT→ACTIVE→INACTIVE` atau `DRAFT→REJECTED`.
- **Audit Requirement:** credit limit, rekening, tax ID, conversion merekam perubahan masked dan checker.
- **Notification:** pemilik domain menerima hasil import/publish.
- **API Requirement:** master CRUD, `/publish`, `/deactivate`, lookup versi/as-of.
- **Data Requirement:** `Item`, `SKU`, `UOM`, `UOMConversionVersion`, `Customer`, `Vendor`, `MasterVersion`.
- **Acceptance Criteria:** AC-MDM-01 receipt 2 carton pada rasio 1:12 menambah 24 pcs; perubahan rasio selanjutnya tidak mengubah histori.

### F-03 — Sales Order, kredit, harga (FR-SAL-01, FR-CRD-01, FR-PRC-01; MUST/MVP)

- **Objective:** order approved memiliki harga, pajak, kredit, dan komitmen stok yang sah.
- **Actor:** Salesman, Supervisor, Credit Controller.
- **Preconditions:** customer/SKU aktif, price/tax rule terbit, scope branch sah.
- **Trigger:** submit SO dari web atau sinkronisasi mobile.
- **Main Flow:** buat lines dan snapshot price/UOM/tax → hitung decimal total → submit idempotent → cek customer/credit/discount → approval → reserve → `ALLOCATABLE` atau `BACKORDERED`.
- **Alternative Flow:** partial fulfillment; credit override melalui approval; stock kurang dapat backorder sesuai policy.
- **Exception Flow:** price tak ada, customer blocked, credit berlebih, reservation gagal, version conflict menghasilkan error; delivery tidak dibuat.
- **Business Rules:** invoice hanya untuk qty POD accepted pada profil kontrak default; exposure tidak double count; perubahan material menilai ulang approval.
- **Validation:** qty >0 dalam base UOM, diskon tidak membuat negatif, alamat/entity valid, total server authoritative.
- **Permissions:** `sales.order.create/submit/approve/cancel`, `credit.override.approve`.
- **State Transition:** lihat §20; perubahan line setelah submit memerlukan revision dan approval baru.
- **Audit Requirement:** price override, credit decision, status, lines, reason.
- **Notification:** approver saat pending, salesman saat keputusan/backorder.
- **API Requirement:** `/sales-orders` dan aksi `submit/approve/cancel`; `Idempotency-Key` dan `If-Match` pada mutasi.
- **Data Requirement:** `SalesOrder/Line`, `PriceSnapshot`, `TaxSnapshot`, `CreditDecision`, `ApprovalInstance`, `Reservation`.
- **Acceptance Criteria:** AC-SAL-01 dua submit dengan key sama menghasilkan satu nomor/approval; AC-SAL-02 credit hold mencegah allocation sampai override sah.

### F-04 — PO dan Goods Receipt (FR-PUR-01/02; MUST/MVP)

- **Objective:** hanya barang dari PO sah yang menambah stok sesuai toleransi dan hasil inspeksi.
- **Actor:** Buyer, Approver, Receiving Staff, AP Officer.
- **Preconditions:** vendor aktif, PO approved, warehouse dalam scope.
- **Trigger:** barang datang dan staff memindai PO serta delivery reference.
- **Main Flow:** receipt draft → cocokkan PO line/UOM/qty/batch/expiry → validasi tolerance → klasifikasikan sellable/hold/damaged → post movement atomik → update PO dan emit event.
- **Alternative Flow:** partial receipt, over receipt dalam tolerance, return-to-vendor dari hold.
- **Exception Flow:** duplicate delivery ref, qty melebihi sisa+tolerance, lot wajib kosong, PO closed atau race receipt ditolak tanpa movement.
- **Business Rules:** cumulative accepted ≤ordered+tolerance; receipt dan movement satu transaksi lokal; vendor invoice mengikuti match policy.
- **Validation:** qty >0, expiry policy, legal entity sama, evidence untuk discrepancy.
- **Permissions:** `purchase.order.create/approve`, `inventory.receipt.create/post`, `purchase.receipt.override`.
- **State Transition:** PO `DRAFT→SUBMITTED→APPROVED→PARTIALLY_RECEIVED→RECEIVED→CLOSED`; receipt `DRAFT→POSTED`.
- **Audit Requirement:** scan source, operator/device, delta qty, override, movement ID.
- **Notification:** buyer/AP ketika discrepancy dan receipt selesai.
- **API Requirement:** `/purchase-orders`, `/goods-receipts/{guid}/post`; idempotency key dan delivery ref uniqueness sesuai policy.
- **Data Requirement:** `PurchaseOrder/Line`, `GoodsReceipt/Line`, `Lot`, `InventoryMovement`.
- **Acceptance Criteria:** AC-PUR-02 dua post receipt identik menghasilkan satu movement set; receipt 6+4 menutup PO 10 tanpa qty 11.

### F-05 — Stok, reservasi, opname (FR-INV-01/02/03; MUST/MVP, opname P2)

- **Objective:** saldo tepat dan setiap perubahan memiliki sumber terlacak.
- **Actor:** Inventory Service, warehouse staff, Inventory Controller.
- **Preconditions:** SKU/warehouse aktif; ownership jelas; source sah.
- **Trigger:** reserve/release, receipt, ship, transfer, return, adjustment, count.
- **Main Flow:** lock balance row dengan urutan key tetap → cek version/invariant → movement append-only + balance + outbox dalam satu transaksi PostgreSQL → publish async.
- **Alternative Flow:** stok kurang jadi backorder; opname membuat adjustment dari counted minus book dengan approval.
- **Exception Flow:** negative sellable, serial duplicate, expired lot, source-line-action duplicate, lock timeout ditolak atau retry aman.
- **Business Rules:** satu movement per source action; sellable nonnegative; reversal adalah movement lawan.
- **Validation:** qty positif, presisi SKU, base UOM, FEFO bila aktif, reason/evidence adjustment.
- **Permissions:** `inventory.stock.view`, `inventory.reserve` service-only, `inventory.adjustment.create/approve`.
- **State Transition:** reservation `REQUESTED→HELD→ALLOCATED→CONSUMED/RELEASED/EXPIRED`; count `OPEN→COUNTED→REVIEWED→POSTED`.
- **Audit Requirement:** source/event ID, before/after balance, batch/bin/operator, approval, trace.
- **Notification:** low stock, discrepancy, reservation failed.
- **API Requirement:** internal reserve/release/consume command dengan request ID unik; public stock inquiry dan adjustment; tiada set-balance endpoint.
- **Data Requirement:** `StockBalance`, `InventoryMovement`, `Reservation`, `StockCount`, `Lot`, `Serial`.
- **Acceptance Criteria:** AC-INV-01 100 concurrent reservation atas available 10 tidak menghasilkan held >10; AC-INV-02 replay event tidak menambah stok dua kali.

### F-06 — WMS, delivery, transfer (FR-WMS-01, FR-TRF-01; MUST/MVP/P2)

- **Objective:** barang terlacak per task, lokasi, batch dan status fisik.
- **Actor:** Picker, Packer, Dispatcher, Receiver, Driver.
- **Preconditions:** reservation/transfer approved, lokasi warehouse aktif, assignment staff; bin aktif hanya jika kebijakan bin P2 diaktifkan.
- **Trigger:** release pick task atau transfer shipment.
- **Main Flow:** buat pick list → scan SKU/batch (dan bin jika aktif) → pack → dispatch menulis movement OUT/IN_TRANSIT → POD/receipt mengonfirmasi hasil.
- **Alternative Flow:** partial pick/shipment/receipt; bin substitute dengan alasan; damaged dipisah.
- **Exception Flow:** scan mismatch, task diambil staff lain, qty >allocated, expired lot, intercompany tanpa dokumen sah ditolak.
- **Business Rules:** dispatch qty ≤picked≤allocated; shipped=received+damaged+discrepancy+still_in_transit.
- **Validation:** serial scan sekali, packing list cocok, bukti damage wajib.
- **Permissions:** `warehouse.pick/pack/dispatch`, `inventory.transfer.approve/receive`.
- **State Transition:** task `OPEN→IN_PROGRESS→PICKED→PACKED→DISPATCHED`; transfer §20.
- **Audit Requirement:** scan time/device/location/operator, exception, POD hash.
- **Notification:** receiver saat in transit, requester saat complete/discrepancy.
- **API Requirement:** task claim/scan/complete, dispatch, transfer receive; idempotency + optimistic version.
- **Data Requirement:** `PickTask`, `Pack`, `DeliveryOrder/Line`, `TransferOrder/Line`, `Shipment`.
- **Acceptance Criteria:** AC-WMS-01 serial tak dapat dipack dua kali; AC-TRF-01 8 shipped, 6 received, 1 damaged menyisakan 1 in transit.

### F-07 — AR/AP, invoice, pembayaran (FR-FIN-01; MUST/MVP)

- **Objective:** tagihan dan settlement akurat tanpa invoice atau payment ganda.
- **Actor:** AR/AP Officer, Cashier, Finance Approver.
- **Preconditions:** delivery/receipt sah, counterparty aktif, period terbuka.
- **Trigger:** issue invoice atau post payment/receipt.
- **Main Flow:** invoice dari source qty eligible → snapshot tax/currency → issue → posting intent/journal → outstanding → payment bank reference → allocate → jurnal settlement.
- **Alternative Flow:** partial payment, unapplied cash, multi invoice allocation, credit memo, reversal.
- **Exception Flow:** source sudah ditagih, allocation >unapplied, duplicate bank ref, period closed, kurs hilang, unbalanced journal menolak posting.
- **Business Rules:** source line portion ditagih sekali; payment amount=allocated+unapplied+fee sesuai policy; posted doc immutable.
- **Validation:** amount decimal >0, due date/tax valid, bank account verified, FX snapshot.
- **Permissions:** `finance.invoice.issue`, `finance.receipt.post`, `finance.payment.approve/post`, `finance.document.reverse`.
- **State Transition:** invoice `DRAFT→ISSUED→PARTIALLY_PAID→PAID`; payment `DRAFT→APPROVED→POSTED→REVERSED`.
- **Audit Requirement:** allocation, bank ref, posting, reversal reason, checker.
- **Notification:** invoice due/overdue dan payment outcome.
- **API Requirement:** invoice issue, payment post/allocate/reverse, aging as-of; idempotency plus source uniqueness.
- **Data Requirement:** `Invoice/Line`, `Payment`, `PaymentAllocation`, `AROpenItem`, `APOpenItem`, `PostingIntent`.
- **Acceptance Criteria:** AC-FIN-01 payment 60 ke invoice 100 menyisakan 40; retry tidak menambah receipt/journal.

### F-08 — Accounting dan laporan keuangan (FR-ACC-01/02; MUST/MVP/P2)

- **Objective:** posted journal seimbang dan laporan dapat ditelusuri.
- **Actor:** Accounting Service, GL Accountant, Controller.
- **Preconditions:** COA/posting rule aktif; fiscal period open.
- **Trigger:** invoice, receipt, payment, adjustment atau manual journal approved.
- **Main Flow:** resolve posting rule version/dimension → validate debit=credit per currency/base → append journal header/lines → update GL projection → expose trial balance.
- **Alternative Flow:** pada MVP missing mapping menolak issue/post dan transaksi lokal rollback; setelah Finance–Accounting dipisah, source menjadi `POSTING_EXCEPTION`. Reversal membuat inverse journal tertaut.
- **Exception Flow:** account inactive, dimension invalid, period locked, FX missing, rounding imbalance di luar tolerance; source tidak ditandai fully posted.
- **Business Rules:** satu posting intent satu journal; posted journal hanya reversal; minimum dua lines.
- **Validation:** source reference, amount nonnegative, legal entity, accounting date/period, cost center bila wajib.
- **Permissions:** `accounting.journal.create/approve/post/reverse`, `accounting.period.close/reopen`.
- **State Transition:** `DRAFT→SUBMITTED→APPROVED→POSTED→REVERSED`.
- **Audit Requirement:** rule version, source hash, lines, checker, period close/reopen.
- **Notification:** exception ke Controller; closing blocker ke owner.
- **API Requirement:** journal actions, trial balance/report query, exception replay; idempotent posting by source type/id/action.
- **Data Requirement:** `Account`, `FiscalPeriod`, `PostingRule`, `Journal/Line`, `GLBalance`, `FXRate`.
- **Acceptance Criteria:** AC-ACC-01 trial balance debit=credit per entity/period; replay event tidak membuat journal kedua.

### F-09 — Approval, tax, budget dan policy (FR-APP-01, FR-TAX-01, FR-BUD-01; MUST/MVP, budget P3)

- **Objective:** keputusan bisnis mengikuti policy yang berlaku dan dapat direproduksi.
- **Actor:** Policy Admin, Approver, Process Owner.
- **Preconditions:** policy draft diuji dan effective interval tidak konflik.
- **Trigger:** dokumen submit/perubahan amount/discount/credit atau commitment.
- **Main Flow:** evaluate input snapshot → buat approval steps → inbox → cek approver SoD/scope → decision → callback idempotent ke domain.
- **Alternative Flow:** parallel quorum, delegation, escalation pada P2; budget warning/soft block sesuai policy.
- **Exception Flow:** ambiguous/no rule, approver kosong, self approval, expired delegation, concurrent decision ditolak.
- **Business Rules:** perubahan material membatalkan approval; budget available=budget−actual−committed.
- **Validation:** threshold tanpa gap/overlap; tax effective date; policy test cases wajib sebelum publish.
- **Permissions:** `policy.*.manage/publish`, `approval.decide/delegate`, `budget.override`.
- **State Transition:** approval `PENDING→APPROVED/REJECTED/RETURNED/EXPIRED`; policy `DRAFT→TESTED→PUBLISHED→RETIRED`.
- **Audit Requirement:** input snapshot, matched rule/version, decision, delegation/escalation reason.
- **Notification:** inbox, reminder SLA, final outcome.
- **API Requirement:** policy simulate/publish; approval inbox/decision; tax quote; budget check/commit/release.
- **Data Requirement:** `PolicyVersion`, `ApprovalInstance/Step/Decision`, `TaxRule`, `Budget/Commitment`.
- **Acceptance Criteria:** AC-APP-01 maker tidak bisa approve sendiri; AC-BUD-01 cancel PO melepas commitment sekali.

### F-10 — Import, dokumen, integrasi, reporting (FR-IMP-01, FR-DOC-01, FR-INT-01, FR-RPT-01; MUST/MVP dasar)

- **Objective:** data masuk/keluar melalui validasi domain dengan hasil dan sumber jelas.
- **Actor:** Data Steward, Integration Client, Analyst.
- **Preconditions:** template/schema/version, mapping, scope dan kuota disetujui.
- **Trigger:** upload file, webhook, API client call atau report request.
- **Main Flow:** quarantine/scan → parse → preview row errors → commit melalui domain commands → simpan external ID/reconciliation → report async bila berat.
- **Alternative Flow:** dry-run, partial commit per batch dengan manifest, export terjadwal, webhook retry.
- **Exception Flow:** CSV formula injection, oversize, malformed input, unsupported version, duplicate row, invalid signature atau PII scope mismatch ditolak.
- **Business Rules:** integrasi tidak menulis DB domain; tiap row punya outcome dan import batch ID; report menunjukkan as-of/freshness.
- **Validation:** MIME+magic bytes, size cap, schema, duplicate key, referential integrity, permission per entity.
- **Permissions:** `data.import/commit/export`, `integration.client.manage`, `document.upload/view`, `report.run`.
- **State Transition:** import `UPLOADED→VALIDATING→PREVIEW_READY→COMMITTING→COMPLETED/PARTIAL/FAILED`; report `QUEUED→RUNNING→READY/FAILED/EXPIRED`.
- **Audit Requirement:** file hash, template version, actor, row outcomes, report parameters, download access.
- **Notification:** ready/failure tanpa data sensitif.
- **API Requirement:** async job status/result, signed webhook, cursor pagination; URL storage jangka pendek.
- **Data Requirement:** `ImportJob/RowResult`, `ExternalIdentityMap`, `WebhookDelivery`, `Attachment`, `ReportJob`.
- **Acceptance Criteria:** AC-IMP-01 preview 100 row dengan 3 error menunjukkan sebab; commit tidak membuat 3 row salah; rerun tak duplikat.

### F-11 — Sales mobile offline (FR-SAL-01/03; SHOULD/P2)

- **Objective:** salesman mencatat visit/draft order saat koneksi buruk tanpa klaim stok/kredit palsu.
- **Actor:** Salesman, Supervisor.
- **Preconditions:** login online awal, device terdaftar, master snapshot aktif.
- **Trigger:** route dibuka offline, order/visit dibuat, koneksi pulih.
- **Main Flow:** local UUID + encrypted SQLite outbox → queue command berurutan → push dengan idempotency key → server validasi ulang harga/kredit/stok → map server ID dan outcome.
- **Alternative Flow:** foto/POD upload terpisah dengan checksum; master delta refresh; backorder setelah user review.
- **Exception Flow:** token expired, device revoked, price changed, customer blocked, duplicate command, upload gagal tidak menghapus draft.
- **Business Rules:** offline order bukan approved order; server menetapkan nomor final, harga, credit, stok; tidak ada approval offline.
- **Validation:** cached master version/TTL, qty/UOM, foto size, GPS consent.
- **Permissions:** `mobile.route.view`, `mobile.visit.create`, `sales.order.create` berdasarkan scope server.
- **State Transition:** local `LOCAL_DRAFT→PENDING_SYNC→SYNCING→ACCEPTED/NEEDS_REVIEW/REJECTED`.
- **Audit Requirement:** device/local/server ID, attempts, conflict dan user acknowledgement.
- **Notification:** sync outcome dan order perlu revisi.
- **API Requirement:** `/mobile/sync/pull?cursor=`, `/mobile/sync/push`; per-command outcome dan cursor monotonic.
- **Data Requirement:** local outbox, `SyncCommand`, `SyncCursor`, `Device`, `Visit`, `RoutePlan`, ID map.
- **Acceptance Criteria:** AC-MOB-01 draft tetap ada setelah restart; saat online satu server order dibuat; perubahan harga meminta review.

### F-12 — Sales return, purchase return, credit/debit memo (FR-SAL-02, FR-PUR-02; MUST/P2)

- **Objective:** koreksi barang dan nilai terjadi tanpa menghapus histori pengiriman, penerimaan, invoice atau jurnal asli.
- **Actor:** Customer Service, Warehouse Inspector, Buyer, AR/AP Officer, Approver.
- **Preconditions:** source delivery/receipt dan invoice diketahui; return window dan reason policy aktif.
- **Trigger:** customer/vendor mengajukan retur atau koreksi harga/qty.
- **Main Flow:** buat RMA/return request → validasi eligible qty/value dan approval → inspeksi fisik → movement ke sellable/hold/damaged atau outbound vendor → credit/debit memo dari accepted qty/value → posting reversal/adjustment journal dan open item.
- **Alternative Flow:** partial return, barang belum invoiced, replacement order, hanya price adjustment tanpa movement.
- **Exception Flow:** cumulative return >source accepted qty, serial tak cocok, period closed, memo melebihi original taxable base atau memo duplicate ditolak.
- **Business Rules:** satu source portion diretur maksimum sekali secara kumulatif; tax dan cost memakai snapshot original atau aturan koreksi yang disetujui; posted memo immutable.
- **Validation:** reason dan attachment bukti wajib menurut threshold; inspeksi menentukan status stok; legal entity/currency source sama.
- **Permissions:** `sales.return.create/approve`, `purchase.return.create/approve`, `finance.memo.issue`.
- **State Transition:** return `DRAFT→SUBMITTED→APPROVED→INSPECTED→POSTED→CLOSED`; `SUBMITTED→REJECTED`.
- **Audit Requirement:** source, qty/value original dan koreksi, inspector, approver, movement/journal IDs, reason.
- **Notification:** requester, warehouse, AR/AP saat decision, inspeksi dan memo issue.
- **API Requirement:** return create/approve/inspect/post dan memo issue, masing-masing idempotent dengan expected version.
- **Data Requirement:** `ReturnOrder/Line`, `ReturnInspection`, `CreditMemo/DebitMemo`, `Movement`, `PostingIntent`.
- **Acceptance Criteria:** AC-RET-01 delivery 10, invoice 10, return accepted 3 menghasilkan credit memo maksimal 3 tanpa mengubah invoice asal; retry tidak menambah movement/journal. AC-RET-02 delivery 10, return accepted 3 sebelum invoice hanya mengizinkan invoice maksimal 7 tanpa credit memo.

### F-13 — RFQ, vendor comparison dan blanket PO (FR-PUR-01; SHOULD/P2)

- **Objective:** pilihan pemasok terbukti kompetitif dan call-off tidak melampaui kontrak.
- **Actor:** Requester, Buyer, Purchasing Manager.
- **Preconditions:** PR approved, vendor aktif, product-supplier mapping dan currency policy ada.
- **Trigger:** buyer membuka RFQ atau menarik PO dari blanket contract.
- **Main Flow:** RFQ ke vendor berizin → quotation per item/qty/UOM/lead time/term → normalisasi currency/UOM → comparison matrix → buyer memilih dengan reason → PO dibuat dari penawaran/kontrak versi yang menang → approval.
- **Alternative Flow:** single-source procurement dengan alasan; partial award ke beberapa vendor; blanket PO release bertahap.
- **Exception Flow:** quotation expired, vendor blocked, kontrak cap/qty habis, comparison tanpa kurs, self approval ditolak.
- **Business Rules:** evaluation criteria dan weight dipublikasikan sebelum vendor selection; perubahan award material memerlukan approval ulang; cumulative call-off ≤contract cap.
- **Validation:** line match ke PR, quantity positive, price decimal, delivery date/lead time, attachment quotation.
- **Permissions:** `purchase.rfq.create`, `purchase.vendor.select`, `purchase.contract.manage`, `purchase.order.approve`.
- **State Transition:** RFQ `DRAFT→OPEN→CLOSED/AWARDED`; blanket `DRAFT→APPROVED→ACTIVE→EXHAUSTED/EXPIRED`.
- **Audit Requirement:** invited vendors, bid versions, comparison snapshot, selection rationale dan approver.
- **Notification:** buyer saat quote masuk/expired; vendor channel bila integrasi tersedia.
- **API Requirement:** RFQ/quotation/compare/award, blanket release; kontrak source/version pada PO.
- **Data Requirement:** `RFQ/Line`, `VendorQuotation/Line`, `AwardDecision`, `PurchaseContract`, `BlanketPORelease`.
- **Acceptance Criteria:** AC-RFQ-01 award menyimpan matriks perbandingan dan reason; release yang melampaui cap ditolak.

### F-14 — Budget, expense dan reimbursement (FR-BUD-01, FR-FIN-02; SHOULD/P3)

- **Objective:** pengeluaran tidak melebihi policy anggaran tanpa jejak override dan settlement yang benar.
- **Actor:** Department Requester, Budget Owner, AP Officer, Employee, Controller.
- **Preconditions:** approved budget version, cost center, expense type, payment account dan period aktif.
- **Trigger:** PR/expense/reimbursement diajukan atau PO diposting.
- **Main Flow:** cek available budget → reserve commitment → approval berdasar amount/cost center → receipt/expense actual diposting → commitment berkurang sebesar actual → AP/employee payable → payment dan journal.
- **Alternative Flow:** soft warning, carry-forward/reallocation antar cost center, partial utilization, cash advance offset.
- **Exception Flow:** insufficient hard budget, duplicate receipt, missing cost center, self approval, closed period, reallocation tanpa authority ditolak.
- **Business Rules:** available=budget−actual−committed; source punya satu active commitment; actual dan release commitment tidak double count.
- **Validation:** evidence expense, category/tax, amount/currency, receipt date dan duplikasi nomor bukti.
- **Permissions:** `budget.create/approve/override`, `expense.submit/approve`, `reimbursement.post`.
- **State Transition:** budget `DRAFT→APPROVED→ACTIVE→CLOSED`; expense `DRAFT→SUBMITTED→APPROVED→POSTED→PAID`.
- **Audit Requirement:** budget version, check snapshot, override reason, approver, payment/journal link.
- **Notification:** budget threshold, pending decision, reimbursement paid.
- **API Requirement:** check/commit/release budget, expense and reimbursement actions dengan idempotency.
- **Data Requirement:** `Budget/Line`, `BudgetCommitment`, `ExpenseClaim`, `ReceiptAttachment`, `Payment`, `Journal`.
- **Acceptance Criteria:** AC-BUD-02 budget 100, committed PO 40, actual 20 dari PO itu menghasilkan available 60, bukan 40; cancel sisa PO mengembalikan 20.

## 18. User Stories dan acceptance criteria

| ID | User story | Given / When / Then |
|---|---|---|
| US-01 | As a Salesman, I want to create a multi-UOM order, so that customer demand is recorded accurately. | **Given** 1 carton=12 pcs; **When** submit 2 carton; **Then** SO menyimpan 24 base pcs dan satu nomor final. |
| US-02 | As a Credit Controller, I want to review exceeded exposure, so that risky orders are controlled. | **Given** exposure termasuk open order; **When** SO melebihi limit; **Then** hold sampai override sah. |
| US-03 | As a Warehouse Staff, I want to scan exact batch and, when enabled, bin, so that stock is traceable. | **Given** pick task FEFO; **When** batch lain/expired dipindai, atau bin berbeda saat fitur bin aktif (P2); **Then** task ditolak atau override berizin dengan alasan. |
| US-04 | As a Buyer, I want partial receipt, so that deliveries can be tracked separately. | **Given** PO 10; **When** receipt 6 lalu 4; **Then** dua GRN dan stock +10 saja. |
| US-05 | As an AP Officer, I want three-way match, so that invoice mismatch is visible. | **Given** PO 10 dan receipt 6; **When** invoice qty 10; **Then** 4 ditahan sesuai policy. |
| US-06 | As a Controller, I want journals linked to source, so that balances are reliable. | **Given** invoice issued; **When** posting diproses dua kali; **Then** hanya satu balanced journal. |
| US-07 | As an Approver, I want an inbox with due time, so that I can decide promptly. | **Given** PO pending; **When** approve; **Then** status naik sekali dan maker diberi notifikasi. |
| US-08 (P2) | As a Salesman, I want offline order draft, so that lost connectivity does not lose work. | **Given** master cache; **When** draft offline lalu online; **Then** satu order tersinkron atau konflik terlihat. |
| US-09 | As an Auditor, I want to trace variance to count and approval, so that corrections are explainable. | **Given** adjustment posted; **When** movement dibuka; **Then** source, before/after, approver dan reason terbaca. |
| US-10 | As an Executive, I want a scoped dashboard with freshness time, so that data age is clear. | **Given** akses dua entity; **When** membuka revenue; **Then** hanya data dua entity dan refresh time ditampilkan. |

## 19. Business Rules lintas modul

| ID | Aturan | Enforcement |
|---|---|---|
| BR-IAM-01 | Deny by default; grant perlu permission aksi **dan** scope data. | Server policy + integration test |
| BR-IAM-02 | Maker tidak approve/post dokumen buatannya; break-glass terpisah dan diaudit. | Approval + domain |
| BR-MDM-01 | Base UOM dan ownership legal entity tidak diubah setelah transaksi. | Master validator |
| BR-SAL-01 | Per delivery line: gross invoiced qty ≤delivered accepted qty−accepted pre-invoice return qty; credited post-invoice return qty ≤gross invoiced qty yang belum dikreditkan; net billed qty=gross invoiced−credited qty. Retur setelah invoice tidak membuat invoice asli invalid. | Unique source portion allocation |
| BR-CRD-01 | Exposure bucket mutually exclusive; cek ulang sebelum dispatch. | Credit projection |
| BR-PRC-01 | Price/promo/tax rule punya immutable published version dan effective range. | Policy publisher |
| BR-PUR-01 | Receipt cumulative ≤PO open+tolerance; di luar toleransi perlu PO amendment. | Purchase/Inventory |
| BR-INV-01 | Movement append-only dan idempotent by source action; saldo bukan field edit UI. | Unique index + transaction |
| BR-INV-02 | Sellable/available tidak negatif; expired/damaged/hold tidak dialokasikan. | Row lock + constraint |
| BR-WMS-01 | Dispatch qty ≤picked≤allocated; serial berada di satu lokasi/status fisik. | WMS + Inventory |
| BR-TRF-01 | Transfer lintas legal entity memakai intercompany documents. | Transfer validator |
| BR-FIN-01 | Finance posting tidak dihapus; void/reversal refer original dan reason. | Accounting owner |
| BR-ACC-01 | Debit=credit per currency dan base currency setelah rounding policy. | DB transaction |
| BR-APP-01 | Amount, payee, line, discount, currency berubah → approval lama batal. | Domain owner |
| BR-BUD-01 | Available=approved budget−posted actual−active commitment. | Budget owner |
| BR-INT-01 | External writer tidak menulis DB domain; webhook signed, dedup, retry terbatas. | Integration layer |
| BR-MOB-01 | Nomor final, harga, credit, stok diputuskan server; offline cache advisory. | Sync processor |
| BR-TIM-01 | Instant UTC; document date memakai zona legal entity; period memakai local accounting date. | Domain + time library |

## 20. State Machines

| Dokumen | Valid transition | Invalid transition / syarat |
|---|---|---|
| Sales Order | `DRAFT→SUBMITTED→WAITING_APPROVAL→APPROVED→APPROVED_PENDING_RESERVATION→ALLOCATABLE→PARTIALLY_FULFILLED→FULFILLED→COMPLETED`; `SUBMITTED→APPROVED` bila tanpa approval; `APPROVED_PENDING_RESERVATION→BACKORDERED/RESERVATION_FAILED→ALLOCATABLE` setelah retry/stock baru; pre-shipment `→CANCELLED`; pending `→REJECTED/REVISION_REQUIRED→DRAFT` | `DRAFT→FULFILLED`, `REJECTED→ALLOCATABLE`, cancel qty shipped, edit material tanpa revision |
| Purchase Order | `DRAFT→SUBMITTED→WAITING_APPROVAL→APPROVED→PARTIALLY_RECEIVED→RECEIVED→CLOSED`; sebelum receipt `→CANCELLED` | `DRAFT→RECEIVED`; cancel received qty |
| Goods Receipt | `DRAFT→VALIDATED→POSTED`; pre-post `→VOIDED` | `POSTED→DRAFT/DELETED`; koreksi pakai return/adjustment |
| Delivery | `DRAFT→PICKING→PICKED→PACKED→DISPATCHED→POD_ACCEPTED_PENDING_FINANCE→DELIVERED`; dispatch `→PARTIALLY_DELIVERED/EXCEPTION` per qty | `DISPATCHED→DRAFT`; qty >allocated; `POD_ACCEPTED_PENDING_FINANCE→DELIVERED` tanpa Finance ack |
| Transfer | `DRAFT→SUBMITTED→APPROVED→PICKING→IN_TRANSIT→PARTIALLY_RECEIVED→RECEIVED→COMPLETED` | `IN_TRANSIT→CANCELLED` tanpa menyelesaikan transit |
| Invoice | `DRAFT→ISSUED→PARTIALLY_PAID→PAID`; `ISSUED/PARTIALLY_PAID→VOID_PENDING→VOIDED` via reversal | `ISSUED→DRAFT`; delete posted |
| Payment | `DRAFT→SUBMITTED→APPROVED→POSTED→REVERSED` | `POSTED→DRAFT` |
| Journal | `DRAFT→SUBMITTED→APPROVED→POSTED→REVERSED` | `POSTED→EDITED/DELETED`, post period closed |
| Approval | `PENDING→APPROVED/REJECTED/RETURNED/EXPIRED` | Dua keputusan berbeda pada step/version sama |

Setiap transisi adalah command dengan precondition, expected entity version, permission, idempotency key, event dan audit. Status agregat tidak menggantikan qty per line. `COMPLETED` pada SO berarti seluruh qty delivered/invoiced atau sisa dibatalkan eksplisit.

## 21. Approval Workflow

Policy mempunyai scope, effective range, priority, conditions, version, steps dan fallback. Default implementasi: gross total < IDR 10 juta supervisor; ≥10 juta dan ≤100 juta manager; >100 juta director. Manual discount >0–5% menambah Sales Manager, >5–10% menambah Director, >10% ditolak; over-receipt default 0% dan partial under-receipt tetap open. Currency lain dikonversi memakai FX snapshot saat submit. Parallel approval dan delegation masuk P3; SoD maker-checker berlaku sejak MVP. Rule ambiguous atau approver tidak ditemukan → `PENDING_CONFIGURATION` dan notifikasi owner; dokumen tidak lolos diam-diam. [Batas inklusif dan simulasi G-06](decisions/mvp-business-policy.md#g-06--approval-sod-diskon-receipt).

## 22. Numbering, deletion, waktu, presisi

**Nomor:** pola `SO/{branch}/{YYYY}/{MM}/{000001}` berversi per (legal_entity, branch, document_type, local_period). Nomor final dialokasikan saat submit/issue/post dalam transaksi DB memakai row counter atomik dan unique index. Draft memakai UUID/kode sementara; cancel/void tidak memakai ulang nomor. Gap akibat kegagalan eksternal dicatat. Kebutuhan *gapless* hukum lokal ditentukan kemudian.

**Hapus:** master belum direferensikan boleh soft delete dengan `deleted_at/by` dan uniqueness aktif yang jelas; master telah direferensikan dinonaktifkan. Transaksi posted tidak dihapus; cancel/void/reversal dengan original reference dan reason. Retention/erasure PII memakai masking/tokenization bila kewajiban audit mengizinkan.

**Waktu:** instant `timestamptz` UTC; simpan IANA timezone legal entity/branch dan `business_date` lokal. Filter satu hari UI menjadi UTC half-open interval [start_local, next_day_local) agar DST benar. Fiscal period memakai local accounting date legal entity. Event menyimpan `occurred_at` dan `recorded_at` UTC. User timezone untuk display/filter. Backdate memerlukan izin, period open dan reason.

**Uang:** Go decimal library yang divalidasi dan PostgreSQL `NUMERIC(20,6)` untuk nominal internal; tidak memakai float. Harga unit dan kuantitas hingga 6 decimal; total settlement mengikuti minor unit currency configuration. Rounding mode default asumsi `HALF_UP` dan titik rounding terdokumentasi: line discount → taxable base → line tax → document total. Residual masuk akun rounding yang dikonfigurasi. FX `NUMERIC(24,10)` dengan source/time snapshot. [Dokumentasi PostgreSQL menyebut numeric tepat untuk nominal uang](https://www.postgresql.org/docs/18/datatype-numeric.html).

---

# Part 4 — Domain & Data Model

## 23. Domain Model dan bounded contexts

| Context | Aggregates utama | Memiliki fakta authoritative | Membaca konteks lain melalui |
|---|---|---|---|
| Organization/IAM | LegalEntity, OrgNode, User, Role, ScopeGrant | Struktur berlaku dan hak akses | Tidak ada direct foreign DB |
| Master Data | Product/SKU, Customer, Vendor, UOM | Identitas dan versi master | Org API/event |
| Commercial | SalesOrder, PurchaseOrder, Quotation | Komitmen jual/beli, harga/tax snapshot | Master, Pricing, Credit, Approval |
| Inventory/WMS | StockBalance, Movement, Reservation, Receipt, Transfer, DeliveryTask | Qty dan status stok fisik | Sales/Purchase commands, Master snapshot |
| Finance | Invoice, Payment, Allocation, OpenItem, CreditPolicy | Piutang/utang dan settlement | Delivery/Receipt, Accounting status |
| Accounting | PostingIntent, Journal, Account, FiscalPeriod | Ledger finansial dan period | Business source event/API |
| Policy | PriceRule, TaxRule, ApprovalPolicy, Budget | Aturan terbit dan keputusan versi | Org/master reference |
| Support | Document, Notification, Audit, Import, Integration, Report | Evidence, delivery, projection, metadata | Domain events/API |

**Invariant boundary:** satu aggregate dapat ditulis hanya oleh owner. Foreign ID lintas owner adalah UUID+source type yang divalidasi via API/event snapshot, bukan DB-level FK lintas service. Referential reconciliation background menangkap orphan/lag. Projection/report boleh stale dengan freshness indicator; command validation kritikal meminta owner authoritative.

## 24. High-Level ERD tekstual

`Tenant 1—N Company 1—N LegalEntity 1—N Branch 1—N Warehouse 1—N Bin`. `OrgNode(parent_id)` menyusun Region/Area/Branch; `Department/Division` punya hierarki fungsional; `Employee N—M Branch/Territory` via effective assignment. `User 0..1—1 Employee; User 1—N RoleAssignment N—1 Role 1—N Permission; RoleAssignment N—M ScopeGrant`.

`Product 1—N SKU; SKU 1—N Barcode/UOMConversionVersion/Lot/Serial`. `Customer 1—N Address; Customer N—1 CustomerGroup/Channel/Territory; Vendor N—M SKU` via `ProductSupplier`.

`Customer 1—N SalesOrder 1—N SalesOrderLine N—1 SKU`. `SalesOrderLine 1—N Reservation/DeliveryLine; DeliveryLine 1—N InvoiceLine`, dengan unique billed source portion. `Vendor 1—N PurchaseOrder 1—N PurchaseOrderLine 1—N GoodsReceiptLine; GoodsReceiptLine 1—N InventoryMovement`. `Warehouse/SKU/Lot/Bin 1—N InventoryMovement`; `StockBalance` unik per stock key. `TransferOrder 1—N TransferLine 1—N Shipment/ReceiptLine`.

`Invoice 1—N InvoiceLine` dan `Invoice N—M Payment` melalui `PaymentAllocation`. `Invoice/Payment/Movement 1—N PostingIntent 1—0..1 Journal 1—N JournalLine N—1 Account`. `LegalEntity 1—N FiscalPeriod/Account/PostingRule`. `BusinessDocument 1—N ApprovalInstance/Attachment/AuditEvent` melalui typed reference. `EventOutbox` dan `ConsumerInbox` berada pada setiap owner yang mempublikasikan/mengonsumsi event.

## 25. Entity fields, keys, indexes dan retention

**Standard entity fields:** `id BIGINT GENERATED ALWAYS AS IDENTITY` adalah primary key lokal per tabel/owner; `guid UUIDv7 UNIQUE NOT NULL` adalah identitas publik/lintas owner. API/event tidak mengekspos `id`. Entitas mutable juga memiliki `tenant_guid`, `legal_entity_guid` bila relevan, `code`, `name`, `status` sesuai domain, `created_at`, `created_by`, `updated_at`, `updated_by`, `deleted_at`, `deleted_by` dan `version BIGINT` mulai 1. Kolom `*_by` menyimpan GUID actor user/service/system, dengan `actor_type` di audit; `updated_*` awal sama dengan `created_*`, `deleted_*` NULL sampai soft delete. Field yang tidak relevan untuk tabel penghubung tidak dipaksa; ledger/journal/audit append-only boleh menghilangkan `updated_*`/`deleted_*` dan menyimpan `version=1` atau tidak punya version bila invariant tabel melarang update. Transaksi menambah `document_no`, `business_date`, `currency`, `source_type/guid`, `approval_version`, `posted_at/by` dan cancellation/reversal refs. Ledger/event menambah `occurred_at`, `recorded_at`, `event_id`, `correlation_id` sebagai identifier protokol. PII hanya di tabel/kolom yang berizin. Detail DDL dan pengecualian ada di [standar database](engineering/database-standards.md).

**UUID:** `guid` memakai UUIDv7 karena time-ordered dan cocok untuk indexing; jangan mengambil timestamp GUID sebagai tanggal bisnis atau bukti waktu. UUIDv4 diterima untuk import/kompatibilitas; public API memperlakukan GUID opaque. PostgreSQL 18 menyediakan UUIDv4/v7 native. [Dokumentasi UUID PostgreSQL](https://www.postgresql.org/docs/current/datatype-uuid.html).

**Uniqueness:** master code unik per tenant/legal entity+active scope; document number unik per entity/type/period; `business_operation_guid` unik permanen pada registry/header operasi, sementara beberapa line/leg movement atau journal dalam satu operasi dibedakan dengan source portion key/leg yang stabil dan unik. `version` hanya untuk optimistic concurrency, bukan bagian dedup business key. External ID unik per integration+entity; serial unik per item+ownership scope; active approval decision unik per step/version/approver. Index query wajib mencakup tenant/entity, business date, status dan stable sort key. Large ledger dipartisi berdasarkan bulan/period dan entity setelah profil volume; partisi tidak mengganti index/retention policy.

**History:** movement, journal, audit dan financial source disimpan append-only sesuai retention legal; koreksi berupa record baru. Master mempunyai effective-dated history. Audit before/after untuk PII disimpan masked/tokenized. Archive cold storage hanya setelah report/reconciliation dan legal hold diperiksa; restore diuji.

## 26. Financial posting matrix awal

Mapping akun bersifat konfigurasi per legal entity, tax code, item category dan accounting policy. Tabel ini menetapkan event dan arah debit/kredit; contoh angka ada di [keputusan G-02/G-03](decisions/mvp-business-policy.md), sementara aktivasi produksi tetap memerlukan mapping akun yang disetujui Controller.

| Source/trigger | Debit | Credit | Catatan |
|---|---|---|---|
| Goods Receipt accepted, invoice belum masuk | Inventory | GRNI (goods received not invoiced) | Cost snapshot; pajak mengikuti invoice/rule |
| Vendor Invoice matched | GRNI; Input Tax bila eligible | Accounts Payable | Price variance ke akun variance jika nilai beda |
| Vendor Payment posted | Accounts Payable | Bank/Cash | Fee bank dipisah |
| Sales Delivery dispatched | Inventory In Transit | Inventory Warehouse | Belum revenue/COGS untuk profil POD accepted |
| POD accepted + Sales Invoice issued | Accounts Receivable; COGS | Sales Revenue; Output Tax; Inventory In Transit | Finance Core mem-post source portion unik; accepted qty dan original cost snapshot |
| Customer Receipt posted | Bank/Cash | Accounts Receivable | Unapplied cash ke liability sampai dialokasikan |
| Settlement mata uang asing dengan beda kurs | AR/AP dan/atau Realized FX Loss | Bank dan/atau Realized FX Gain | Selisih dihitung dari FX snapshot original vs settlement |
| Sales Return accepted + Credit Memo | Sales Return/Output Tax; Inventory jika resellable | AR; COGS reversal | Rusak dapat masuk loss account |
| Purchase Return | GRNI/AP atau Vendor Claim | Inventory | Tergantung status invoice |
| Stock Adjustment loss/gain | Inventory Shrinkage atau Inventory | Inventory atau Inventory Gain | Approval dan cost snapshot |
| Intercompany transfer (fase lanjut) | Due-from / Inventory tujuan | Due-to / Inventory asal | Pajak dan eliminasi sesuai policy lokal |
| Expense/Reimbursement | Expense; Input Tax jika eligible | AP/Employee Payable/Bank | Cost center wajib jika policy |

**Control:** pada MVP Invoice+Accounting berada dalam satu Finance Core dan posting invoice+journal satu transaksi lokal: `ISSUED` berarti jurnal sudah posted; kegagalan posting me-rollback transaksi issue sehingga invoice tetap `DRAFT` dan nomor final tidak terpakai. Ketika Finance dan Accounting dipisah, tambahkan state eksplisit `POSTING_PENDING/POSTING_EXCEPTION`, saga/outbox, exception queue, dan reconciliation sebelum cutover; payment/aging/credit exposure tidak memperlakukan invoice pending sebagai posted. Jangan menampilkan invoice fully posted sebelum journal ada.

## 27. Budget, tax, currency dan cost model

Budget key=(entity, fiscal year/month, department, branch, cost center, account); proposal→approved version→active. Commitment pada PO approval, actual saat posting expense/GRNI sesuai policy, release otomatis saat cancel/close. Tidak ada double subtraction saat commitment berubah menjadi actual: keduanya bergeser atomik pada owner atau melalui event dengan unique source.

Tax rule key mencakup jurisdiction, tax type, party status, product class, transaction type, effective dates, inclusive/exclusive, exemption certificate dan rounding level. Baseline Indonesia nonmewah 12% × DPP 11/12; jenis khusus/mewah memerlukan rule eksplisit. Tax rate tidak di-hardcode; invoice menyimpan tax determination input/output. Withholding mengurangi cash payable hanya dengan klasifikasi dan bukti sah, bukan nilai expense otomatis. [Tax matrix G-04](decisions/mvp-business-policy.md#g-04--pajak-indonesia-dan-pembulatan).

Multi currency menyimpan original amount/currency, FX rate/source/time, base amount, realized/unrealized FX accounts. Revaluation period-end fase P3. Moving weighted average cost awal per legal entity+SKU+ownership; return memakai original outbound cost snapshot. Negative inventory dilarang agar cost tidak ambigu. Specific identification untuk barang tidak saling dipertukarkan memerlukan kelas valuasi tersendiri; perubahan metode cost tidak retroaktif. [Contoh G-02](decisions/mvp-business-policy.md#g-02--valuasi-persediaan-dan-waktu-cogs).

---

# Part 5 — Technical Architecture

## 28. System Architecture dan prinsip

`Web Next.js BFF / Flutter / integration client → Go API Gateway → domain APIs (Go) → PostgreSQL per owner`; `domain outbox → NATS JetStream → consumer inbox → projections/notifications/integrations`. Browser berbicara ke BFF Next.js dengan cookie session; BFF meneruskan request berizin ke Go Gateway. Redis untuk session/cache/rate limit; S3/MinIO untuk dokumen; OpenTelemetry untuk telemetry. Internal sync memakai REST/gRPC dengan deadline; event untuk side effect/projection. Semua ingress di-authenticate, authorize, rate-limit dan diberi request/trace ID. Tidak ada shared mutable business DB.

Go service memakai Clean Architecture: transport → application command/query → domain aggregates/policies → repository interfaces → PostgreSQL/broker adapters. Dependency injection eksplisit saat bootstrap; DDD untuk bounded context, bahasa domain, aggregate invariant. CQRS hanya untuk dashboard/search/report dengan read model berbeda; CRUD normal tetap satu model.

## 29. Microservice Architecture dan Service Responsibilities

| Deployable MVP | Modul di dalamnya | Alasan batas | DB/schema owner |
|---|---|---|---|
| Go Gateway | Routing API, auth enforcement, rate limit | Edge concern; tidak menyimpan transaksi | Config minimal |
| Identity & Platform | IAM, organization, master, pricing/tax/approval sederhana, dokumen metadata | Volume kecil, policy berkaitan; modul kode tetap terpisah | `identity`/`organization`/`master`/`policy` |
| Commercial | Sales, Purchase, Credit | Order commitment; stock via Inventory command | `sales`/`purchase`/`credit` |
| Operations | Inventory, WMS, transfer, goods receipt/delivery | Stock invariant dan physical flow lokal | `inventory`/`warehouse` |
| Finance Core | AR/AP, invoice, payment, Accounting/GL | Invoice→journal dan settlement→journal perlu transaksi lokal MVP | `finance`/`accounting` |
| Async Workers | Outbox relay, notification, import/export, reporting, integration | Worker dapat diskalakan | Schema per owner/job |

Satu deployable boleh memakai beberapa schema dengan repository boundary dan role DB per modul; cross-schema transaction hanya di Finance Core untuk posting MVP, sebagai pengecualian terdokumentasi. **Trigger pemisahan:** tim owner mandiri, throughput/availability berbeda, kontrak stabil, biaya konsistensi lintas service terukur. Customer/vendor/product/approval tidak dipisah hanya karena entitas berbeda.

Web BFF untuk browser berada pada Next.js `frontend/nextjs` dan mengelola sesi cookie server-side; Go Gateway tetap edge API untuk web BFF, mobile dan klien integrasi. BFF tidak menjadi pemilik aturan bisnis atau database domain.

**Enterprise scale candidate:** pisahkan IAM/Org, MDM, Sales, Purchase, Inventory/WMS, Finance, Accounting, Pricing/Credit/Approval, Integration, Reporting ketika trigger terpenuhi. Reporting memakai store analitik sendiri. Pemisahan Finance–Accounting memerlukan posting saga, exception queue dan reconciliation sebelum cutover. Gateway stateless; authn OIDC, authz dari policy service/cache pendek.

## 30. Service Communication dan database strategy

**Synchronous:** keputusan yang harus diketahui sebelum submit (customer block, price quote, credit check) memakai authenticated REST/gRPC, timeout dan request ID. Stock inquiry boleh sinkron sebagai indikasi saja. **Reservasi final setelah approval mengikuti saga async §32**; WMS hanya membuat task sesudah Inventory mengonfirmasi reservation. Retry hanya untuk command idempotent, exponential backoff+jitter, circuit breaker dan bulkhead. Dependency kritikal tak tersedia → pending/fail closed, tidak approve/ship dengan cache stale. **Asynchronous:** facts setelah commit lewat outbox→broker→inbox; consumer at-least-once dan idempotent.

| Pilihan DB | Kelebihan | Biaya/risiko | Keputusan |
|---|---|---|---|
| Database per service | Isolasi, independent deploy/backup | Operasi banyak DB, distributed transaction | Target enterprise |
| Schema per module dalam satu cluster | Operasi lebih ringan, local transaction | Blast radius cluster, privilege discipline | MVP dengan owner/schema/role ketat |
| Satu schema bersama | Mudah awal | Coupling dan cross-module query | Tidak dipilih |

Migration DDL dimiliki modul, backward compatible via expand→backfill→switch→contract. Read replica untuk query nonkritikal dengan lag terlihat. Stock/journal command membaca primary. Connection pool dan statement timeout dibatasi per service.

## 31. Broker choice dan Event Architecture

| Broker | Cocok untuk | Trade-off |
|---|---|---|
| NATS JetStream | Operational events/queue, durable stream, replay, consumer ack | Ecosystem analytics lebih kecil; inbox wajib |
| RabbitMQ | Work queue dan routing fleksibel | Replay/event log panjang kurang natural |
| Kafka | Throughput/retention besar, stream processing | Operasi/tuning lebih berat untuk MVP |

**Rekomendasi:** NATS **JetStream** untuk MVP dan pertumbuhan, durable replicated stream, explicit ack, DLQ/parking stream dan retention policy. Core NATS saja tidak persisten untuk critical events. Kafka dievaluasi bila volume/analytics butuh replay skala besar. [NATS JetStream memberi persistence dan at-least-once delivery](https://docs.nats.io/concepts/jetstream).

**Nama event:** `domain.aggregate.past_tense.v1`, contoh `sales.order.submitted.v1`; envelope: `event_id` UUIDv7, `aggregate_guid`, `aggregate_version`, `tenant_guid`, `legal_entity_guid`, `occurred_at` dan `recorded_at` UTC, `correlation_id`, `causation_id`, `schema_version` dan payload minimal. `occurred_at` adalah waktu aksi bisnis dari server tepercaya; `recorded_at` diisi database saat statement insert outbox dimulai. Outbox lag diukur dari `recorded_at` ke broker publish, dan consumer lag dari `recorded_at` ke pemrosesan. Event adalah fakta lampau, bukan command. Tambahan field optional; breaking change memakai v2 dan dual publish sementara.

| Domain | Event minimum |
|---|---|
| Master | `master.customer.created.v1`, `master.customer.blocked.v1`, `master.product.published.v1`, `master.vendor.updated.v1` |
| Sales | `sales.order.created.v1`, `sales.order.submitted.v1`, `sales.order.approved.v1`, `sales.order.cancelled.v1` |
| Purchase | `purchase.order.approved.v1`, `purchase.order.cancelled.v1` |
| Inventory/WMS | `inventory.stock.reserved.v1`, `inventory.stock.released.v1`, `inventory.movement.posted.v1`, `warehouse.goods_receipt.posted.v1`, `warehouse.delivery.shipped.v1`, `warehouse.delivery.accepted.v1`, `inventory.transfer.received.v1` |
| Finance/Accounting | `finance.invoice.issued.v1`, `finance.payment.received.v1`, `accounting.journal.posted.v1`, `accounting.period.closed.v1` |
| Policy | `approval.instance.requested.v1`, `approval.instance.decided.v1`, `pricing.rule.published.v1` |

Ordering hanya per aggregate/key via version check. Consumer yang melihat version gap park+fetch snapshot; duplicate diabaikan dengan unique `(consumer,event_id)` inbox. Transient retry backoff; permanent ke DLQ dengan alert. Relay outbox mengirim sampai broker ack; duplicate publish aman.

## 32. Distributed Transaction Strategy

**Order approval→reservation→delivery readiness:** Sales menyimpan `APPROVED_PENDING_RESERVATION` dan outbox dalam commit lokal. Orchestrator meminta Inventory reserve memakai `reservation_request_id` deterministik. Jika sukses, Inventory commit reservation+balance+outbox, kemudian Sales menjadi `ALLOCATABLE` dan WMS membuat pick task. Jika stok gagal, Sales menjadi `BACKORDERED` atau `RESERVATION_FAILED` sesuai policy; tak ada delivery. Jika credit check ulang gagal setelah reserve, saga mengirim release idempotent dan hold order. Compensation adalah command/event baru, bukan penghapusan.

**Crash scenarios:** reserve sukses namun response hilang → retry key sama mengembalikan reservation sama; event dua kali → inbox abaikan; order cancel saat reserve berjalan → expected version menolak transisi lalu release. Timeout berkepanjangan → `REQUIRES_RECONCILIATION`, tidak boleh ship. Reconciler membandingkan SO, reservation, delivery, invoice dan posting intent. Saga menyimpan state, attempt, deadline dan error.

**POD→invoice/journal:** Operations menyimpan accepted source portion, biaya outbound, dan outbox dalam transaksi lokal. Finance menunggu dispatch/in-transit posting untuk portion yang sama, lalu menerbitkan invoice dan jurnal AR/revenue/PPN/COGS sekali dalam transaksi lokal; event ack mengubah Delivery menjadi `DELIVERED`. Event terlambat/duplikat diparkir atau direplay idempotent; close periode memeriksa `POD_ACCEPTED_PENDING_FINANCE`, outbox, invoice dan journal yang belum rekonsiliasi. [Detail cut-off dan contoh angka](decisions/mvp-business-policy.md#g-03--kendali-barang-pendapatan-cut-off).

**Idempotency critical endpoints:** wajib untuk SO submit, PO approve, receipt post, reserve/release/consume, invoice issue, payment post, transfer ship/receive, journal post. Scope key=(tenant, actor/client, method, route/action, Idempotency-Key). Simpan body hash, response/reference dan expiry API 24–72 jam; key sama+body beda → 409. Unique business source constraint permanen melindungi setelah expiry. Key dan result disimpan dalam local transaction bila memungkinkan; in-progress request mengembalikan 409/202 dan status URL. DB uniqueness/version adalah pengaman akhir, bukan Redis lock.

## 33. API Strategy dan kontrak awal

External REST JSON di `/api/v1`. OpenAPI 3.x menjadi kontrak source-of-truth per bounded context; Postman collection memuat request, contoh, dan assertions untuk uji lintas layanan. Internal gRPC hanya untuk hot path terukur dengan protobuf versioning; jangan menduplikasi semua REST.

| Method/path | Tujuan dan perilaku |
|---|---|
| `GET /api/v1/sales-orders` | List scoped, filter, sort, cursor/page |
| `POST /api/v1/sales-orders` | Create draft, idempotency recommended |
| `GET /api/v1/sales-orders/{guid}` | Detail dengan version/ETag |
| `PATCH /api/v1/sales-orders/{guid}` | Perubahan parsial draft dengan `If-Match` |
| `PUT /api/v1/sales-orders/{guid}` | Replace draft lengkap bila kontrak mendukung; PATCH lebih umum |
| `POST /api/v1/sales-orders/{guid}/submit` | State transition dengan aturan domain |
| `POST /api/v1/sales-orders/{guid}/approve` | Approval decision, bukan PATCH status |
| `POST /api/v1/sales-orders/{guid}/cancel` | Reason wajib dan version check |
| `POST /api/v1/goods-receipts/{guid}/post` | Movement idempotent |
| `POST /api/v1/payments/{guid}/post` | Settlement/journal idempotent |

`DELETE` hanya untuk draft/master yang boleh dihapus; posted transaction memakai action endpoint. `PATCH` untuk ubah representasi tanpa workflow; `POST /{guid}/action` untuk transisi yang memicu side effect. Jangan menerima `PUT status=APPROVED` sebagai jalan pintas. Command mengembalikan current state/version atau `202 Accepted` + operation URL bila async.

**List standard:** `page` ≥1, `page_size` default 25 max 200, `search`, allowlisted `sort` dan `order=asc|desc`, `start_date`, `end_date`, `timezone` IANA, `branch_guid`, `status`, `legal_entity_guid`. Date range berarti business date kecuali parameter menyebut `created_at`. Response `data` dan `meta{page,page_size,total?,next_cursor?,as_of}`. Untuk volume tinggi gunakan cursor stable (sort_value,id); total count opsional/async. Sort/filter diparameterisasi dan allowlisted.

**Error standard:**

```json
{
  "success": false,
  "code": "SALES_ORDER_CREDIT_LIMIT_EXCEEDED",
  "message": "Customer credit limit exceeded",
  "details": {"customer_guid": "…", "exposure": "12500000.00"},
  "request_id": "019…"
}
```

Kode `DOMAIN_RESOURCE_REASON` uppercase, contoh `INVENTORY_RESERVATION_INSUFFICIENT_STOCK`. HTTP 400 malformed, 401 unauthenticated, 403 unauthorized, 404 absent/out-of-scope (anti-enumeration), 409 conflict/key mismatch, 412 stale ETag, 422 domain validation, 429 quota, 503 dependency unavailable. Details tidak memuat PII tanpa izin; request_id selalu ada. Error catalog mencantumkan retryability.

**Security/performance contract:** OAuth2/OIDC token dengan audience/scopes; service-to-service workload identity + mTLS bila platform mendukung; schema validation, size limit, rate limit per principal, max query cost, audit action sensitif. Outbound webhook signed HMAC dengan timestamp+event ID, retry exponential, replay window; inbound memverifikasi raw body signature.

## 34. Integration Architecture

Adapter per provider (bank, payment gateway, marketplace, e-commerce, logistics, tax, CRM, external ERP) menerjemahkan canonical command/event. Anti-corruption layer menyimpan external ID, schema version, mapping dan reconciliation status. Near-real-time via REST/webhook, bulk via import job/event. Inbound update wajib idempotent dan menyimpan provenance; financial input masuk staging/match queue sebelum posting. Outbound webhook punya subscription, secret rotation, delivery log, retry, DLQ dan manual replay berizin.

## 35. Cache, search dan background jobs

**Redis:** OIDC session metadata/revocation, rate-limit counter, short-lived master/permission projection, distributed lock untuk koordinasi non-kritis, job progress. Namespace tenant, TTL, version key dan invalidation event wajib. Cache miss menuju owner. Stock available, credit exposure, approval final, period status dan journal balance tidak diputuskan dari cache stale. Redis lock bukan pengganti DB constraint/row lock.

**Search:** PostgreSQL full-text/trigram dengan scoped indexed query pada MVP/P2; PII dan branch filter sebelum hasil. OpenSearch hanya jika relevansi, volume, faceting atau latency terukur melampaui PostgreSQL; index eventual dan UI menampilkan freshness. Hasil search bukan sumber keputusan stock/credit.

**Workers:** report generation, CSV/XLSX import, email/push, integration sync, aging materialization, recurring journal (P3), expiry reclassification, stock reconciliation. Job punya unique key, attempts, deadline, progress, checkpoint, cancel policy, DLQ dan retention; posting domain tetap via owner command. Scheduler leader election/DB advisory lock menghindari double run; job action tetap idempotent.

## 36. Web Architecture dan UX

Next.js 16.x + TypeScript, React, **shadcn-admin MIT** sebagai acuan shell/design tokens/komponen presentasi yang diadaptasi dari Vite ke Next.js, Tailwind, TanStack Query/Table, React Hook Form, Zod. Versi dependency dipin dalam lockfile setelah adaptasi dan smoke build. ERP membungkus komponen vendor di UI wrapper milik repo; contoh auth/database vendor tidak dipakai. SSR untuk shell, auth-aware landing, initial view bila membantu TTFB; transaction grids/forms sebagai client components. Server memvalidasi ulang semua input. Query cache keyed by tenant/entity/scope dan diinvalidasi setelah command; switch entity menghapus privileged cache lama. Zustand hanya untuk UI state lintas halaman yang tidak cocok URL/query cache; Redux Toolkit bila domain client state kompleks benar-benar dibutuhkan. Server/business state tetap di API/TanStack Query. Detail keputusan template ada di [ADR-0005](adr/0005-shadcn-admin-frontend.md); keputusan Echo/Next.js tetap pada [ADR-0003](adr/0003-echo-metronic.md).

Layout: sidebar modul permission-based, top nav, breadcrumb, global search, notification, user/entity switcher, approval inbox. Modul punya list/detail/create/edit/approval/history/attachment/audit; table mendukung filter/sort/pagination/saved view/export/import/bulk action dengan preview/confirmation dan permission check. Dynamic forms memakai metadata versioned, field kritikal tetap divalidasi server. Responsive tablet, keyboard navigation, focus state, aria labels, localization, currency/date/timezone formatting. Role dashboard: Executive revenue/gross profit/cash/AR/AP; Sales Manager target/order/conversion; Warehouse Manager fill rate/backlog/expiring; Finance Manager aging/closing; Salesman route/visit/order; Approver pending/SLA.

## 37. Mobile Architecture dan Offline Sync Strategy

Flutter/Dart, encrypted SQLite local DB, secure keystore untuk token, background sync sesuai batasan OS, push, camera/barcode/QR, GPS dengan consent, foto dan signature/POD bila perlu. Mobile module: salesman route/customer/product/price snapshot/visit/order draft; supervisor KPI/approval online; warehouse receive/pick/scan online-first dengan queue terbatas; driver delivery/POD offline terkontrol; approver inbox/decision online. Journal, policy admin, bulk import dan financial close tetap web.

Local record: `local_id` UUID, `server_guid` UUID nullable, `sync_status`, `local_version`, `server_version`, `last_sync_at`. Pull delta per (tenant,user,scope,collection) cursor; push command berurutan per aggregate dengan idempotency key. At-least-once send + server dedup. Conflict: server wins untuk master/price/stock/credit/status; note/visit dapat merge bila field berbeda; same-field conflict → `NEEDS_REVIEW` dengan diff/pilihan user; posted record tidak overwrite. Scope revoke menghapus local restricted cache pada next online; offline data TTL asumsi 7 hari dan device encryption. Retry exponential+jitter, network/battery-aware, foto upload limit; cursor maju setelah batch commit. Uji restart, duplicate, token expiry, clock skew, role/price/stock/customer change, putus tengah upload.

---

# Part 6 — Security, DevOps & Observability

## 38. Security Requirements dan data security

**Identity:** OIDC untuk user login, OAuth2 Authorization Code + PKCE untuk web/mobile, client credentials/workload identity untuk service dan integration client. Access JWT berumur pendek (asumsi 5–15 menit), audience/service scopes dan signature diverifikasi; refresh token rotation, reuse detection, per-device session, revoke/logout all. Password lokal hanya bila IdP tidak tersedia: Argon2id dengan parameter terukur, MFA untuk privileged roles, brute-force rate limiting, lockout bertahap dan recovery audit. Biometric mobile membuka secure local credential, bukan mengganti server auth.

**Authorization:** RBAC permission granular + ABAC untuk legal entity, branch, warehouse, department, ownership, value threshold, state dan SoD. Permission UI hanya menyesuaikan navigasi; API memutus akses setiap command/query. Break-glass timeboxed, dual approval, alert audit. Delegation memiliki scope, reason, effective range dan revoke; service accounts paling sedikit haknya. Pengujian eksplisit untuk IDOR, horizontal/vertical privilege escalation dan direct URL.

**App/API controls:** parameterized SQL, output encoding dan CSP, secure headers, CSRF defense untuk cookie-based sessions, SameSite/HttpOnly/Secure, request body limits, allowlist upload, SSRF protection pada webhook/download, schema validation, security scanning dependency/image/secret, signed artifact dan SBOM. Threat model O2C/P2P/payment/offline diperbarui tiap perubahan boundary. Gunakan [OWASP ASVS 5.0](https://asvs.owasp.org/) sebagai baseline verifikasi web/API dan [OWASP MASVS](https://mas.owasp.org/MASVS/02-Frontispiece/) untuk mobile; kontrol dipetakan ke test dan evidence saat desain detail.

**Data:** TLS 1.2+ pada ingress dan internal traffic, mTLS antarlayanan bila platform mendukung; encryption at rest pada DB, backup, object storage dan device; KMS-managed key dan rotation. Bank account, tax ID, salary, PII dienkripsi/tokenisasi tingkat field sesuai klasifikasi; masking di UI/log/export. Field salary hanya jika modul HR dikembangkan. Export PII memerlukan alasan, permission dan audit. Retention matrix ditetapkan per data class/jurisdiction; legal hold mengalahkan purge. Purge menghapus cache, export yang kedaluwarsa, object version dan local device data menurut kebijakan; immutable financial record dimasking bila penghapusan identitas sah.

## 39. Audit Requirements

Audit event minimum: `event_id`, actor/service/delegator GUID dan type, action, module, entity type/guid, legal entity/scope GUID, previous/new redacted values, occurred_at/recorded_at UTC, IP, user agent/device, request_id, correlation_id, trace_id, reason, policy version, outcome. Cakup login gagal/sukses, role/scope/config changes, approval, harga/kredit override, stok, finance, import/export, document download, period reopen dan break-glass. Audit terpisah dari app log, append-only; akses baca dibatasi, admin aplikasi tidak bisa menghapus. Tamper evidence melalui hash chain per partition/batch + signed daily digest ke immutable object storage; restore dan sampling verifikasi bulanan. Retention audit mengikuti legal policy, bukan TTL cache. PII di before/after disamarkan, nilai sumber tetap dapat ditelusuri melalui izin khusus.

## 40. Logging & Observability

Log JSON structured dan UTC. Contoh:

```json
{"timestamp":"2026-10-28T06:00:00Z","service":"commercial","level":"INFO","request_id":"019a2439-0000-7000-8000-000000000001","trace_id":"4bf92f3577b34da6a3ce929d0e0e4736","correlation_id":"019a2439-0000-7000-8000-000000000002","tenant_guid":"019a2439-0000-7000-8000-000000000003","legal_entity_guid":"019a2439-0000-7000-8000-000000000004","actor_guid":"019a2439-0000-7000-8000-000000000005","event":"sales.order.submitted.v1","entity_guid":"019a2439-0000-7000-8000-000000000006","duration_ms":87}
```

Jangan log password, token, bank number, tax ID, salary, full payload atau stack trace yang berisi PII. Pseudonymous ID boleh dengan retention. OpenTelemetry trace context diteruskan web/mobile→gateway→service→broker worker; correlation_id untuk saga bisnis, request_id untuk HTTP request, trace_id untuk satu execution trace. Metrics: API p50/p95/p99, 4xx/5xx, DB pool/slow query/replica lag, broker backlog/oldest age/DLQ, outbox lag, stock reservation conflicts, posting exceptions, mobile sync conflict, report queue, backup success. Stack contoh Prometheus/Grafana, Loki, Tempo/Jaeger. Dashboard dan alert berbasis SLO; alert harus menunjuk owner/runbook, bukan hanya CPU.

## 41. Data Migration

**Tahap:** extract (Excel/CSV/legacy DB read-only) → profile/clean (duplikasi, UOM, alamat, tax, currency, opening balance) → canonical mapping + lineage → dry-run validate → load master → load opening stock/AR/AP/GL dengan source tags → reconcile → UAT sign-off → cutover freeze → delta load → post-cutover monitor. Setiap batch punya source hash, template version, row status dan rollback plan. Data historis yang tidak dibutuhkan operasional dapat diarsipkan read-only dengan search/link, bukan dipaksa menjadi transaksi baru.

**Reconciliation gates:** count dan checksum per entity, SKU/warehouse/batch quantity, inventory value vs GL, AR/AP aging vs control accounts, trial balance debit=credit, open PO/SO qty, customer/vendor mapping. Tolerance selisih moneter ditetapkan Controller; selisih tak terselesaikan masuk exception ledger dengan owner dan tanggal. Opening journal dan stock movement diberi migration source ID unik; rerun idempotent. Cutover rehearsal minimal dua kali, salah satunya memakai volume produksi. Rollback cutover didasarkan pada titik stop transaksi; setelah ERP menerima posting nyata, rollback data memerlukan compensating process, bukan restore sepihak.

## 42. DevOps, configuration dan feature flags

**Git:** trunk-based dengan short-lived feature branches, PR review, protected main, semantic tags, release branch hanya untuk hotfix terkendali. CI memeriksa format/lint, unit/integration/contract, dependency/secret scan, SAST, image scan, migration compatibility, OpenAPI breaking change, build image immutable; CD deploy DEV→STAGING→UAT→PRODUCTION dengan evidence, approval operasional untuk production dan canary/blue-green sesuai layanan. Environment config divalidasi saat startup, secrets dari vault/KMS, tidak di repo/log.

**Migration DB:** expand→backfill→switch→contract, migration terurut dan reproducible; destructive step setelah semua binary lama lepas. Rollback aplikasi memakai image versi sebelumnya selama schema tetap kompatibel; data correction memakai forward migration/compensation. Feature flags seperti `new_pricing_engine`, `new_approval_flow`, `mobile_offline_order` mempunyai owner, scope tenant/entity, start/end, fallback, audit dan cleanup date. Flag tidak boleh melewati invariant atau mengubah ledger historis. Config versioned per entity untuk approval threshold, credit, tax, numbering, warehouse policy, payment term, discount, notification; publish dengan policy simulation, dual approval untuk finansial dan rollback version baru (bukan edit versi lama).

## 43. Deployment Architecture

DEV lokal dengan Docker Compose: Go deployables, PostgreSQL, Redis, NATS JetStream, MinIO dan telemetry ringan; seeded synthetic data, bukan data produksi. STAGING/UAT/PRODUCTION terisolasi jaringan, secrets, database dan broker. Production Kubernetes bila kebutuhan HA/skala/operasi memadai: ingress/LB+WAF → gateway replicas → stateless services autoscaled → managed/HA PostgreSQL, Redis, JetStream, object storage; workers terpisah menurut queue. IaC dan GitOps/approved CD, resource requests/limits, readiness/liveness/startup probes, pod disruption budgets, network policy, egress allowlist, TLS certificate automation. Container image dipin digest dan non-root. Jangan memaksakan Kubernetes untuk pilot bila platform operasi belum siap; single-node Docker Compose bukan topologi HA production.

## 44. High Availability

Target awal production: **99,9% monthly availability** untuk core transaction API (asumsi; mengecualikan maintenance terjadwal yang disepakati). Minimal dua replicas untuk stateless service di zona berbeda bila tersedia, LB health checks, PostgreSQL primary+streaming standby, WAL archive/PITR, Redis HA untuk cache/session, JetStream 3-node replicated stream, object storage redundant. Critical command tidak bergantung pada read replica. Capacity planning dimulai dari 100–1.000 concurrent users dan load profile nyata; scale out stateless/worker, partition/read model/DB tuning sebelum pemecahan service. 10.000+ users adalah arah desain dan harus dibuktikan ulang dengan load test.

## 45. Backup & Disaster Recovery

Target awal **RPO ≤15 menit, RTO ≤4 jam** untuk core transaction (asumsi SLA yang harus disetujui); DR di region kedua bila pelanggan menuntut. Full backup harian + continuous WAL archiving, snapshot object store/config/secrets metadata, broker stream backup/replay plan, backup encrypted dan immutable dengan retention 30/90/365 hari sesuai policy. Restore diuji bulanan untuk DB acak dan DR drill end-to-end minimal dua kali setahun. Runbook menyebut failover, split-brain prevention, DNS/client retry, restore order (identity→master→inventory→commercial→finance), outbox replay dan reconciliation stock/GL setelah pemulihan. Bukti RPO/RTO diukur dari drill, bukan hanya konfigurasi backup.

## 46. Technical & Business Risks serta mitigasi

| Risiko | Dampak | Mitigasi/owner |
|---|---|---|
| Microservice over-engineering / distributed transaction | Delivery lambat, status menggantung | Modular deployable MVP; saga hanya lintas owner; Architecture Lead |
| Inventory race, oversell, double reserve, negative stock | Hilang penjualan/kesalahan valuasi | Row lock, unique source key, invariant, concurrency test, reconciliation; Inventory Lead |
| Duplicate event/payment/receipt atau partial failure | Double posting | Outbox/inbox, idempotency, unique business key, compensation, exception queue; Domain Leads |
| Deadlock/lock contention | Latency dan timeout | Urutan lock tetap, bounded retry, observability; DB Lead |
| Stale cache/search/projection | Keputusan salah atau dashboard beda | Owner authoritative untuk command; TTL/version/freshness; Platform Lead |
| Offline conflict/data leakage | Order salah, PII di perangkat | Encrypted local DB, TTL, server revalidation, remote revoke, conflict UI; Mobile Lead |
| Timezone/DST/backdate | Salah period/due date | UTC instant + IANA business date, period tests, backdate policy; Finance Lead |
| Financial rounding/FX mismatch | Trial balance/AR selisih | Decimal, snapshot rate, rounding policy, property tests, recon; Controller |
| Stock/GL reconciliation drift | Closing terhambat | Daily source-to-ledger control, variance queue, immutable trail; Controller |
| Low master data quality/migration | Go-live gagal | Profiling, steward, dry-run, reconciliation gate; Data Lead |
| Tax/legal policy berubah | Dokumen tidak patuh | Config versioning, local tax review, effective dates; Tax Lead |
| Approval bottleneck/SoD conflict | Proses macet | Delegasi aman, SLA escalation, policy simulation, exception owner; Process Owner |
| Vendor integration instability | Payment/delivery status tertunda | Adapter isolation, retries, circuit breaker, manual reconcile; Integration Lead |
| Adoption/training | Workaround spreadsheet | Pilot cabang, champion, help content, task telemetry; Product Lead |

## 47. Dependencies dan keputusan eksternal

Go-live bergantung pada: chart of accounts dan posting mapping ditandatangani Controller; SKU/UOM/customer/vendor dibersihkan; warehouse/bin dan stock opening dihitung; credit/discount/approval/tax policy per legal entity diaktifkan; IdP, email/push, object storage, bank/marketplace API credentials tersedia; jadwal retensi baseline dan region Indonesia diverifikasi Legal/Security; device scan/camera diuji di lapangan; tim operasi mampu backup/restore dan incident response. Dependency eksternal diberi owner, due date, status, fallback dan evidence di delivery plan.

---

# Part 7 — Non Functional Requirements

## 48. NFR terukur

Seluruh target berlaku pada workload profil pilot yang disepakati, data volume representatif, warm-up dan jaringan terukur; pengukuran dilaporkan per endpoint/role/tenant, bukan rata-rata global yang menyembunyikan tail latency.

| ID | Kategori | Target/acceptance | Prioritas |
|---|---|---|---|
| NFR-PERF-01 | API latency | p95 simple read/write <300 ms; p95 complex query/command <1 s, tidak termasuk integrasi eksternal yang async | MUST/MVP |
| NFR-PERF-02 | Report | Interaktif <5 s untuk agregat terindeks; report berat async dengan status/progress; target penyelesaian per report ditetapkan | MUST/MVP |
| NFR-SCALE-01 | Concurrency | 100–1.000 concurrent users fase awal dengan workload O2C/P2P/stock; rencana kapasitas menuju 10.000+ diuji bertahap | MUST/MVP |
| NFR-AVAIL-01 | Availability | 99,9% bulanan core API setelah stabilisasi, terukur dari synthetic + server metrics | MUST |
| NFR-REL-01 | Reliability | Tidak ada stock negatif, duplicate posted journal/payment/receipt pada retry/concurrency suite; DLQ terpantau | MUST |
| NFR-SEC-01 | Security | Semua endpoint punya authn/authz/scope tests; temuan critical/high sebelum production nol atau exception bertanda tangan | MUST |
| NFR-DATA-01 | Integrity | Daily stock balance vs movement, subledger AR/AP vs control account, trial balance debit=credit; exception punya owner/SLA | MUST |
| NFR-AUD-01 | Auditability | 100% privileged/financial/stock transition memiliki actor/source/reason/correlation dan dapat dicari sesuai hak | MUST |
| NFR-REC-01 | Recoverability | RPO ≤15 min dan RTO ≤4 h terbukti pada DR drill | MUST |
| NFR-OBS-01 | Observability | trace end-to-end untuk ≥95% sampled critical flows, setiap alert punya owner/runbook, PII tidak bocor log | MUST |
| NFR-MAIN-01 | Maintainability | Kontrak OpenAPI, ADR boundary, migration dan runbook diperbarui pada perubahan; coverage fokus invariant, bukan angka buta | MUST |
| NFR-INT-01 | Interoperability | API v1 versioned, webhook schema/signature, import template versioned, contract compatibility gate | MUST |
| NFR-UX-01 | Usability | 90% pilot users menyelesaikan skenario top-5 tanpa bantuan setelah training; time-on-task baseline dan feedback tercatat | SHOULD |
| NFR-ACC-01 | Accessibility | Web target [WCAG 2.2 AA](https://www.w3.org/TR/WCAG22/); keyboard, focus, label, contrast dan screen reader diuji pada alur kritikal | SHOULD/MVP |
| NFR-I18N-01 | Locale | Bahasa Indonesia dan English UI; currency, decimal, date, timezone sesuai locale; user-entered code tetap stabil | SHOULD/P2 |
| NFR-MOB-01 | Offline | Draft tidak hilang setelah restart; valid command sinkron ≥95% dalam 15 min setelah koneksi stabil; konflik terlihat | SHOULD/P2 |

**Capacity model awal:** uji campuran 50% read list/detail, 20% search/report ringan, 20% command sales/purchase, 10% stock/finance; peak 3× rata-rata jam sibuk. Dataset sintetis minimal 1 juta SKU-stock keys/10 juta movements dan 5 juta order lines untuk uji strategi indeks/partition sebelum klaim 10.000+ users. Angka ini target eksperimen, bukan estimasi pasti kapasitas hardware. Performance budget per hop dan query plan dicatat; penambahan replica tidak menyelesaikan lock hotspot.

## 49. Testing Strategy

| Lapisan | Bukti wajib |
|---|---|
| Go unit/domain | State transition, price/tax/credit/stock formula, UOM, decimal rounding, period rules, SoD; property tests untuk invariant |
| Go integration | PostgreSQL transaction/locks/constraints, outbox/inbox replay, Redis fallback, broker duplicate/out-of-order, object storage |
| API contract | OpenAPI schema compatibility, saved request assertions (Postman bila dipakai), auth/scope, idempotency, error codes, pagination |
| Cross-service E2E | O2C, P2P, transfer, R2R dengan partial, cancel, retry, compensation, exception/reconciliation |
| Web | Component/form/table/accessibility tests, Playwright untuk alur kritikal dan role/scope switching |
| Mobile | Dart unit, Flutter widget, integration pada device; offline restart/sync/conflict, camera/scan/GPS/permission |
| Security | SAST/DAST, dependency/secret scan, pentest sebelum go-live, ASVS/MASVS evidence dan authorization matrix |
| Load/chaos | k6 scenario 100/1.000 user, soak dan spike; kill worker, DB failover, broker delay, network loss, duplicate event |
| Migration/DR | Dry-run data reconcile, cutover rehearsal, point-in-time restore, measured RPO/RTO |

**Exit gate minimum:** semua MUST acceptance test lulus; stock/GL reconciliation nol unresolved critical; no high/critical security issue tanpa formal exception; performance memenuhi p95 untuk workload pilot; restore drill dan incident runbook lulus; UAT process owners menandatangani O2C/P2P/R2R. Test data sintetis/anonymized, tidak menyalin PII produksi mentah ke DEV.

## 50. Reporting & Analytics

Reporting membaca event-driven projection atau read replica yang diizinkan, tidak mengunci primary transaction. Setiap metric punya definisi, owner, grain, source, as-of dan filter legal entity/currency. Cross-currency executive total memakai reporting currency dan FX policy, menampilkan kurs/as-of; nilai native tetap dapat drill-down. Scheduled reports P3 memiliki recipient scope snapshot, export encryption dan expiry.

| Dashboard/report | Definisi ringkas dan drill-down | Refresh target |
|---|---|---|
| Executive revenue/gross profit | Net invoiced revenue minus returns; gross profit = revenue−COGS; drill invoice/journal | ≤15 min P2; close report as-of |
| Sales by branch/product/customer/salesman/area | Net invoice/fulfilled sales dengan attribution snapshot pada order | ≤15 min |
| Sales growth/target/effective call | Periode komparasi kalender/fiscal; effective call = visit dengan outcome yang didefinisikan Sales Ops | Harian |
| Inventory value/aging/turnover | Qty × valuation cost; age dari receipt/last movement policy; turnover = COGS/average inventory | Harian |
| Slow/fast/dead/expiring stock | Threshold configurable per category; expiry berdasarkan business date warehouse | Harian + low-stock alert near-real-time |
| AR/AP aging | Open item as-of dengan due-date bucket configurable (current, 1–30, 31–60, 61–90, >90) | ≤15 min, period close exact |
| Cash position | Posted bank/cash balance; unposted bank feed terpisah | ≤15 min |
| Trial balance, P&L, balance sheet, cash flow | Sumber posted journal saja; financial statement mapping berversi, as-of period | On demand/close |

Exports CSV/XLSX/PDF memakai permission + row/size limit, masking, watermark untuk sensitif, audit download dan async untuk >threshold. CSV escape formula-leading cells. Data lineage menampilkan source document dan journal ID; report menandai late event/projection lag.

## 51. Performance, failure dan consistency budgets

Critical command menetapkan deadline end-to-end; 503/202 dengan operation status jika dependency melebihi budget, tanpa ambiguous success. Event lag SLO awal p95 <30 detik untuk notification/report projection; accounting posting MVP lokal. Outbox oldest age >2 menit dan DLQ >0 critical memicu alert. Reconciliation harian membandingkan ledger vs balance; klaim stok/GL di dashboard memuat as-of. Load test meliputi hotspot satu SKU (flash order), banyak branch, large order lines, concurrent receipt+reservation, period close, bulk import dan expired lot. Circuit breaker melindungi upstream; fallback hanya untuk read nonkritikal. Kebijakan retry: jitter, max attempts, no infinite loop, operator-visible terminal failure.

## 52. Release and operational readiness gates

Setiap release memiliki migration plan, rollback/roll-forward, feature flag owner, contract compatibility, capacity estimate, monitoring dashboard, alert/runbook, security review untuk surface baru, QA evidence dan UAT sign-off. Launch bertahap per pilot branch/legal entity, lalu ramp menurut metrik error/latency, reconciliation dan support ticket. Stop/go threshold: no ledger mismatch unexplained, no double posting, no negative stock, p95 dan 5xx dalam SLO, backup terakhir valid. Insiden sev1 menghentikan posting berisiko via flag/maintenance mode yang tidak menyembunyikan status transaksi; recovery melalui reconciliation sebelum resume.

---

# Part 8 — MVP & Roadmap

## 53. MVP Definition dan prioritas MoSCoW

**MVP = satu vertical slice beroperasi untuk satu legal entity dan beberapa branch/warehouse**, dengan model multi entity sejak awal. Pilot membuktikan O2C, P2P dan R2R pada stok serta angka keuangan yang direkonsiliasi; bukan sekadar CRUD modul. Volume/user pilot dibatasi agar operasi support mampu menangani exception. Setiap MUST yang tercantum di bawah adalah release gate.

| Capability MVP | Cakupan minimum yang harus siap | Yang ditunda |
|---|---|---|
| Foundation | Tenant/legal entity/branch/warehouse, IAM RBAC+scope, OIDC, audit, numbering, config versioning, document storage | ABAC kompleks, self-service policy designer |
| Master | SKU/UOM/conversion, customer/vendor, price/tax dasar, import CSV dengan preview, employee reference | Variant matrix kompleks, bulk XLSX besar |
| Sales | SO multi-line, customer/credit validation, fixed approval policy, reservation/backorder, basic pick/pack/delivery | RFQ sales, promo advanced, route planning |
| Purchase | PR sederhana, PO approval, partial goods receipt, vendor invoice matched | RFQ comparison, contracts, blanket PO |
| Inventory/WMS | Movement ledger, balance, batch/expiry policy, reservation, receiving/picking/dispatch, adjustment approved | Wave picking, bin optimization, intercompany transfer |
| Finance/GL | Sales/vendor invoice, partial customer/vendor payment, AR/AP aging, COA, auto-journal, GL, trial balance, basic P&L, period lock | Cash-flow statement lengkap, FX revaluation, advanced bank reconcile |
| Platform | REST v1, OpenAPI per domain, outbox/inbox, JetStream, notification in-app/email dasar, role dashboards dasar, observability/backup | Marketplace/bank integration, scheduled report |
| Web/Mobile | Responsive web untuk semua MVP tasks; mobile online read/visit pilot opsional | Offline order production dan mobile WMS advanced |

**Prioritas:** MUST menjaga integritas end-to-end; SHOULD berikutnya meningkatkan efisiensi; COULD diputuskan dari pilot metrics; WON'T pada MVP tercatat di §10. Approval minimal tetap ada karena PO/SO/adjustment/payment tidak boleh melewati SoD. Accounting minimal tetap ada agar invoice dan stock value tidak menjadi utang teknis data. Batas UI dan workflow boleh sederhana selama invariant, audit, dan exception handling selesai.

## 54. Product Roadmap

| Tahap | Sasaran dan fitur | Exit evidence |
|---|---|---|
| Foundation (milestone M0–M2) | Discovery policy, domain glossary, IAM/org/master, tax/price/approval dasar, platform, CI/CD, migration tooling | Master sample valid, authz matrix, contract/API skeleton, restore awal |
| MVP vertical slice (milestone M3–M6) | O2C+P2P+stock/WMS sederhana+AR/AP/GL, audit, CSV import, dashboards dasar, pilot satu entity | O2C/P2P/R2R E2E dan UAT lulus, stock/GL reconcile, NFR pilot |
| Phase 2 Operations (setelah pilot) | RFQ/vendor compare, returns/credit memo, transfers parsial, bin/wave, sales route/visit, mobile offline order, push, expanded reports | Multi branch rollout, offline sync metrics, transfer reconciliation |
| Phase 3 Enterprise Controls | Approval parallel/escalation/delegation, budget, advanced promotion, bank reconcile, FX/revaluation, scheduled report, external adapters, intercompany | Control owner sign-off, no unresolved ledger mismatch, integration contract tests |
| Enterprise Expansion | Manufacturing/POS/TMS extensions, advanced analytics/forecasting/AI, dedicated reporting store, selective service splits | Separate business case, historical data quality and scalability proof |

**Batas desain implementasi final:** [FSD-EXP](roadmap/enterprise-expansion-fsd.md) menetapkan discrete assembly ringan, POS online, TMS milestone, analytics/forecasting sebagai rekomendasi, reporting store, dan service split hanya bila metrik menuntut. Business case pada tabel adalah gate investasi/aktivasi, sementara baseline FSD/API/data/UX/QA sudah cukup untuk memulai kode terhadap fixture sintetis. Kebutuhan di luar batas itu memerlukan perubahan PRD, bukan asumsi implementer.

Urutan milestone **bukan komitmen tanggal**; estimasi jadwal dibuat setelah sizing backlog dan mengasumsikan 3 product squads (Commercial, Operations, Finance/Platform), QA/SRE/Security shared, process owners tersedia, dan master/COA disetujui tepat waktu. Tanpa itu, replan scope/date berdasarkan dependency dan critical path. Pilot memakai satu entity namun skema, permission dan API mengandung legal entity sejak hari pertama.

## 55. Milestone dan deliverables

| Milestone | Artefak dan bukti penerimaan | Owner |
|---|---|---|
| M0 Discovery sign-off | Process maps, data profiling, COA, costing/tax/credit policy, open decisions ditutup untuk MVP | PM + Process Owners |
| M1 Architecture baseline | ADR service/data/event/API, threat model, NFR test plan, OpenAPI draft, UX flows | Architect + Security |
| M2 Foundation ready | IAM/org/master/config, seed dan migration tool, audit, CI/CD, backup restore proof | Platform Lead |
| M3 Stock/control ready | Ledger/reservation/receipt/adjustment, concurrency/reconcile tests, WMS pilot | Operations Lead |
| M4 O2C/P2P ready | SO→delivery→invoice→receipt dan PR→PO→GRN→AP→payment E2E | Commercial + Finance |
| M5 UAT/cutover | Data rehearsal, staff training, security/perf/DR gates, support runbooks, signed reconciliation | QA + Controller + Ops |
| M6 Pilot go-live review | 2–4 minggu hypercare, KPI baseline/target, defects dan rollout decision | Product + Sponsor |

## 56. Definition of Ready

Sebuah story siap build bila: actor/value dan owner jelas; legal entity/scope/permission ditentukan; precondition, main/alternative/exception flow, state transition, idempotency dan audit didefinisikan; data/API/event contract atau perubahan version dicatat; UI wireframe/empty/error/loading state tersedia bila perlu; tax/accounting impact diputuskan Controller untuk financial flow; acceptance Given/When/Then dan test data termasuk concurrency/duplicate failure tersedia; dependency dan feature flag/cutover risk teridentifikasi. Story yang menyentuh keputusan terbuka berstatus `BLOCKED_FOR_DECISION`, bukan ditebak saat coding.

## 57. Definition of Done

Kode direview dan sesuai arsitektur; unit/integration/contract/E2E relevan lulus; authorization matrix dan audit event terbukti; migration reversible/forward-fix plan; OpenAPI, event schema, FSD/ADR, UI help, runbook dan dashboards diperbarui; observability menampilkan failure path; performance/security checks sesuai risiko; data reconciliation lulus bila menyentuh stock/finance; UAT process owner menerima flow; flag/rollback dan deploy evidence tersedia. Tidak ada P0/P1 defect terbuka dan exception yang tersisa punya owner, severity, tanggal penyelesaian.

## 58. Open Questions dan decision register

OQ-01–OQ-06 telah memiliki baseline desain dalam [keputusan bisnis MVP](decisions/mvp-business-policy.md), sehingga tidak lagi memblokir rancangan kode. Angka dan profil legal entity harus diaktifkan melalui approval pemilik proses sebelum transaksi produksi. Pertanyaan lain tetap memiliki fase dan owner seperti tercantum; perubahan keputusan memperbarui ADR/PRD/FSD/contract.

| ID | Pertanyaan/opsi | Rekomendasi awal dan konsekuensi | Owner / batas keputusan |
|---|---|---|---|
| OQ-01 | Apakah Company adalah group atau legal entity? | **Desain diputuskan:** Company grup pelaporan, LegalEntity unit pembukuan; CustomerAccount per entity. | Sponsor/Finance, aktivasi tenant |
| OQ-02 | Moving average vs FIFO vs standard cost? | **Desain diputuskan:** moving weighted average per entity+SKU+ownership; specific ID untuk kelas khusus. | Controller, aktivasi policy |
| OQ-03 | Kapan revenue/COGS diakui: dispatch, POD, invoice? | **Desain diputuskan:** profil default keduanya pada POD accepted; dispatch ke in transit. Kontrak lain memerlukan profil terbit. | Controller, aktivasi profil kontrak |
| OQ-04 | Exact tax jurisdiction, rounding level, e-invoice/withholding? | **Desain diputuskan:** baseline Indonesia, tax rule versioned, contoh numerik dan Coretax workflow; kelas khusus fail-closed. | Tax Lead, aktivasi rule/rekonsiliasi |
| OQ-05 | Approval threshold, inclusive boundary, SoD exception? | **Desain diputuskan:** batas/role, diskon, over-receipt 0%, maker-checker dan simulasi G-06. | Process Owners, aktivasi policy |
| OQ-06 | Credit exposure mencakup guarantee/deposit apa, override limit berapa lama? | **Desain diputuskan:** bucket mutually exclusive, guarantee 0 default, deposit posted eligible, FX buffer 5%, override nonaktif default. | Credit Controller, aktivasi policy |
| OQ-07 | Negative stock pernah diizinkan? | Tidak untuk sellable MVP; backorder dipakai | Inventory Controller, M0 |
| OQ-08 | Intercompany legal/tax flow dan transfer valuation? | **Baseline desain ditetapkan:** pasangan source/destination, transfer price/cost/FX snapshot, due-from/due-to, dua approval, saga dan elimination report; [FSD-P3](roadmap/phase-3-fsd.md). Tax profile/GL riil harus disahkan per pasangan entity sebelum aktivasi. | Tax/Controller, aktivasi Phase 3 |
| OQ-09 | Retention PII/finance/audit, residency, legal hold, consent GPS? | **Desain diputuskan:** region Indonesia, keuangan ≥10 tahun, log dan cache berbatas, GPS MVP nonaktif; lihat G-16. | Legal/Security, aktivasi produksi |
| OQ-10 | Bank/payment provider, webhooks, marketplace, WhatsApp? | **Baseline adapter ditetapkan:** allowlisted target, versioned mapping, HMAC/replay defense, source ID dedup, DLQ dan owner command; [FSD-P3](roadmap/phase-3-fsd.md). Provider riil dipilih dari business case dan contract test sebelum aktivasi. | Product/Integration, aktivasi Phase 3 |
| OQ-11 | SLO/RPO/RTO final dan jam operasional? | 99,9%, 15 min, 4 h sebagai target awal, uji biaya/infrastruktur | Sponsor/Ops, M1 |
| OQ-12 | Target pilot branch, volume, perangkat scanner, connectivity? | Pilih representatif peak dan koneksi buruk; ukur baseline | Operations, M0 |
| OQ-13 | Batas penerimaan over/under receipt dan expiry FEFO? | Baseline over 0%, under sebagai partial open, expiry wajib dan FEFO; pengecualian butuh policy terbit. | Procurement/Warehouse, aktivasi policy |
| OQ-14 | Multi language selain Indonesia/English dan mata uang aktif? | Dua bahasa awal; currency master dapat bertambah dengan precision config | Product/Finance, M1 |
| OQ-15 | Apakah invoice dan GL boleh terpisah deployable sejak MVP? | Tetap satu Finance Core sampai posting exception/recon matang | Architect/Controller, M1 |
| OQ-16 | Search PostgreSQL vs OpenSearch; broker NATS vs Kafka? | PostgreSQL FTS dan JetStream sampai metrik menunjukkan kebutuhan lain | Architect/SRE, P2 |

### Decision trade-off ringkas

| Keputusan | Option A | Option B | Recommended option / alasan |
|---|---|---|---|
| Service granularity | Banyak microservices sejak awal | Modul dalam sedikit deployable | B; meminimalkan transaksi terdistribusi tanpa mengorbankan boundary |
| Database topology | DB per service | Schema per module | B untuk MVP dengan privilege terpisah; A ketika layanan benar-benar dipisah |
| Broker | Kafka | NATS JetStream | NATS untuk operational events MVP; Kafka bila retention/stream analytics terukur |
| Search | OpenSearch | PostgreSQL FTS | PostgreSQL dulu; kompleksitas indeks kedua hanya bila kebutuhan terbukti |
| Sync mobile | Last-write-wins universal | Server-authoritative dengan review konflik | B; menjaga harga, credit, stock dan status |
| Financial correction | Edit/delete posted | Reversal/adjustment tertaut | B; histori dapat diaudit |

### Artefak turunan berikutnya

PRD ini menjadi sumber untuk BRD per proses, FSD per fitur kontrak §17, SRS/NFR test plan, ADR/System Design, OpenAPI per bounded context, event schema, logical/physical ERD, UI/UX specification, migration mapping dan QA test plan. Setiap artefak menautkan ID requirement dan mencatat keputusan yang berubah. PRD dipelihara berversi; perubahan business rule finansial/stok harus disetujui process owner dan Controller sebelum contract/implementation diubah.
