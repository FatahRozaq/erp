# OPS-001 — Rencana migrasi data, cutover, backup dan incident MVP

**Scope:** pilot satu LegalEntity beberapa Branch/Warehouse; mode multi entity tetap ada sejak awal. Ini rencana pelaksanaan, bukan bukti restore/cutover sudah berhasil. Mengikuti [PRD §§41–52](../enterprise-erp-prd.md#41-data-migration), [G-16 retention](../decisions/mvp-business-policy.md#g-16oq-09--data-retensi-dan-lokasi-operasi-indonesia), [model data](../features/mvp-physical-data-design.md) dan [SLO](../engineering/slo-workload.md). PM, Data Steward, Controller, Operations Lead, Security dan SRE memberi tanda terima sebelum produksi.

## Data mapping dan rehearsal

| Urutan | Source→target | Aturan mapping/validasi | Bukti sign-off |
|---|---|---|---|
| 1 | legacy org/users→tenant/company/entity/branch/warehouse/membership | canonical GUID baru + external identity map; parent/scope, user status dan SoD review | Security + Sponsor |
| 2 | SKU/UOM/customer/vendor→master | code/alias de-dup, conversion version, tax/profile/bank masked; bad rows quarantine | Master Steward + Tax |
| 3 | COA, tax/price/credit/approval/posting rule→policy versions | account mapping per entity, simulation fixture, active interval, two approvers | Controller + Tax + Process Owners |
| 4 | opening inventory by SKU/warehouse/lot/status/ownership→movement awal | qty/value/average cost, expiry/serial, negative reject; GL inventory control reconcile | Inventory Controller |
| 5 | opening AR/AP and deposits→open items/journal | party/invoice/due date/currency/FX/tax source, allocated/unapplied; control account reconcile | AR/AP + Controller |
| 6 | document/attachment evidence→private object+metadata | SHA-256, MIME/scan, retention class, source GUID; no public URL | Security + Legal |

Setiap import memakai template/version, external source ID, file hash, row result, dry run, exception list dan idempotent commit. Rehearsal minimal dua kali pada staging volume representatif: pertama menemukan mapping/quality gap, kedua membuktikan durasi, restartability, reconciliation dan rollback. Data produksi tetap di region Indonesia sesuai policy; snapshot dimasking bila dipakai untuk testing. Mapping/exceptions disimpan sebagai manifest berversi, bukan spreadsheet lokal tanpa audit.

## Cutover dan keputusan go/no-go

1. Tetapkan cutoff timestamp dalam timezone entity, scope pilot, owner kontak, komunikasi pengguna dan freeze window; hentikan source writes atau gunakan CDC dengan watermark disetujui.
2. Ambil backup/PITR marker dan digest source; verifikasi restore ke lingkungan terisolasi sebelum switch.
3. Jalankan import berurutan sesuai tabel; rekonsiliasi row count, total qty/value stok, AR/AP per party, trial balance, open GRNI, tax documents dan attachment hash. Semua delta punya resolution/ticket; unexplained delta=0.
4. Aktifkan policy versions, role grants dan feature flags per entity; lakukan smoke test authz, SO/PO/GRN/POD/invoice/payment/journal dengan data sintetis terisolasi atau transaksi kontrol yang disetujui.
5. Go/no-go ditandatangani PM, Controller, Security, SRE dan owner operasional. Kriteria: security critical/high resolved, double posting/negative stock/unexplained ledger delta=0, backup/restore valid, latency/error dalam SLO, support runbook tersedia.
6. Ramp bertahap branch/user; hypercare 2–4 minggu, dashboard dan exception queue dipantau harian; tutup pilot dengan reconciliation signed dan keputusan rollout.

Rollback aplikasi memakai image sebelumnya selama schema expand kompatibel; data yang sudah posted **tidak** dihapus atau diputar balik melalui down migration. Jika pilot gagal setelah transaksi nyata, hentikan command berisiko, rekonsiliasi source/journal, lalu gunakan correction/reversal terdokumentasi atau forward fix. Point-in-time restore ke produksi hanya melalui prosedur incident/disaster dengan keputusan Controller karena dapat menghilangkan transaksi yang sudah diakui; simpan evidence dan replay source yang sah.

## Runbook minimum

| Insiden/sinyal | Respons operator | Bukti keluar |
|---|---|---|
| outbox lag/DLQ naik | cek owner event/version, retry bounded, replay terotorisasi; jangan publish raw duplicate manual | inbox dedup dan source projection reconcile |
| POD accepted pending Finance | cek dispatch cost snapshot, tax/account/period; retry op GUID sama setelah root cause | invoice/journal satu kali, delivery ack |
| GRNI/AP mismatch | bandingkan PO/GRN/vendor invoice source; tahan period close, koreksi dokumen baru | GRNI aging dan AP control zero delta |
| stock ledger vs balance mismatch | hentikan posting SKU/scope berisiko, ambil snapshot/log, reconcile movement | no negative stock, correction approved |
| auth/session compromise | revoke session version/credential, isolasi device/service, audit accesses | token lama ditolak, scope leakage terukur |
| backup/DB outage | failover sesuai tested playbook; restore isolated lebih dulu, ukur RPO/RTO | restore checksum, journals/source consistency |

Dashboard minimum: API p50/p95/p99 dan 5xx, DB pool/slow query, outbox oldest age/DLQ, pending saga, stock/GL/AR/AP reconciliation deltas, backup age/success, session revoke latency, object scan queue. Alert punya owner, severity, threshold dan runbook link. Nilai threshold final dipasang setelah baseline workload pilot; jangan mengklaim 99,9%/RPO/RTO tercapai tanpa pengukuran.
