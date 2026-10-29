# SLO dan workload baseline MVP

**Status:** target desain, bukan hasil benchmark. **Owner:** SRE/QA/Product. Target ini ditetapkan sebagai asumsi awal dan ditinjau dari data pilot. Definisi SLI/error budget mengikuti [Google SRE Workbook](https://sre.google/workbook/implementing-slos/).

| Kelas | Contoh | SLI dan target rolling 28 hari | Timeout user |
|---|---|---|---|
| Read sederhana | detail SKU/PO/SO, balance satu SKU | availability valid response ≥99,9%; p95 server ≤300 ms, p99 ≤800 ms | 5 s |
| List/filter | PO/SO/invoice list 25 rows scoped | availability ≥99,9%; p95 server ≤600 ms, p99 ≤1,5 s | 8 s |
| Command sinkron | create/submit/approve/post GRN | accepted outcome or explicit domain error ≥99,9%; p95 ≤1 s, p99 ≤3 s | 10 s |
| Query kompleks | aging, stock valuation, trial balance | p95 ≤3 s, p99 ≤8 s pada dataset benchmark; long query jadi async job | 15 s |
| Saga/event | POD accepted→Finance posted | ≥99,5% selesai ≤2 menit; 100% pending terlihat dan alert setelah 5 menit | UI tampil pending |
| Mobile sync P2 | batch 50 commands, delta 500 records | p95 ≤5 s pada jaringan uji; retry aman tanpa duplikasi | 15 s |

Availability dihitung dari request valid yang tidak berakhir 5xx/timeout; 4xx domain/auth yang benar tidak dihitung kegagalan layanan, tetapi dipantau untuk UX. Latency diukur di edge untuk respons sinkron, dari accept→posted untuk saga; exclude health checks dan traffic benchmark. Error budget 99,9% = sekitar 40,32 menit per 28 hari; burn rate cepat memicu on-call, konsumsi budget tinggi membatasi rilis berisiko sampai pulih. Ini target produk, bukan angka yang diklaim sebagai kewajiban standar.

**Profil uji awal:** 1 tenant pilot, 2 legal entity, 20 branch, 10 warehouse, 50 ribu SKU, 100 ribu customer, 1 juta SO/tahun, 3 juta movement/tahun, 500 concurrent web users, peak 100 read/s + 20 command/s, data aktif 24 bulan. Jalankan 30 menit steady + 10 menit peak 2× + 5 menit retry/duplicate storm dengan dataset terdistribusi realistis. Lingkungan benchmark: PostgreSQL 18 dedicated 8 vCPU/32 GiB, app 4 replica × 2 vCPU/4 GiB, broker 3 node, latensi DB p95 <5 ms; network klien 50 ms RTT web, mobile 150 ms RTT dan 2% loss. Ini **fixture pengujian**, bukan sizing produksi.

Tes k6/Postman untuk HTTP memakai auth/scope nyata dan request mix 60% read sederhana, 20% list, 10% command, 10% kompleks; command menggunakan data unik dan reset fixture, bukan membuat duplikasi tak sengaja. Playwright mengukur lima tugas pengguna: cari SKU, buat+submit PO, post receipt parsial, buat+submit SO, lihat invoice dan status Finance. UAT mencatat task completion, p95 durasi, kesalahan dan akses keyboard; target awal ≥95% berhasil tanpa bantuan pada skenario normal. Setelah pilot, kalibrasi target berdasarkan telemetry dan keputusan Product/SRE, tanpa diam-diam menurunkan SLO.
