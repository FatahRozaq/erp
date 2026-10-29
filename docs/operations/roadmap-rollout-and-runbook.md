# OPS-RM — Rollout, cutover, dan pemulihan sampai Enterprise Expansion

**Baseline:** 29 Oktober 2026. [Runbook MVP](mvp-cutover-and-runbook.md) berlaku untuk Foundation+MVP; dokumen ini menambah gate Phase 2, Phase 3 dan Enterprise Expansion. Setiap aktivasi per legal entity/branch memakai feature flag default OFF, policy version terbit, data migration tervalidasi, owner bisnis, dan bukti uji pada [QA-RM](../roadmap/roadmap-test-vectors.md). Menggabungkan kode tidak mengaktifkan transaksi nyata.

## Urutan per tahap

| Tahap | Prasyarat aktivasi | Sinyal go/no-go | Pemulihan |
|---|---|---|---|
| Phase 2 | RFQ/blanket dan return source reconciliation; transfer/bin/count stock parity; device scope, offline cursor, push permission; route consent | Tidak ada unexplained stock delta, duplicate award/release/return, atau sync command hilang; 95% order offline valid tersinkron ≤15 menit setelah koneksi stabil di pilot | Matikan flag command baru, pertahankan read/replay; pending transfer/return tetap EXCEPTION hingga owner menyelesaikan, jangan hapus movement |
| Phase 3 | Approval DAG dan SoD simulation; budget/expense account mapping; bank statement source mapping; FX/tax policy; connector secret dan replay window; dua entity intercompany aktif | Budget available tidak negatif, journal seimbang, reconciliation nol unexplained, duplicate webhook tidak membuat command kedua, intercompany pair cocok | Pause scheduler/connector/command baru; tahan posting pending; posting salah dikoreksi dengan dokumen pembalik, bukan rewrite ledger |
| Enterprise Expansion | BOM/cost/WIP mapping; POS provider sandbox→production proof dan register close; carrier consent/evidence; reporting store source watermark dan lineage; forecast review owner | WO WIP+finished reconcile, POS capture/stock/journal/receipt satu kali, TMS tidak mengganti POD, dashboard watermark sesuai owner, forecast hanya rekomendasi | Disable checkout/WO release/plan assignment baru; provider outcome unknown masuk reconciler; report stale diblokir, fallback ke owner report; split service rollback sesuai ADR khusus |

## Checklist cutover yang wajib diisi pada implementasi

1. Catat build/contract/schema/flag/policy version, tenant/entity/branch scope, owner dan waktu perubahan; simpan snapshot backup serta hasil restore rehearsal.
2. Terapkan migration expand yang kompatibel, termasuk function/trigger/grant PostgreSQL berversi; backfill dengan checkpoint, validasi signature/privilege function, row count/hash/FK/unique dan parity ledger. Switch read/caller function hanya setelah versi lama dan baru lulus dual-run; contract cleanup dikerjakan pada rilis berikutnya. Jangan rollback posted finance/stock dengan menghapus baris.
3. Jalankan contract tests producer/consumer, authz/SoD/idempotency/concurrency, replay duplikat dan out-of-order, fault injection dependency, serta UAT numerik tahap terkait. Bukti harus merujuk operation ID dan data sintetis/tenant pilot yang disetujui.
4. Aktifkan flag secara berurutan: internal sandbox → satu entity/branch pilot → cohort bertambah. Pantau error code, pending age, DLQ, outbox/inbox lag, stock/GL reconciliation, bank/intercompany mismatch, provider unknown, sync lag, serta report watermark. Target SLO mengikuti [baseline](../engineering/slo-workload.md) dan diperketat dari pengukuran nyata.
5. Go/no-go diputus oleh Product, process owner, Controller/Tax untuk financial flow, Security untuk akses/integrasi, dan Ops/SRE untuk kapasitas/restore. Simpan keputusan dan exception dengan owner, severity dan tanggal tutup.

## Jalur pemulihan

- **API/worker gagal:** hentikan command baru lewat flag; worker retry memakai operation GUID, inbox dedup dan bounded backoff. Replay DLQ diaudit setelah penyebab diperbaiki. Jangan mengubah event ID atau aggregate version lama.
- **Stok/keuangan tidak cocok:** bekukan posting pada scope yang terdampak; bandingkan source movement/journal/portion dengan watermark dan operation GUID; perbaiki lewat adjustment/reversal berizin di periode OPEN, lalu jalankan rekonsiliasi ulang.
- **Connector/payment provider timeout:** status `UNKNOWN`/`PENDING` ditahan. Query status provider berdasar external ID sebelum retry/capture/refund. Callback ditolak bila signature, timestamp atau source scope tidak valid.
- **Offline mobile:** revoke membatalkan cursor dan token scoped; reset snapshot membuat cursor baru tanpa menerima command yang telah dicabut. Bukti yang belum aman di server tetap lokal terenkripsi sampai ack atau operator menyelesaikan exception.
- **Reporting/forecast stale:** dashboard menampilkan `as_of` dan status STALE; export resmi dihentikan sampai gap/replay dan parity selesai. Forecast lama tidak boleh diam-diam dipakai untuk keputusan baru.
- **Service split opsional:** ADR per split memuat owner data, dual-run parity, cutover point, dan rollback binary/schema yang kompatibel. Bila invoice dan journal dipisah, `POSTING_PENDING` harus terlihat dan period close menolak pending.

Runbook operasional per tenant melengkapi nilai yang tidak boleh ditebak dari desain: endpoint IdP/provider, secret reference, rekening/COA, tax rule, carrier, volume, jadwal, personel on-call dan persetujuan lisensi aset Metronic. Ini adalah input aktivasi lingkungan nyata, bukan alasan untuk menunda penulisan handler terhadap kontrak sintetis.
