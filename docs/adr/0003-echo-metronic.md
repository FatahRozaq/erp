# ADR-0003 — Echo v5 dan Metronic Next.js untuk ERP

**Status:** diterima sebagai baseline desain pada 29 Oktober 2026. **Owner:** Architecture, Backend Lead, Web Lead. **Cakupan:** seluruh roadmap; versi patch dikunci saat scaffold dari artefak resmi yang benar-benar dipakai.

## Keputusan

Backend HTTP Go memakai **Echo v5** (`github.com/labstack/echo/v5`) pada gateway dan API setiap deployable. Go minimal 1.25 mengikuti [persyaratan resmi Echo](https://echo.labstack.com/guide/installation/). Echo hanya adapter transport: routing, middleware, binding DTO, validasi bentuk, error mapping, dan response. Aturan bisnis, transaksi, persistence, outbox/inbox, dan worker tetap berada di modul domain/application; worker tidak mengimpor `echo.Context`.

Web memakai **Metronic Next.js** sebagai shell, design tokens, komponen presentasi, icon, navigasi, dan pola layout. Aplikasi ERP tetap Next.js App Router + TypeScript dengan BFF same-origin dan kontrak OpenAPI kanonik. [Boilerplate resmi](https://docs.keenthemes.com/metronic-nextjs) menyediakan Next.js/App Router, tetapi paket contohnya juga memakai Prisma/Supabase dan auth bawaan. [Panduan custom auth KeenThemes](https://docs.keenthemes.com/metronic-nextjs/guides/custom-auth) menunjukkan pemisahan dependensi itu. ERP memakai OIDC/session BFF sendiri dan **tidak** memberi Metronic akses langsung ke database, token backend, atau aturan bisnis. Dokumen contoh vendor menjadi referensi UI, bukan sumber arsitektur data.

## Alasan dan batas

Echo memberi API HTTP Go yang kecil dengan middleware, sementara batas `adapter → application → domain` membuat service dapat diuji tanpa framework. Echo [mengingatkan agar binding tidak langsung ke business struct](https://echo.labstack.com/guide/binding/); DTO request harus allowlist dan dipetakan eksplisit. [Error handler terpusat](https://echo.labstack.com/guide/error-handling/) dipakai untuk envelope error ERP. Middleware Recover, request logging, secure headers, trusted proxy, timeout, rate limit, dan authz dikonfigurasi eksplisit; default framework bukan bukti aman.

Metronic mempercepat tampilan konsisten, tetapi lisensi dan source vendor harus diperlakukan sebagai aset berizin. Paket Next.js dan versi yang diperoleh dicatat dengan checksum, versi, sumber unduhan resmi, license evidence, dan daftar file yang diadaptasi. Kode vendor terisolasi pada `frontend/nextjs/src/vendor/metronic/` (atau private package internal); fitur ERP hanya mengimpor wrapper `components/ui`/`components/layout` yang dimiliki repo. Perubahan vendor dilakukan lewat upgrade terkontrol, diff, visual regression, accessibility test, dan dependency scan. Jangan mencampur demo data, demo auth, Prisma migration, atau mock credentials vendor ke build produksi.

Menurut [panduan lisensi Metronic KeenThemes](https://keenthemes.com/metronic/tailwind/docs/getting-started/license), hak penggunaan bergantung pada model end product/deployment dan distribusi source. Dokumen pricing dan licensing resmi harus diverifikasi kembali terhadap SKU/kanal pembelian yang nyata sebelum source disalin atau didistribusikan. Karena aset belum diberikan dalam workspace, **integrasi visual Metronic belum dapat diverifikasi**. Paket docs ini hanya memutuskan cara mengintegrasikannya; procurement/license evidence menjadi gate pemasukan aset dan rilis, bukan alasan menebak implementasi UI.

## Konsekuensi dan verifikasi saat scaffold

1. Kunci Go toolchain, Echo v5 patch, dan Next.js/React patch dalam manifest dan lockfile; kunci patch Metronic setelah bundle berizin diterima. Jalankan smoke build dan security scan. Jangan mengasumsikan versi paket dari halaman docs yang bisa berbeda dari bundle dibeli.
2. `cmd/api` membuat `echo.New`, mendaftarkan middleware dan route owner, serta shutdown terkontrol; `adapters/http` berisi DTO/handler/error mapper. Request context yang diteruskan ke application adalah `context.Context` standar dengan principal terverifikasi, bukan `*echo.Context`.
3. Bind body/path/query secara eksplisit ke DTO terpisah; tes unknown field, duplicate key, body limit, nomor decimal, tenant spoofing, path GUID lintas scope, stale ETag, dan panic recovery.
4. Metronic dipakai untuk layout/primitive melalui wrapper lokal; route/feature layer tidak mengimpor vendor langsung. Uji keyboard/focus, WCAG 2.2 AA, dark mode, RTL bila diaktifkan, responsif, CSP, bundle size, dan permission-based navigation.
5. Bila bundle Metronic aktual tidak menyediakan adapter Next.js yang sesuai, Web Lead mempertahankan arsitektur BFF/feature dan mengadaptasi aset resmi yang berizin; perubahan framework atau auth memerlukan ADR baru.
