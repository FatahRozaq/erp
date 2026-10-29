# Keputusan Baseline Bisnis MVP — ERP Distribusi Indonesia

**Tanggal riset:** 28 Oktober 2026. **Status:** keputusan desain untuk implementasi dan data uji; aktivasi transaksi riil memerlukan persetujuan pemilik proses, Controller, dan Tax/Legal atas konfigurasi tenant. **Cakupan:** distribusi barang berwujud domestik Indonesia oleh penjual PKP, satu legal entity per transaksi, IDR sebagai mata uang dasar, penjualan biasa tanpa konsinyasi/uang muka/intercompany. Kasus di luar profil ini ditolak dengan kode aturan yang jelas sampai profil kontrak dan pajak yang relevan diterbitkan.

Dokumen ini menutup keputusan desain G-01 sampai G-06 di [audit kesiapan](../implementation-readiness.md). Angka persetujuan, toleransi, diskon, buffer FX, dan limit kredit di bawah adalah **default produk yang diusulkan**, bukan angka yang diwajibkan undang-undang atau kebijakan perusahaan tertentu. Simpan sebagai policy berversi dengan rentang efektif; tidak ada perubahan retroaktif atas dokumen yang telah disubmit/posted. Lingkungan produksi hanya mengaktifkan policy setelah approval maker–checker serta simulasi kasus di bawah.

## G-01 — Tenant, Company, LegalEntity, Branch, Warehouse

| Objek | Makna dan kepemilikan | Cardinality dan larangan |
|---|---|---|
| `Tenant` | Batas isolasi pelanggan SaaS, identitas, konfigurasi dan billing platform. | 1 tenant memiliki 1..N company; tidak menjadi pemilik jurnal atau stok. |
| `Company` | Grup/holding atau brand pelaporan di dalam tenant. | 1 company memiliki 1..N legal entity; tidak punya NPWP, COA, AR/AP atau inventory ledger sendiri. |
| `LegalEntity` | Badan hukum dan unit pembukuan/pajak: NPWP/PKP, mata uang dasar, kalender fiskal, zona waktu, COA, nomor dokumen, status periode. | Setiap transaksi, stok, piutang, utang, jurnal dan credit account milik tepat satu legal entity. |
| `Branch` | Unit operasional di bawah legal entity, dengan region/area efektif-bertanggal. | Tepat satu legal entity pada suatu waktu; pindah kepemilikan lintas entity harus membuat branch baru, bukan memindahkan histori. |
| `Warehouse` | Lokasi stok di bawah legal entity; assignment branch efektif-bertanggal. | Tepat satu legal entity sepanjang umur; transfer lintas entity memerlukan dokumen intercompany terpisah. |
| `Customer` | Identitas party tenant-level agar duplikasi berkurang. | `CustomerAccount` per `(tenant_guid, customer_guid, legal_entity_guid)` menyimpan status jual, tax profile, payment term, dan credit limit; AR tidak dapat berpindah entity. |

Contoh fixture: tenant T memiliki company C, legal entity LE-A dan LE-B. LE-A mempunyai branch A-1/A-2 dan warehouse W-A; LE-B mempunyai branch B-1 dan warehouse W-B. Customer X boleh punya account X-A dan X-B dengan limit/term berbeda. SO dari A-1 hanya memakai X-A dan W-A; SO X-A tidak boleh mengambil limit X-B. Reparent A-2 antar region mencatat `valid_from/to` dan snapshot branch pada dokumen lama; laporan `as-was` dan `as-is` dapat dibedakan.

Constraint minimum: GUID unik; `legal_entity(tenant_guid, company_id)` valid dengan FK lokal Platform; code unik dalam parent dan active period; `customer_account` unik per customer+legal entity; branch/warehouse assignment tidak overlap untuk subjek yang sama. Perubahan parent melarang cycle dan disimpan dalam history; permission query memakai closure/interval yang berlaku pada tanggal aksi. Tidak ada SQL lintas owner untuk memvalidasi referensi ke stok/jurnal.

## G-02 — Valuasi persediaan dan waktu COGS

**Metode:** moving weighted average untuk SKU yang saling dipertukarkan, konsisten pada kelas persediaan yang sama. Pool biaya adalah `(legal_entity_guid, sku_guid, ownership)` dalam mata uang dasar legal entity; warehouse/bin/lot adalah dimensi kuantitas dan traceability, bukan formula biaya lain. Barang dengan serial individual yang benar-benar tidak saling dipertukarkan memakai specific identification hanya melalui kelas valuasi terbit tersendiri. Metode tidak berubah retroaktif; migrasi metode memerlukan pembukaan saldo dan rekonsiliasi. [IAS 2](https://www.ifrs.org/issued-standards/list-of-standards/ias-2-inventories/) mengizinkan FIFO atau weighted average untuk barang yang saling dipertukarkan dan specific identification untuk barang yang tidak demikian.

Pada receipt, biaya masuk = harga beli net + freight/duty yang dapat diatribusikan + pajak **tidak dapat dikreditkan**; PPN masukan yang dapat dikreditkan terpisah. `new_average = (old_qty × old_average + accepted_qty × landed_unit_cost) / new_qty`. Simpan nilai total persediaan sebagai `numeric(20,6)` dan unit average internal sebagai `numeric(24,10)`; residual alokasi masuk pada movement terakhir secara deterministik. Qty/valuation negatif ditolak. Perpindahan gudang dalam entity membawa biaya asal tanpa recalculation harga. Return pelanggan memakai `outbound_cost_snapshot` dari delivery line; barang rusak masuk hold dan dinilai menurut kebijakan NRV/kerugian, tidak otomatis menjadi sellable. Write-down NRV dan damage diakui pada periode terjadinya, sesuai [IAS 2](https://www.ifrs.org/issued-standards/list-of-standards/ias-2-inventories/).

Contoh IDR tanpa pajak masukan: receipt 10 unit × 100 = 1.000 dan 10 × 120 = 1.200 memberi 20 unit bernilai 2.200, average 110. Dispatch 5 unit memindah 550 dari Inventory Warehouse ke Inventory In Transit, belum COGS. POD menerima 3 unit: COGS 330 dan stok transit turun 330. Dua unit gagal antar dan kembali: stok gudang naik 220 dari transit. Jika 2 dari 3 unit yang terjual kemudian diretur layak jual, credit memo dan movement balik menambah inventory 220, membalik COGS 220; tidak memakai average terbaru untuk menentukan biaya retur asal.

## G-03 — Kendali barang, pendapatan, cut-off

Default profil kontrak `TRANSFER_ON_ACCEPTED_DELIVERY`: kendali barang berpindah hanya pada bukti terima pelanggan yang sah (POD accepted) per delivery line/qty. Bukti minimum memuat identitas penerima yang dikonfirmasi, qty accepted/rejected per line, waktu server, actor/device, idempotency key, serta tanda tangan atau foto dengan checksum; GPS tidak wajib. Bukti tidak lengkap masuk `POD_REVIEW_REQUIRED`. Scan dispatch hanya mengubah lokasi/status menjadi in transit. POD gagal/ditolak tidak menciptakan revenue atau COGS. [IFRS 15](https://www.ifrs.org/issued-standards/list-of-standards/ifrs-15-revenue-from-contracts-with-customers/) mengaitkan pendapatan dengan perpindahan kendali, yang dapat bergantung pada syarat kontrak; [IAS 2](https://www.ifrs.org/issued-standards/list-of-standards/ias-2-inventories/) menempatkan beban persediaan terjual pada periode pendapatan terkait. Profil transfer saat dispatch hanya boleh diterbitkan untuk kontrak dengan bukti term yang menyatakan kendali berpindah saat pengiriman; invoice sendirian bukan bukti perpindahan kendali.

Alur online MVP: `DISPATCHED → POD_ACCEPTED_PENDING_FINANCE` pada delivery; Finance kemudian memberi status `INVOICED_POSTED` pada source portion dan acknowledgement yang mengubah delivery menjadi `DELIVERED` untuk qty selesai. Operations menyimpan accepted qty dan cost snapshot, menerbitkan event; Finance Core menunggu posting dispatch/in-transit untuk portion yang sama, lalu membuat invoice dan jurnal AR/revenue/PPN/COGS secara idempotent dalam satu transaksi lokal. Kegagalan Finance meninggalkan state pending yang terlihat dan dapat diretry; tidak boleh menandai delivery selesai atau menutup periode selama event accepted belum diposting. Source portion unik permanen mencegah invoice dan COGS ganda. Pada 3 unit di contoh G-02, harga net 200/unit dan PPN efektif 11%: Dr AR 666; Cr Revenue 600; Cr PPN Keluaran 66; Dr COGS 330; Cr Inventory In Transit 330. Posting stock movement fisik oleh Operations dan jurnal Finance direkonsiliasi per `business_operation_guid`. Dua unit gagal antar kembali ke gudang tanpa pendapatan/COGS.

Tanggal bisnis POD memakai zona legal entity; tanggal pencatatan aktual tetap UTC. Jika POD 31 Desember tetapi event diterima 1 Januari, Finance mem-post ke 31 Desember **hanya bila periode masih open** dan bukti penerimaan valid. Close gate menolak periode bila ada POD accepted belum terselesaikan. Jika periode sudah closed, jangan backdate diam-diam: buat exception, Controller menentukan reopen berizin atau adjustment current period dengan referensi periode asal. Faktur pajak dan waktu terutang mengikuti aturan yurisdiksi; untuk penyerahan BKP domestik, [ketentuan DJP](https://www.pajak.go.id/sites/default/files/lampiran/PER-11_PJ_2025_0.pdf) mengaitkan faktur dengan penyerahan atau pembayaran lebih awal, sehingga status tax document harus dimonitor terpisah dari invoice ERP.

## G-04 — Pajak Indonesia dan pembulatan

`TaxRuleVersion` memiliki `jurisdiction=ID`, tanggal berlaku, legal entity PKP, seller/buyer tax status, kelas produk, jenis transaksi, `vat_rate`, `dpp_factor_num/den`, `inclusive`, exemption basis/certificate, withholding type/rate, rounding policy, akun GL dan referensi regulasi. Tax determination mengambil snapshot input/versi pada setiap invoice/credit memo. Kelas yang tak punya rule, PPnBM tanpa tarif dan bukti klasifikasi, atau exemption tanpa dasar valid → `TAX_POLICY_MISSING` dan issue ditolak. Tidak ada fallback diam-diam ke tarif nol.

Baseline barang/jasa nonmewah yang dicakup PMK 131/2024 memakai tarif PPN 12% × DPP nilai lain 11/12 dari harga net, sehingga efektif 11%; barang mewah yang masuk cakupan memakai DPP penuh 12% dan PPnBM menurut kelas khusus. Perlakuan khusus lain tidak diturunkan dari aturan umum. Ini mengikuti penjelasan [DJP PMK 131/2024](https://pajak.go.id/node/113453); konfigurasi harus dicek terhadap perubahan regulasi saat aktivasi, termasuk [perubahan PER-11/PJ/2025 yang berlaku 1 Oktober 2026](https://www.pajak.go.id/index.php/id/peraturan/perubahan-atas-peraturan-direktur-jenderal-pajak-nomor-11pj2025-tentang-ketentuan).

| Skenario IDR | Net sesudah diskon | DPP | PPN | Total/settlement |
|---|---:|---:|---:|---:|
| Nonmewah eksklusif | 120.000 | 110.000 | 13.200 | Tagihan 133.200 |
| Nonmewah inklusif, harga gross 133.200 | 120.000 | 110.000 | 13.200 | Tagihan 133.200 |
| Nonmewah, diskon 10% dari 120.000 | 108.000 | 99.000 | 11.880 | Tagihan 119.880 |
| Mewah, contoh **PPnBM 0 hanya untuk uji rumus PPN** | 120.000 | 120.000 | 14.400 | 134.400 sebelum PPnBM; transaksi nyata wajib tarif PPnBM aktif |
| Dibebaskan dengan dasar hukum valid | 120.000 | 120.000 | 0 | Tagihan 120.000; kode exemption + dasar tersimpan |
| Jasa yang memang objek PPh 23, pelanggan pemotong | 100.000 | 91.666,666667 | 11.000 | Tagihan 111.000; bila potong 2.000 dan bukti potong sah, kas 109.000 + piutang pajak 2.000 |

Baris PPh 23 adalah contoh jalur jasa, **bukan** aturan default penjualan barang. [DJP](https://pajak.go.id/id/pph-pasal-23) menyebut pemotongan 2% pada jasa tertentu; klasifikasi jasa dan bukti potong harus diverifikasi. Tanpa bukti potong, selisih kas tetap sebagai AR/suspense, bukan otomatis dianggap lunas.

Perhitungan memakai decimal/rational tanpa float. Urutan: harga × qty → diskon → taxable net → DPP factor → PPN/withholding. Default implementasi membulatkan pajak ke satuan IDR per line dengan `HALF_UP` dan total dokumen adalah jumlah line; residual bila diperlukan dialokasikan ke line taxable terbesar, tie-break `line_guid`. DPP internal tetap presisi tinggi; angka legal pada XML e-Faktur mengikuti format/validasi DJP dan selisih ditahan untuk review, tidak disesuaikan diam-diam. Untuk invoice valuta asing, konversi **PPN** ke IDR memakai kurs KMK yang berlaku saat Faktur Pajak seharusnya dibuat, terpisah dari kurs pembukuan/credit check, sesuai [PER-11/PJ/2025](https://www.pajak.go.id/sites/default/files/lampiran/PER-11_PJ_2025_0.pdf). Faktur pajak adalah artefak eksternal dengan status `PENDING/SUBMITTED/ACCEPTED/REJECTED` dan external reference; jalur MVP dapat memakai ekspor XML serta pencocokan manual di [Coretax DJP](https://pajak.go.id/coretaxpedia/cara-membuat-faktur) sampai integrasi resmi tersedia. Aktivasi penjualan PKP memerlukan proses tax document yang operasional.

## G-05 — Kredit, FX, deposit, override

Kredit dihitung dalam mata uang dasar legal entity pada nilai **gross termasuk pajak** yang diperkirakan akan ditagih. Setiap source portion hanya berada pada satu bucket: `APPROVED_UNSHIPPED → SHIPPED_UNACCEPTED → ACCEPTED_UNBILLED → POSTED_AR → PAID/CANCELLED`. Exposure = seluruh bucket aktif + komitmen lain yang disahkan − eligible deposit. Perpindahan bucket atomik/idempotent, bukan menambah salinan. Guarantee bernilai 0 sebagai pengurang exposure secara default; hanya bank guarantee terverifikasi, belum kedaluwarsa dan terikat pada customer/entity boleh diaktifkan lewat policy khusus. Deposit eligible adalah kas diterima/posted, belum dialokasikan/direfund, milik customer+entity yang sama; aplikasi deposit ke AR memindahkan nilai antarbucket tanpa pengurangan kedua.

Untuk currency non-IDR, gunakan kurs snapshot terpercaya pada waktu check ditambah buffer risiko default 5% pada komitmen terbuka; sumber default [JISDOR USD/IDR atau kurs acuan non-USD/IDR Bank Indonesia](https://www.bi.go.id/id/fungsi-utama/moneter/informasi-kurs/default.aspx) untuk pair yang tersedia. Umur kurs maksimal 72 jam; hari libur tidak memperpanjang batas tanpa policy baru yang disetujui. AR posted memakai nilai buku dasar, bukan dikonversi ulang tiap request. Kurs hilang/stale → hold. Kurs pajak memakai KMK sesuai G-04, **bukan** kurs credit check ini. Credit account row dikunci bersama ledger bucket saat submit, approval, dan release dispatch; hitung ulang setelah lock pada primary DB. Dua order paralel tidak boleh keduanya lolos dari limit yang sama. Payment pending tidak mengurangi exposure. Credit limit baru default nol, berarti prepaid-only; bila order belum didukung prepaid flow, submit ditolak.

Contoh limit 1.000; AR 400 + SO approved 300 + in transit 100 + accepted unbilled 50 = gross 850. Deposit eligible 100 menghasilkan exposure 750 dan available 250. Order baru 300 ditahan. Ketika 100 in transit berubah menjadi AR 100, exposure tetap 750. Pembayaran AR 200 yang posted menurunkannya ke 550. Dari posisi 550 tersebut terdapat dua skenario terpisah: refund deposit 100 menaikkan exposure ke 650; **atau** alokasi deposit 100 ke AR menurunkan AR dan eligible deposit masing-masing 100, sehingga exposure tetap 550.

Default `credit_override_enabled=false` di production sampai policy diterbitkan. Jika diaktifkan, default kelebihan maksimal `min(10% × credit_limit, IDR 10.000.000)`, hanya untuk satu SO dan legal entity, expiry maksimal 24 jam, reason, Controller dan approver kedua yang bukan maker, dan consumed-once record wajib; tidak dapat mengabaikan customer blocked, sanction, atau period lock. Tidak ada override global/permanen.

## G-06 — Approval, SoD, diskon, receipt

Policy amount memakai `gross_total_base_currency` setelah pajak dan diskon, tepat pada batas: `0 < amount < IDR 10.000.000` → Supervisor; `10.000.000 ≤ amount ≤ 100.000.000` → Manager; `amount > 100.000.000` → Director. Untuk SO/PO, approval amount dan approval diskon keduanya harus terpenuhi; satu principal boleh memenuhi dua step bila role/scope sah, tetapi maker tidak boleh memutus step apa pun pada dokumen sendiri. Policy version/inputs disnapshot saat submit. Perubahan amount, currency, line, payee, bank account, tax/discount, atau legal entity membatalkan approval lama.

| Kondisi default | Keputusan |
|---|---|
| Manual discount 0% | Tidak ada step tambahan |
| 0% < manual discount ≤5% | Sales Manager tambahan |
| 5% < manual discount ≤10% | Sales Director tambahan |
| Manual discount >10% atau net price di bawah cost snapshot | Tolak; floor default = biaya unit snapshot (margin kotor minimum 0%); cost hilang → tolak |
| Receipt qty kurang dari PO | Terima parsial; sisa PO tetap open |
| Receipt qty melebihi sisa PO, berapa pun | Tolak sampai PO amendment disetujui; default over tolerance 0% |
| Vendor invoice qty/price melebihi matched PO/GRN | `MATCH_EXCEPTION`; default tolerance 0 sampai policy P2P diterbitkan |
| SKU expiry wajib tanpa lot/expiry atau expired | Tolak; FEFO hanya boleh override dengan role, alasan dan jejak audit bila barang masih layak |

Simulasi batas amount: 9.999.999 → Supervisor; 10.000.000 → Manager; 100.000.000 → Manager; 100.000.001 → Director. Diskon 5% → Manager; 5,000001% → Director; 10,000001% → rejected. Maker=approver, delegator=maker, approver di luar scope, tidak ada approver, atau policy overlap → keputusan tidak boleh auto-pass; masuk `PENDING_CONFIGURATION`/`FORBIDDEN` dengan owner dan SLA. Delegation/parallel/escalation tetap P2; emergency break-glass tidak membuka posting keuangan atau stok pada MVP. Published policy immutable dan penerbitannya membutuhkan maker–checker serta simulation tests.

## G-07 — Three-way match vendor invoice dan landed cost

Stocked goods memakai three-way match PO approved ↔ goods receipt posted ↔ vendor invoice per source portion; jasa memakai PO ↔ service acceptance. Default toleransi **0** untuk qty dan harga. Qty invoice yang eligible tidak boleh melebihi accepted yang belum ditagih, dan harga net harus sama dengan PO version yang disetujui. Invoice sebelum receipt atau berlebih tetap `MATCH_EXCEPTION` tanpa AP/input tax/jurnal sampai receipt/PO amendment/credit note menyelesaikan selisih. Satu nomor vendor invoice per vendor+legal entity+tax period tidak boleh diposting dua kali; original tax document dan referensi eksternal disimpan.

Contoh PO 10 × 100, receipt 6: saat GRN Dr Inventory 600, Cr GRNI 600. Vendor invoice 6 × 100 + PPN 66: Dr GRNI 600, Dr PPN Masukan 66 bila eligible, Cr AP 666. Invoice 10 × 100 pada saat receipt baru 6 memperlihatkan matched 6 dan exception 4, tetapi seluruh invoice **belum diposting** sampai resolved. Invoice 6 × 105 memperlihatkan price variance 30 dan belum diposting; PO amendment atau credit note vendor harus disetujui lebih dulu.

Freight/duty yang dapat diatribusikan langsung ke barang masuk ke landed cost, bukan langsung expense, sesuai [IAS 2](https://www.ifrs.org/issued-standards/list-of-standards/ias-2-inventories/). Baseline alokasi antar line berdasarkan proporsi nilai beli net; residual ke line dengan nilai terbesar, tie-break GUID. Contoh freight 100 pada dua line bernilai 600 dan 400 memberi 60 dan 40. Jika harga/freight final datang setelah sebagian unit terjual, adjustment proporsional masuk nilai inventory tersisa dan COGS unit terjual pada periode terbuka; periode tertutup memakai jurnal koreksi berizin yang tertaut, bukan mengedit movement lama. GRNI terbuka dan harga variance direkonsiliasi harian.

## G-16/OQ-09 — Data, retensi dan lokasi operasi Indonesia

Baseline deployment MVP memilih region Indonesia untuk database, object storage, backup, audit digest dan disaster recovery. [PP 71/2019 Pasal 21](https://jdih.komdigi.go.id/produk_hukum/view/id/695/t/common) memperbolehkan PSE privat mengelola data di dalam atau luar Indonesia dengan syarat pengawasan/penegakan hukum, sedangkan sektor tertentu dapat memiliki aturan tambahan. Untuk pembukuan pajak, [UU KUP Pasal 28(11)](https://www.pajak.go.id/sites/default/files/2021-11/SDSN%20UU%20KUP%20stdtd%20UU%20HPP.pdf) secara khusus mensyaratkan buku/catatan/dokumen dasar pembukuan elektronik disimpan 10 tahun **di Indonesia**; [UU 8/1997 Pasal 11](https://peraturan.bpk.go.id/Download/34482/UU%20Nomor%208%20Tahun%201997.pdf) menetapkan 10 tahun sejak akhir tahun buku untuk catatan dan bukti keuangan perusahaan. Jadwal retensi tenant memakai batas yang lebih lama bila aturan sektoral/kontrak mengharuskan; legal hold menghentikan purge.

| Kelas data | Default retensi desain | Perlakuan |
|---|---|---|
| Jurnal, invoice, receipt, bukti keuangan, stock movement yang menjadi bukti pembukuan, audit terkait | ≥10 tahun sejak akhir tahun buku | Append-only, akses terbatas, arsip/restore teruji; PII yang tidak wajib dapat dimasking tanpa menghilangkan bukti transaksi |
| Audit login/keamanan yang tidak terkait bukti keuangan | 2 tahun setelah event | Akses Security saja, legal hold/insiden dapat memperpanjang |
| PII profil nonkeuangan setelah akun ditutup | 12 bulan setelah penutupan hubungan | Hapus atau anonimisasi kecuali masih melekat pada bukti keuangan/hold |
| Log aplikasi | 30 hari | Redaksi PII/token, tidak menjadi audit utama |
| Trace terdistribusi | 14 hari | Sampling dan redaksi |
| Export sementara | 7 hari | URL berumur pendek, hapus objek setelah TTL |
| Cache mobile offline | 7 hari maksimal tanpa validasi scope ulang | Encryption at rest; revoke/scope change memicu purge |
| Backup operasional | 35 hari rolling | Encryption, restore drill, expiry terukur; arsip keuangan legal dipisah dari backup |
| GPS mentah | Tidak dikumpulkan pada MVP; fitur P2 opt-in | Bila aktif, notice/consent atau dasar hukum lain yang disetujui Legal, minimisasi dan jadwal retensi spesifik |

[UU PDP 27/2022](https://jdih.komdigi.go.id/produk_hukum/view/id/832/t/crc32/) menuntut tujuan pemrosesan terbatas, keamanan, penghapusan setelah masa retensi kecuali aturan lain menentukan, serta informasi retensi ketika consent menjadi dasar. Karena itu audit/ledger keuangan tidak dihapus atas permintaan yang bertentangan dengan kewajiban simpan; identitas yang tidak perlu dimasking dan permintaan dicatat. Policy `data_class/jurisdiction/legal_hold` memilih purge, masking, dan backup expiry; backup bukan jalan pintas mempertahankan data tanpa batas. DPIA/penilaian risiko, notice, akses subjek, incident response, dan review Legal/Security adalah gate aktivasi produksi, bukan alasan menunda struktur kode.

## Aturan aktivasi dan bukti penutupan

Semua aturan di atas dapat diturunkan menjadi schema/policy config, command guard, dan test tanpa menebak nilai tersembunyi. Untuk data produksi, setiap legal entity mempunyai `policy_activation` yang memuat versi policy, effective date, approver Finance/Tax/Process Owner, hash simulasi, dan referensi regulasi. Tanpa aktivasi, endpoint mutasi finansial/stok mengembalikan `POLICY_NOT_ACTIVE` dan tidak menulis ledger. Ini adalah kontrol rilis yang eksplisit, bukan pertanyaan desain yang perlu diselesaikan saat coding.

Gate implementasi per slice tetap memerlukan FSD, OpenAPI/event schema, DDL, dan test konkrit menurut [readiness](../implementation-readiness.md) G-08..G-15. Dokumen ini tidak mengklaim bahwa angka default sudah disahkan oleh perusahaan tertentu atau bahwa e-Faktur dan perlakuan khusus otomatis patuh hukum tanpa konfigurasi dan verifikasi Tax.
