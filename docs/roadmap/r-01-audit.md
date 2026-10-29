# R-01 — Audit repository, backlog dan bukti G0 scope

**Tanggal audit R-01:** 29 Oktober 2026. **Status R-01: DONE untuk perencanaan backlog. Status G0 penuh: PARTIAL.** Bukti berada di [BL-001](implementation-backlog.md), [TR-001](requirement-traceability.md), serta validator di [scripts/validate_backlog.py](../../scripts/validate_backlog.py). Pekerjaan ini tidak membangun atau menguji aplikasi. Pada saat audit R-01, R-02 dan semua work order implementasi masih terbuka; [register R-02](r-02-dependency-register.md) kini selesai, dengan G0 tetap PARTIAL sampai input aktual/PIC tersedia.

## 1. Baseline yang benar-benar diperiksa

Audit membaca AGENTS root, PRD requirement/acceptance/roadmap, FSD Foundation, first slice, O2C, P2P, Inventory/WMS, Finance, Platform, return dan sync; FSD Phase 2/3/Expansion, data dictionary, UX, QA, work order, timeline dan gate. Inventaris filesystem menunjukkan:

| Artefak | Bukti saat R-01 | Batas kesimpulan |
|---|---|---|
| Kontrak HTTP | 16 file `contracts/openapi/*/v1.yaml` | Desain wire tersedia; tidak membuktikan handler berjalan. R-01 tidak mengulang lint/schema validation historis. |
| Event | 43 schema dan 43 contoh di `contracts/events` | Producer/consumer runtime belum ada. |
| SQL | 11 file migration `*.up.sql` di empat service owner | Subset Foundation/receipt/return. Tidak dijalankan ulang pada R-01; laporan apply PostgreSQL sebelumnya adalah bukti historis terpisah. |
| Stack | `backend/golang`, `frontend/nextjs`, `mobile/flutter` dan AGENTS tersedia | Belum ditemukan `.go`, `.ts`, `.tsx`, `.dart`, `go.mod`, `go.work`, `package.json`, atau `pubspec.yaml` pada inventaris workspace. |
| CI dan Git | `.git` dan scaffold workflow aplikasi belum tersedia | Tidak ada build/runtime/CI yang dapat diklaim lulus; bootstrap Git/CI masuk B-01. Script validasi dokumen R-01 bukan runtime ERP. |
| Aset dan lingkungan | Belum ada bukti Metronic vendor manifest, environment pilot, credential/provider dan owner bernama di artefak yang diperiksa | R-02 mencatat input/status/jalur perolehan; tidak boleh menganggap aset telah dibeli atau tenant telah diaktifkan. |

## 2. Hasil pemecahan backlog

**38 work order → 88 slice**. Semua 99 ID FR/BR/NFR/US/AC yang didefinisikan PRD tercakup: **35 FR, 18 BR, 16 NFR, 10 US, 20 AC**. Enam objective dan KPI bisnis PRD §5–6 juga dipetakan terpisah, termasuk perbedaan sync95% dalam 15 menit dan success keseluruhan 99,5%. Ekstensi tanpa ID FR khusus ditautkan pula melalui PRD §54 dan FSD-EXP §1–5 pada TR-001. ID PRD F-01–F-14 berbeda namespace dari ID work order F-01–F-04; tabel fitur/FSD menjelaskan pemetaannya.

Setiap slice memiliki actor/outcome, owner delivery dan reviewer role, acceptance, dependency slice, ukuran, risiko, serta profil sumber FSD/kontrak/data/UX/QA. Enabler platform dan gate operasi mempunyai hasil demonstrasi/bukti sendiri; tidak dibuat sebagai endpoint bisnis fiktif. Pekerjaan yang membutuhkan rincian tambahan diberi NEEDS_SPEC, bukan disembunyikan oleh jumlah coverage. Role owner bukan penunjukan seseorang atau tanda tangan mereka; R-02 perlu mengikat role ke PIC aktual dan kapasitas.

## 3. Gap spesifikasi yang harus ditutup pada slice terkait

Enam kelompok di bawah adalah gap detail yang ditemukan audit, bukan keputusan menghapus atau menambah requirement. FSD/kontrak/data/UX/QA yang disebut pada backlog adalah baseline dan **harus dilengkapi sebelum coding scope yang terkena gap**. R-01 hanya memberi assignment, dependency, dan acceptance penutupan. Label desain lama “semua siap coding” dibatasi oleh hasil audit ini.

| ID / status | Bukti dan masalah | Owner / slice / gate | Bukti penutupan sebelum kode |
|---|---|---|---|
| GAP-01 OPEN | [PRD §15](../enterprise-erp-prd.md#15-functional-requirements-dan-detailed-module-requirements) FR-ORG-01/02 meminta region/area/stock point/department/division/cost-profit center. [Foundation](../features/foundation-fsd.md) dan [DATA-003](../features/mvp-data-dictionary.md) merinci entity/branch/warehouse dan closure, tetapi mapping seluruh jenis node/dimensi ke persistence/wire/UX belum lengkap. | Platform + Org owner; **F-01.1**, sebelum G2 | Matriks parent/type dan assignment effective, field/API untuk seluruh node/dimensi, screen/form, fixtures cycle/overlap/as-was/as-is; parent ownership eksplisit. |
| GAP-02 OPEN | FR-MDM-01/02/03 dan employee reference MVP meminta atribut product/barcode/brand/principal/variant sederhana serta customer group/channel/territory/salesman dan product-supplier. [Master API](../../contracts/openapi/master/v1.yaml), [Platform API](../../contracts/openapi/platform/v1.yaml) dan DATA-003 memiliki SKU/UOM serta party/account inti; seluruh atribut itu belum dipetakan lengkap. | Platform + Master Data/Commercial; **F-02.2–F-02.3**, sebelum G2 | FSD/data/API/UX/QA untuk atribut, relasi dan reference employee; barcode uniqueness dan masking/checker; batas variant sederhana vs matrix kompleks sesuai PRD §53. |
| GAP-03 OPEN | FR-SAL-01 menyebut quotation→SO dan repeat order; [Sales API](../../contracts/openapi/sales/v1.yaml) dan [O2C](../features/o2c-fsd.md) berpusat pada SO/credit. Lifecycle quotation, expiry, conversion idempotency dan cloning aman belum lengkap sebagai kontrak sendiri. | Commercial + Sales owner; **M-04.1**, sebelum G3 | FSD, data, API, quote/repeat screens dan QA source/expiry/requote; source snapshot dan nomor lama tidak didaur ulang. |
| GAP-04 OPEN | FR-MDM-04 memerlukan employee assignment efektif, FR-SAL-03 target/attribution. [FSD-P2](phase-2-fsd.md) dan [DATA-RM](roadmap-data-dictionary.md) memiliki route/visit; `employee_guid` pada expense adalah referensi, bukan lifecycle employee master. Definisi target/effective-call lengkap belum ada. | Platform + Commercial + Sales Ops; **P2-04.1**, sebelum route assignment dan G5 | Position/supervisor/department/branch/territory versi efektif, target period/formula/attribution, ownership data, API/UX dan QA overlap/scope/history. Tidak memperluas menjadi payroll/HR suite. |
| GAP-05 OPEN | FR-ACC-02 meminta balance sheet/cash flow; [Finance FSD](../features/finance-gl-fsd.md) merinci trial balance/P&L/aging, [FSD-P2](phase-2-fsd.md) merinci operations reports. Mapping statement/formula/UX/fixture kedua statement belum setara detailnya. | Finance + Controller; **P2-05.1**, sebelum G5 | Account-to-statement mapping berversi, metode/klasifikasi cash-flow disetujui Controller, API/query dan layar, fixture neraca seimbang serta cash beginning+movement=ending. Ini keputusan bisnis terbuka spesifik, bukan asumsi programmer. |
| GAP-06 OPEN | FR-IMP-01 menunda XLSX ke P2; [IMP-001](../features/mvp-import-templates.md) adalah template CSV. [UX-RM](roadmap-ux.md) meminta ID/EN, tetapi proof locale lintas web/mobile/export belum ada. | Platform + Web/Mobile + Data owner; **P2-05.2**, sebelum G5 | Worksheet/header/type/limit/formula/macro/duplicate handling, preview/commit contract dan fixtures XLSX; catalog ID/EN dan roundtrip uang/date/timezone. Build fondasi locale di F-04.2, verifikasi lengkap P2-05.2. |

GAP-05 membutuhkan keputusan Controller mengenai metode laporan; gap lain memerlukan elaborasi desain dan review owner terhadap requirement yang sudah ada. Semua dapat disiapkan pada pekerjaan terkait tanpa menebak policy riil. R-02 belum dijalankan, sehingga tanggal target dan PIC bernama belum diketahui; batas waktu logisnya adalah “sebelum kode slice/gate” di atas.

### Ketidakkonsistenan yang diperbaiki dalam audit R-01

- **FIX-01:** label phase delegasi dan approval paralel/escalation pada PRD §15/§21 diselaraskan menjadi P3, mengikuti PRD §54, FSD-P3 dan WO P3-01 yang sudah menjadi roadmap. FR-FIN-02 expense/bank reconcile juga P3; register POS berada pada Expansion E-02. Scope fitur tidak dihapus.
- **FIX-02:** contoh traceability PRD §14 merujuk `BR-INV-03/04` yang tidak didefinisikan. Referensi diganti dengan `BR-INV-02` untuk stock guard dan `BR-PUR-01` untuk receipt limit. Tidak membuat business rule baru.
- Search tetap MVP sesuai FSD-PLT/M-08 (lebih awal dari label SHOULD/P2 PRD); label FR-SRH-01 diselaraskan agar satu urutan. Nominal deadline 128 minggu tidak diubah oleh perubahan label ini.

## 4. Dependency, jalur kritis dan ukuran

Graph pada BL-001 memakai prerequisite antarslice, bukan sekadar nomor urut. Prasyarat paket ditambahkan ke slice pertama dan urutan internal konservatif memakai slice sebelumnya; DONE pada slice terakhir berarti seluruh paket sebelumnya terbukti. Karena profile B-01 bergantung R-02, G0 harus diperiksa sebelum platform dimulai. F-04 dapat dikerjakan sejajar F-02/F-03 setelah IAM; M-03 GRNI/AP dapat sejajar M-04 sales setelah stock; kedua cabang bertemu pada M-06. Semua pekerjaan P2 bertemu P2-05; seluruh control P3 bertemu P3-06/G6; assembly/POS/TMS bertemu reporting/Expansion gate.

**Jalur bisnis kritis kandidat:** mobilisasi → scaffold/data/auth → IAM/master/policy dan web shell → PR/PO → GRN/stock → SO/credit → reservation/WMS/POD (menunggu GRNI/AP juga) → AR/payment/GL → platform completion → UAT/restore → pilot → P2 gate → P3 gate → Expansion gate → hardening → final handover. Jika gagal, fase berikutnya tidak boleh ditandai selesai. Node gap di jalur ini harus ditutup sebelum dependent slice mulai.

Validator menghitung jalur dependency terpanjang memakai midpoint effort S/M/L. Ini **bukan critical path kalender/CPM tervalidasi**, sebab kapasitas, resource contention, waiting time dan named reviewer belum diisi R-02. Timeline 128 minggu tetap asumsi tiga squad dari TL-001; total person-days tidak boleh langsung dibagi jumlah AI atau dianggap tanggal selesai. Reforecast setelah R-02 serta throughput B-01/G1. S=2–3, M=4–6, L=7–10 person-days gabungan; uncertainty paling tinggi pada GAP-01–06, provider integration dan E-06.2 split bersyarat. Bila E-06 memilih no-split, acceptance N/A beralasan tetap memerlukan bukti keputusan dan regression; estimasi split tidak menjadi komitmen.

### Risiko dan external gates

| Risiko | Dampak / owner | Mitigasi / gate |
|---|---|---|
| Lisensi/source Metronic belum terbukti | F-04.1 UI integration; Product/Web | R-02 register, vendor manifest sebelum salin source; shell/kontrak independen dapat berjalan. F-04 tidak DONE tanpa acceptance vendor. |
| IdP/provider/policy riil belum tersedia | Auth, payment, tax, adapters; Security/Integration/Controller/Tax | Fixture/stub untuk development, sandbox contract test dan activation approval untuk rilis; tidak menganggap stub bukti provider. |
| GAP-01–06 | Detail belum memenuhi DoR subset; owner pada tabel gap | Tutup FSD/data/kontrak/UX/QA lalu re-estimasi slice; jangan bypass atau membuang requirement SHOULD. |
| Migration awal dianggap mencakup seluruh domain | Integrity/upgrade; DBA/domain leads | B-02 audit checksum/grants; migration baru per slice, PostgreSQL tests dan forward-fix/restore proof. |
| Ledger, credit, billing-source race | Double posting/overspend; Operations/Commercial/Finance | Function lokal atomik, source uniqueness, inbox/outbox, failure/reconciliation fixtures pada M/P2/P3/E terkait. |
| Kapasitas dan reviewer belum bernama | Timeline/SoD review; Product | R-02 capacity/PIC register, reforecast per gate; tidak menjanjikan 128 minggu sebagai kalender fixed. |
| UAT/hypercare/sign-off belum terjadi | Pilot/final tidak sah; Product/Ops | M-09/M-10/P2-05/P3-06/Z-02 menyimpan bukti manusia dan observasi nyata. |

## 5. Penilaian G0

| Item G0 dari TL-001 | Hasil R-01 | Bukti / pekerjaan tersisa |
|---|---|---|
| Backlog per WO, owner, dependency, acceptance, ukuran | **PASS untuk scope R-01** | BL-001 38 WO/88 slice; role owner/reviewer eksplisit, risiko dan graph. Named PIC/capacity dicatat R-02. |
| Pilot/entity, data, workload/perangkat/jaringan, baseline KPI | **OPEN — R-02** | Belum ada register input aktual; fixture desain bukan input pilot yang disetujui. |
| Lisensi/IdP/policy/provider punya owner dan jalur perolehan | **OPEN — R-02** | Role risiko di audit ini belum menggantikan register target/status/perolehan R-02. |
| Perubahan scope menautkan PRD/FSD/kontrak/data/UX/QA | **PASS untuk baseline R-01** | TR-001 dan profil BL-001; gap detail terlihat dan status NEEDS_SPEC. Tidak ada scope baru di luar PRD; label fase diselaraskan. Perubahan berikutnya tetap wajib ditelusuri. |

**Keputusan:** centang R-01 saja; G0 belum lulus penuh, G1–G8 belum dibuktikan. Pekerjaan berikutnya yang siap adalah **R-02**, mulai R-02.1 lalu R-02.2. B-01 baru siap setelah register R-02 dan G0 ditinjau. Gap spesifikasi tetap menahan slice terkait, bukan menahan penyusunan register R-02.

## 6. Bukti validasi yang dapat diulang

Jalankan dari root repository:

```bash
python3 scripts/validate_backlog.py
```

Validator memeriksa coverage checklist WO, requirement PRD dua arah, profil sumber owner/acceptance, local file/heading links, status READY/DONE terhadap dependency, unresolved dependency, dan cycle graph. Hasil sukses hanya membuktikan struktur/rujukan/coverage dokumen. Audit isi dan gap pada bagian 3 berasal dari pembacaan sumber; sebuah link valid tidak membuktikan bahwa kontrak sudah lengkap.

Output aktual:

```text
Work orders: 38; slices: 88; requirement IDs: 99
AC: 20; BR: 18; FR: 35; NFR: 16; US: 10
Local links checked: 574; NEEDS_SPEC: 7
Estimated total effort: 571–819 person-days (baseline kasar)
PASS: planning references/coverage/DAG only; runtime not tested.
```

Jalur terpanjang menurut midpoint effort yang dihitung validator:

```text
R-01 → R-02 → B-01 → B-02 → B-03 → F-01 → F-02 → F-03
→ M-01 → M-02 → M-04 → M-05 → M-06 → M-07 → M-08
→ M-09 → M-10 → P2-04 → P2-05 → P3-01 → P3-02 → P3-06
→ E-01 → E-04 → E-05 → E-06 → Z-01 → Z-02
```

Cabang dengan bobot sama dapat menghasilkan jalur alternatif (misalnya control P3 dan assembly/POS); validator menampilkan satu jalur terpanjang. Size termasuk task bersyarat E-06.2 sebagai placeholder; setiap keputusan split memerlukan estimasi baru. Angka 571–819 person-days bukan revisi otomatis timeline 128 minggu dan tidak termasuk menunggu aset/UAT/hypercare. Jika gap bertambah atau ukuran berubah, jalankan ulang validator dan perbarui bukti ini. Pemeriksaan tambahan pada sembilan dokumen indeks/PRD/gate yang diperbarui: 259 tautan lokal, nol file hilang; seluruh referensi BR pada PRD sekarang terdefinisi. Tidak ada build/test API, UI/mobile, SQL apply, benchmark, UAT atau produksi yang dijalankan pada R-01.
