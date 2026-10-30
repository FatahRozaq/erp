# Standar frontend web ERP

**Status:** baseline desain implementasi, 29 Oktober 2026  
**Berlaku untuk:** `frontend/nextjs` (Next.js App Router, TypeScript, acuan UI shadcn-admin MIT)
**Sumber kebutuhan:** [Enterprise ERP PRD](../enterprise-erp-prd.md), terutama bab 33, 36, 38–40, dan 49.

## 1. Keputusan arsitektur

Web adalah klien ERP dan BFF (Backend for Frontend). Gateway/API Go tetap pemilik aturan bisnis, otorisasi, transaksi, audit, `version`, dan kalkulasi final. Next.js mengurus halaman, sesi browser, komposisi data untuk UI, dan endpoint BFF yang diperlukan browser. UI tidak menulis langsung ke basis data atau broker.

Gunakan Next.js 16 App Router dengan [shadcn-admin MIT](https://github.com/satnaing/shadcn-admin) sebagai acuan shell dan sistem UI sesuai [ADR-0005](../adr/0005-shadcn-admin-frontend.md). Template sumber berbasis Vite; adaptasikan komponen yang diperlukan ke Next.js, tanpa membawa router atau demo auth/data Vite. Pin commit/hash sumber dan versi dependency sebelum integrasi visual F-04. `page.tsx` dan `layout.tsx` tetap Server Components secara default; beri `"use client"` hanya pada form, tabel, dialog, dan interaksi browser. Route group untuk layout tidak mengubah URL, sedangkan kode fitur di luar `app` menjaga folder route tetap tipis. Ini sesuai [struktur proyek Next.js](https://nextjs.org/docs/app/getting-started/project-structure) dan [batas Server/Client Components](https://nextjs.org/docs/app/getting-started/server-and-client-components).

Pilih satu alur data: **browser → same-origin BFF Next.js → gateway `/api/v1` → domain Go**. Server Components membaca melalui lapisan akses server yang sama. Jangan membuat *catch-all proxy* yang bebas meneruskan path/header pengguna; setiap route BFF yang diperlukan harus punya method, input, dan upstream tujuan yang eksplisit. OpenAPI per domain di `contracts/openapi/<domain>/v1.yaml` adalah kontrak lintas klien; kode hasil generator di web harus mengikuti kontrak tersebut dan tidak diedit tangan. Pola server-side data access dan DTO minimal mengikuti [panduan keamanan data Next.js](https://nextjs.org/docs/app/guides/data-security).

## 2. Struktur folder

```text
frontend/nextjs/
├── package.json
├── vendor-manifest.json             # commit/checksum/file/lisensi MIT source yang diadaptasi
├── next.config.ts
├── tsconfig.json
├── eslint.config.mjs
├── public/
└── src/
    ├── app/                         # route, layout, metadata, loading/error saja
    │   ├── layout.tsx
    │   ├── (auth)/sign-in/page.tsx
    │   ├── (erp)/layout.tsx
    │   ├── (erp)/sales/orders/page.tsx
    │   ├── (erp)/sales/orders/[guid]/page.tsx
    │   ├── (erp)/sales/orders/[guid]/loading.tsx
    │   ├── (erp)/sales/orders/[guid]/error.tsx
    │   ├── api/auth/callback/route.ts
    │   ├── api/bff/sales-orders/route.ts
    │   └── api/bff/sales-orders/[guid]/submit/route.ts
    ├── components/
    │   ├── ui/                       # wrapper primitive shadcn-admin yang dimiliki repo
    │   └── layout/                   # shell, sidebar, entity switcher
    ├── features/
    │   └── sales-orders/
    │       ├── api/                  # query keys, query/command adapters
    │       ├── components/           # form, grid, detail, history
    │       ├── hooks/                # hook fitur, tanpa fetch mentah
    │       ├── schemas/              # validasi form Zod
    │       ├── model/                # view model/mapper DTO, bukan domain truth
    │       └── tests/
    ├── generated/openapi/           # hasil generator, read-only dalam review
    ├── vendor/shadcn-admin/          # source template MIT yang benar-benar diadaptasi
    ├── lib/
    │   ├── api/                     # transport BFF/browser dan gateway/server
    │   ├── auth/                    # session.server.ts, permission view helpers
    │   ├── errors/                  # normalisasi error API
    │   ├── format/                  # tanggal, uang, UOM, locale
    │   ├── query/                   # QueryClient/provider dan cache lifecycle
    │   └── telemetry/               # request/trace IDs, redaction
    ├── styles/globals.css           # token Tailwind dan tema
    ├── instrumentation.ts           # telemetry server Next.js
    └── proxy.ts                     # redirect optimistis saja, opsional
```

Nama domain mengikuti PRD (`sales-orders`, `purchase-orders`, `inventory`, `finance`, `approvals`, `organization`). Tambah folder fitur saat ada layar/behavior nyata; jangan membuat folder kosong untuk seluruh peta modul. `components/ui` dan `components/layout` adalah wrapper stabil lintas fitur; fitur tidak mengimpor `vendor/shadcn-admin` langsung. Bila nanti ada aplikasi web kedua, barulah ekstrak primitive stabil ke package UI bersama. Adaptasi source [shadcn-admin](https://github.com/satnaing/shadcn-admin) dicatat di vendor manifest beserta lisensi/copyright; demo auth/data dan router Vite tidak masuk domain ERP.

## 3. Aturan dependensi dan penamaan

```text
app route → feature component / server data access
feature component → feature hook / schema / model → lib API → generated OpenAPI type
shared component → token/primitive saja; tidak mengimpor feature
browser API adapter → same-origin BFF; server API adapter → gateway
```

- Folder dan file TypeScript memakai `kebab-case`; komponen dan tipe ekspor `PascalCase`; fungsi/hook `camelCase` (`useSalesOrders`); konstanta tetap `UPPER_SNAKE_CASE`. Nama file route wajib mengikuti konvensi Next.js (`page.tsx`, `route.ts`, `error.tsx`).
- Satu file komponen mengekspor satu komponen utama. Pecah file ketika tanggung jawab UI atau aturan form berbeda, bukan berdasarkan jumlah baris semata. Hindari `utils.ts` global yang mengumpulkan berbagai domain.
- Gunakan `strict`, `noUncheckedIndexedAccess`, dan `exactOptionalPropertyTypes`; setiap `unknown` dari jaringan dinormalisasi pada boundary. Larang `any`, non-null assertion tanpa alasan, dan *type assertion* untuk menyembunyikan mismatch kontrak. Lihat [TypeScript strict](https://www.typescriptlang.org/tsconfig/strict.html), [unchecked indexed access](https://www.typescriptlang.org/tsconfig/noUncheckedIndexedAccess.html), dan [exact optional properties](https://www.typescriptlang.org/tsconfig/exactOptionalPropertyTypes.html).
- Format otomatis dan lint pada CI. Dependensi dipin melalui lockfile; upgrade framework/library lewat PR dengan build dan tes regresi. Jangan mengandalkan API `latest` dalam kode tanpa pin versi mayor.
- `guid` dipakai untuk URL/API, bukan `id` internal DB. `version` dari server dipertahankan dalam detail/edit; tampilan nomor dokumen berbeda dari identitas teknis. Angka uang dan kuantitas presisi ditransfer sebagai string decimal sesuai kontrak, bukan dihitung dengan float JavaScript; semua total otoritatif dari server.

## 4. Sesi, autentikasi, dan otorisasi

1. Browser diarahkan ke IdP lewat OAuth2/OIDC Authorization Code + PKCE. Callback diproses server Next.js; token akses/refresh tersimpan di penyimpanan sesi server yang terenkripsi dan terikat sesi/perangkat. Browser hanya menerima cookie sesi acak `HttpOnly; Secure; SameSite=Lax` (atau lebih ketat bila alur IdP memungkinkan). Token tidak masuk `localStorage`, `sessionStorage`, props, atau JavaScript browser.
2. Setiap request BFF membaca sesi, memperbarui token server-side bila perlu, mengikat `tenant`, `legal entity`, user, dan scope, lalu mengirim kredensial ke gateway. Gateway tetap memeriksa authn/authz/data scope untuk setiap query dan command. Perubahan hak atau revoke sesi harus berlaku pada request berikutnya sesuai kebijakan IAM PRD.
3. Mutasi BFF memeriksa origin dan token CSRF yang terikat sesi; cookie `SameSite` saja tidak cukup sebagai satu-satunya kontrol. Jangan mengekspor Server Action atau route handler mutasi tanpa pemeriksaan sesi, scope, dan CSRF. `proxy.ts` boleh mengalihkan pengguna yang jelas belum login, tetapi bukan penjaga otorisasi final; [panduan autentikasi Next.js](https://nextjs.org/docs/app/guides/authentication) dan [Proxy Next.js 16](https://nextjs.org/docs/app/getting-started/proxy) menekankan pemeriksaan dekat akses data.
4. Navigasi dan tombol disaring berdasarkan permission untuk UX. Direct URL, Server Component, BFF, dan gateway tetap harus aman ketika UI disiasati. Jangan masukkan seluruh permission/scope sensitif ke payload client; kirim subset yang diperlukan layar.
5. Saat logout, tenant/entity/branch berubah, atau permission version berubah: hapus Query cache dan state browser yang mungkin menyimpan data lama; batalkan request lama, lalu ambil ulang context. Render halaman berisi data terikat pengguna secara dinamis; fetch scoped memakai kebijakan tanpa shared cache (`cache: 'no-store'` bila menggunakan `fetch`) dan jangan memberi `"use cache"` pada data user/tenant tanpa desain key serta invalidasi yang ditinjau keamanan. [Panduan cache Next.js](https://nextjs.org/docs/app/getting-started/caching) membedakan data fresh saat request dari data yang sengaja di-cache. Pastikan tab lama tidak menampilkan data tenant sebelumnya setelah switch.

**Baseline IAM web:** sesi opaque acak disimpan server-side di Redis dengan token OIDC terenkripsi memakai key management; cookie hanya berisi session ID, idle timeout 30 menit dan absolute timeout 8 jam sebagai default tenant yang dapat diperketat policy. Rotasi ID saat login/privilege change, revoke menghapus sesi dan menaikkan session version. Mutasi memakai synchronizer CSRF token yang terikat sesi dan pemeriksaan `Origin`; BFF menolak origin lain. Tab menerima sinyal logout/scope change lewat `BroadcastChannel` untuk menghapus cache segera, sedangkan server tetap menolak request revoked walau sinyal tab gagal. IdP konkret dipilih pada konfigurasi deployment melalui discovery OIDC yang dipin issuer/audience; tidak ada cache persistensi data ERP di browser. Session cookie dan token tetap memerlukan rotasi, revoke, audit login, CSP, dan uji replay sesuai PRD.

## 5. Data, state, form, dan tabel

| Jenis state | Pemilik | Aturan |
|---|---|---|
| Data server (order, stok, approval) | API Go; cermin di TanStack Query | Tidak diduplikasi di Zustand/Redux atau `localStorage` |
| Filter/sort/page dan tampilan yang bisa dibagikan | URL search params | URL menjadi sumber state list; validasi/normalisasi parameter |
| Edit form yang belum dikirim | React Hook Form | Berumur selama layar/form; tidak dianggap dokumen tersimpan |
| Dialog, tab lokal, sidebar | React state; Zustand bila benar-benar lintas halaman | Tidak menyimpan data bisnis/PII |
| Token/sesi | BFF server-side | Hanya cookie opaque di browser |

Kunci query wajib memuat semua dimensi yang mengubah hasil: domain, `tenantGuid`, `legalEntityGuid`, branch/scope identifier atau `scopeVersion`, filter, sort, dan page/cursor. Contoh: `['sales-orders', tenantGuid, legalEntityGuid, scopeVersion, {status, page, pageSize, sort}]`. Parameter harus serializable. Sukses command menginvalidasi list/detail/agregat yang terdampak; untuk status kritis baca kembali state server, bukan mengasumsikan perubahan optimistis. Bersihkan cache saat context identitas berubah. Rujukan: [TanStack Query keys](https://tanstack.com/query/latest/docs/framework/react/guides/query-keys) dan [invalidation setelah mutation](https://tanstack.com/query/latest/docs/framework/react/guides/invalidations-from-mutations).

Tabel transaksi memakai pagination, filter, dan sort **di server**. Tabel hanya mengatur interaksi dan kolom; `page_size` default 25, maksimum 200; sort harus allowlist sesuai OpenAPI. Simpan filter yang dapat dibagikan di URL. Selection lintas halaman harus eksplisit (misalnya kumpulan GUID terpilih) dan bulk action menampilkan preview jumlah/dampak sebelum submit. Jangan men-sort hanya satu halaman ketika UI menyatakan seluruh dataset tersortir. [Panduan TanStack Table](https://tanstack.com/table/latest/docs/framework/react/guide/table-state) membahas state tabel yang dikontrol untuk data server; adapter internal mengisolasi perbedaan versi library.

Form memakai React Hook Form dan schema Zod untuk pesan cepat dan typing; `register` untuk input native, `Controller` untuk komponen yang mengelola `value/onChange` sendiri. Schema UI memvalidasi format, batas dasar, dan dependensi field; server tetap menguji scope, price, credit, tax, stok, SoD, dan total. Saat submit, bangun payload OpenAPI yang eksplisit, termasuk `version`/`If-Match` dan `Idempotency-Key` pada command kritis. Lihat [integrasi React Hook Form](https://react-hook-form.com/integrations) dan [Zod safeParse](https://zod.dev/basics).

Gunakan token semantik Tailwind untuk warna/status/spacing; jangan menyebarkan hex dan style ad hoc di fitur. Wrapper lokal menetapkan API komponen agar pembaruan template tidak mengubah setiap feature. Lihat [source shadcn-admin](https://github.com/satnaing/shadcn-admin) dan [Tailwind theme variables](https://tailwindcss.com/docs/theme). Semua aksi punya label, focus state, keyboard flow, empty/loading/error state, dan kontras yang diperiksa; format tanggal dalam timezone terpilih, simpan timestamp UTC, dan tampilkan currency/UOM sumber dengan jelas.

## 6. API dan error UX

- Transport dari generated OpenAPI type ke BFF/gateway menormalkan error menjadi `{status, code, message, details, requestId, retryable}`. Jangan mencocokkan pesan bebas untuk logika. `details` hanya ditampilkan setelah dipastikan aman bagi scope pengguna.
- `401`: hentikan aksi dan mulai pemulihan sesi sekali; setelah gagal, arahkan login sambil menjaga draft form yang aman hanya di memori. `403/404`: tampilkan akses ditolak/tidak ditemukan tanpa membocorkan keberadaan dokumen lintas scope. `422`: petakan field errors dan ringkasan form. `409/412`: ambil versi terbaru dan tampilkan diff/opsi revisi, jangan overwrite diam-diam. `429/503`: beri status dan retry terkontrol hanya untuk operasi aman atau ber-idempotency key.
- Command yang mengubah workflow (`submit`, `approve`, `post`, `cancel`) memakai endpoint aksi, bukan mengubah `status` lewat `PATCH`. Tampilkan status `202` sebagai operasi berjalan, dengan polling/notification berdasarkan kontrak. Simpan `request_id` pada pesan kegagalan agar support dapat menelusuri kejadian.
- Upload memakai endpoint/file URL yang diizinkan BFF, cap ukuran dan tipe, progress, checksum bila kontrak perlu; jangan memasukkan file besar ke JSON. Download/export memerlukan permission dan akses URL singkat sesuai PRD.

## 7. Telemetry, keamanan, dan pengujian

Gunakan `src/instrumentation.ts` untuk telemetry server Next.js sesuai [panduan instrumentation](https://nextjs.org/docs/app/guides/instrumentation). Setiap request BFF membawa `request_id`, `traceparent`/trace ID, dan `correlation_id` bila merupakan rangkaian bisnis. Log event terstruktur seperti `web.sales_order.submit.failed` dengan status/kode/durasi/scope pseudonymous. Jangan log token, cookie, rekening, tax ID, PII, isi form, atau respons penuh. Audit perubahan bisnis tetap dibuat oleh backend; telemetri browser bukan audit sah.

Kontrol web: CSP, security headers, output encoding, URL allowlist, CSRF, body size limit, upload validation, dependency scan, dan tes IDOR/horizontal scope mengikuti PRD bab 38. Jangan menaruh secret pada variabel `NEXT_PUBLIC_*`. Server Components harus mengirim DTO minimum ke Client Components; lihat [panduan data security Next.js](https://nextjs.org/docs/app/guides/data-security).

Gerbang PR untuk fitur web:

1. Lint, format, TypeScript strict, dan build lulus.
2. Uji komponen/form/table pada kasus loading, empty, validasi, error, keyboard, dan focus.
3. Playwright untuk alur kritis: login, switch tenant/entity/scope, create→submit SO, stale `version`, `403/404`, dan logout/cache purge. Data tes sintetis.
4. Mock/fixture jaringan mengikuti OpenAPI, sedangkan uji integrasi terhadap gateway mengonfirmasi status/error/idempotency. Perubahan kontrak dibuat di `contracts/openapi/<domain>/v1.yaml` dahulu lalu generated client diregenerasi.

## 8. Hal yang harus selaras lintas lapisan

- OpenAPI harus menyatakan `guid`, `version`/ETag, decimal string, timezone, pagination, error envelope, `request_id`, `Idempotency-Key`, dan hasil async `202`. Nama field UI tidak mengubah kontrak backend.
- IAM/gateway perlu mengirim identitas context dan versi/sidik scope yang stabil untuk invalidasi cache; bila tidak ada, web harus memaksa clear cache pada setiap perubahan context sesi.
- BFF dan API harus menyepakati cara meneruskan `traceparent`, `request_id`, `correlation_id`, CSRF boundary, dan bagaimana 401/revoke terdeteksi.
- Feature flags pada UI hanya mengendalikan tampilan; invariant dan permission tetap ditegakkan API.
