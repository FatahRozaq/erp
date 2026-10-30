# ADR-0005 — Template gratis shadcn-admin untuk frontend ERP

**Status:** diterima 30 Oktober 2026. **Owner:** Product, Architecture, Web Lead. **Menggantikan:** keputusan template Metronic pada ADR-0003; keputusan Go/Echo v5 dan Next.js pada ADR-0003 tetap berlaku.

## Keputusan

Frontend aktif tetap `frontend/nextjs/` dengan Next.js 16 App Router, React dan TypeScript. Acuan visual dan komponen admin adalah [shadcn-admin oleh Sat Naing](https://github.com/satnaing/shadcn-admin), khususnya [halaman Users](https://shadcn-admin.netlify.app/users). Repository sumber memakai **Vite**, sehingga tidak dijalankan sebagai aplikasi kedua dan tidak mengganti Next.js/BFF. Web Lead mengadaptasi hanya pola/komponen yang diperlukan ke wrapper `src/components/ui` dan `src/components/layout`, dengan route, data, sesi, dan auth ERP milik aplikasi ini.

Source template berlisensi [MIT](https://github.com/satnaing/shadcn-admin/blob/main/LICENSE). Sebelum menyalin bagian source, pin commit/tag dan checksum, catat daftar file serta dependency dalam `frontend/nextjs/vendor-manifest.json`, dan sertakan pemberitahuan copyright serta teks lisensi MIT untuk bagian yang dipakai. Audit lisensi dependency dan aset (terutama gambar/font) secara terpisah; jangan menyamakan lisensi repository dengan hak pakai semua aset pihak ketiga. Selama belum ada source yang diadaptasi, manifest berstatus `selected-not-integrated`.

## Batas implementasi dan penerimaan

- UI memakai token semantik Tailwind, komponen aksesibel dan wrapper lokal. Kode fitur tidak mengimpor template langsung. Tampilan dapat mengacu pada navigasi, tabel, filter dan state halaman Users; permission, tenant scope, data, audit dan aturan bisnis tetap berasal dari kontrak ERP.
- Jangan membawa demo auth, mock user, credential, endpoint, router Vite, atau storage contoh ke runtime ERP. Browser melalui BFF same-origin Next.js menuju Go gateway; Go tetap memutuskan authorization.
- F-04 menerima bukti manifest commit/hash/file/lisensi, build Next.js dan Flutter, uji login/logout/entity switch, cache purge, keyboard/focus, responsif dan WCAG 2.2 AA. G0 tidak lagi menunggu pengadaan Metronic; input pilot, IdP dan policy aktual tetap mengikuti register R-02.
- Perubahan ke Vite sebagai stack aktif memerlukan keputusan arsitektur baru dan perubahan requirement eksplisit.

## Alasan

Pengguna memilih template gratis pada 30 Oktober 2026. Kode sumber resminya tersedia dengan lisensi MIT. Adaptasi ke Next.js menjaga struktur, BFF, kontrak dan CI yang sudah disiapkan pada B-01 sambil memungkinkan UI yang dipilih dipakai tanpa biaya lisensi Metronic.
