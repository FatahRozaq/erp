# Standar branch dan commit

**Berlaku untuk:** seluruh repository ERP. **Remote utama:** `https://github.com/FatahRozaq/erp`. **Baseline:** 30 Oktober 2026. Aturan ini berlaku untuk perubahan berikutnya; commit historis tidak ditulis ulang.

## Branch

- Perubahan perencanaan awal (PRD, FSD, ADR, roadmap, standar) dikerjakan di `main` selama belum mulai mengimplementasikan kode work order terkait.
- Setiap pekerjaan kode dimulai dari `main` terbaru pada **branch baru**. Satu branch memuat satu work order/slice atau satu perbaikan yang koheren. Jangan memakai ulang branch dari pekerjaan sebelumnya.
- Format branch AI: `codex/<type>/<scope>-<ringkasan>`. `<type>` hanya `feature`, `fix`, atau `refactor`. Nama menggunakan huruf kecil, angka dan tanda hubung; singkat dan mudah dicari. Prefix `codex/` mengidentifikasi branch yang dibuat agent. Jika developer manusia membuat branch, format tanpa prefix `codex/` juga boleh.
- `feature` untuk kemampuan baru; `fix` untuk koreksi perilaku; `refactor` untuk perubahan struktur tanpa mengubah perilaku. Perubahan schema/DB function yang mendukung fitur mengikuti jenis pekerjaan utamanya.
- Buat pull request ke `main`, jalankan CI dan review owner yang relevan sebelum merge. Jangan menandai gate/work order selesai hanya karena branch atau PR sudah ada.

Contoh:

```text
codex/feature/b-02-migration-runner
codex/feature/sales-invoice-crud
codex/fix/sales-invoice-duplicate-posting
codex/refactor/gateway-http-router
```

## Commit

Format judul:

```text
<type>(<scope>): <ringkasan imperatif>
```

`<type>` hanya `feat`, `fix`, atau `refactor`; ini dipetakan dari branch `feature`, `fix`, atau `refactor`. `<scope>` adalah modul/fitur yang diubah, memakai `snake_case` seperti `sales_invoice`, `inventory`, `auth`, atau `web_shell`. Judul berbahasa Inggris, menjelaskan hasil, tanpa titik akhir. Usahakan maksimal 72 karakter.

Body berisi perubahan yang dapat diperiksa, lalu bagian `[Service]`, `[Page]`, dan/atau `[Migration]` **yang relevan**. Bagian yang tidak terdampak tidak perlu ditulis. Isi dengan nama service, route/page, atau file migration/function yang nyata. Untuk perubahan lintas layer, cantumkan ketiganya; jangan menganggap migration sudah berjalan hanya karena filenya ada. Pisahkan judul dan body dengan satu baris kosong.

```text
feat(sales_invoice): add sales invoice CRUD

- add sales invoice endpoints and contract-aligned validation
- add invoice list and detail views
- add versioned invoice schema and posting function

[Service]
- finance: sales invoice API

[Page]
- /sales/invoices
- /sales/invoices/[guid]

[Migration]
- backend/golang/services/finance/migrations/<version>_sales_invoice.sql
```

Contoh tanpa migration:

```text
fix(sales_invoice): prevent duplicate invoice submission

- reject a repeated submit command with the existing result

[Service]
- finance: sales invoice API
```

Sebelum commit, jalankan format, tes dan pemeriksaan kontrak yang relevan; catat hasilnya di PR atau bukti work order. Jangan masukkan credential, data produksi, atau file hasil build ke commit.
