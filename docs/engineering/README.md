# Indeks Standar Engineering ERP

**Versi baseline:** 29 Oktober 2026. Dokumen ini menetapkan standar sebelum scaffold dan implementasi. [Instruksi agent](../../AGENTS.md) mengarahkan agent ke dokumen sesuai pekerjaan dan direktori stack; dokumen ini tetap memegang detail standar. [PRD](../enterprise-erp-prd.md) tetap menjadi sumber kebutuhan; [keputusan bisnis MVP](../decisions/mvp-business-policy.md) mengisi policy default; [audit kesiapan](../implementation-readiness.md) mencatat pekerjaan per fitur.

| Dokumen | Dipakai saat | Isi utama |
|---|---|---|
| [Repository dan kontrak lintas aplikasi](repository-standards.md) | Membuat folder, ownership, CODEOWNERS, contract dan CI | Pohon repo, dependency boundaries, naming dan tipe data lintas layer |
| [Branch dan commit](git-workflow.md) | Memulai perubahan kode dan mencatat riwayat Git | Branch `feature`/`fix`/`refactor`, judul `feat`/`fix`/`refactor`, body dan bagian Service/Page/Migration |
| [Peta struktur seluruh modul](target-module-structure.md) | Menilai bentuk akhir Foundation sampai Enterprise Expansion | Lokasi modul Go, route/feature Next.js, feature Flutter, migration, tes, dan batas pertumbuhan folder |
| [Backend Go + Echo v5](backend-standards.md) | Membuat service/command/worker | Layer/module folder, handler→domain→repository, API/event, outbox, security, logging, tests |
| [Database PostgreSQL](database-standards.md) | Membuat migration dan model persistence | `id`/`guid`, actor/time/version, soft delete, immutable ledger/audit, FK/index/locking, decimal |
| [Migration dan function DB](database-functions-and-migrations.md) | Mengubah schema dan membuat function PostgreSQL yang dipanggil backend | Versi SQL, signature/grant, transaksi atomik, kompatibilitas, rollback/forward-fix dan tes PostgreSQL |
| [Frontend Next.js + shadcn-admin](frontend-standards.md) | Membuat web dan BFF browser | App Router/feature folders, cookie session, data access, forms/tables, cache, error UX |
| [Mobile Flutter](mobile-standards.md) | Membuat aplikasi salesman/approver/warehouse | Screen/ViewModel/Repository, local encryption, sync P2, device security, tests |

## Aturan penggunaan

1. Baca [keputusan bisnis MVP](../decisions/mvp-business-policy.md) dan [readiness review](../implementation-readiness.md) sebelum mengubah proses stok atau keuangan. Policy produksi tetap memerlukan aktivasi business owner.
2. Mulai dari satu vertical slice dan tambahkan folder yang dipakai, bukan membuat semua modul kosong.
3. Kontrak API/event, migration dan function DB dimiliki domain; perubahan lintas layer dibuat bersama consumer dan diuji kompatibilitasnya.
4. `id` adalah kunci lokal database; `guid` adalah identitas publik/lintas owner. Audit dan log adalah mekanisme berbeda.
5. Penyimpangan dari standar membutuhkan ADR yang mencatat alasan, dampak dan jalur kembali/upgrade.

## Urutan artefak sebelum merge fitur

`PRD requirement → decision bisnis → FSD/command matrix → OpenAPI/event schema → migration schema/function/grant → adapter Go + code → PostgreSQL integration/contract tests → operational runbook`.

Kontrak seluruh roadmap telah lulus [audit gerbang perencanaan](../roadmap/roadmap-planning-gate.md); urutan eksekusi mengikuti [timeline dan work order](../roadmap/implementation-timeline.md). Aplikasi belum dibuat; setiap migration/function baru tetap memerlukan bukti runtime pada slice terkait.
