# Instruksi agent — Next.js dengan acuan shadcn-admin

Frontend aktif akan di-scaffold di `frontend/nextjs/`. Baca [standar frontend](../../docs/engineering/frontend-standards.md), [ADR template shadcn-admin](../../docs/adr/0005-shadcn-admin-frontend.md), FSD/UX layar, dan kontrak OpenAPI terkait.

- Gunakan Next.js App Router dan TypeScript. Route/layout tetap tipis; kode fitur berada di `src/features/`; wrapper UI di `src/components/`; source shadcn-admin yang diadaptasi terisolasi di `src/vendor/shadcn-admin/` dan dilacak di vendor manifest.
- Alur data browser → same-origin BFF Next.js → Go gateway. BFF memeriksa sesi, scope, origin/CSRF pada mutasi; gateway tetap memutuskan authorization dan aturan bisnis. Hindari catch-all proxy dan data ERP dalam cache bersama.
- Generated OpenAPI client/type tidak diedit manual. Terapkan `guid`, decimal string, `version`/ETag, error code, dan request ID sesuai kontrak.
- Jangan menyalin demo auth, demo data, secret, atau router Vite ke aplikasi ERP. Pin commit sumber, catat checksum/file yang diadaptasi di manifest dan pertahankan pemberitahuan lisensi MIT.

`src/` dibuat pada work order scaffold; struktur detailnya ada pada standar frontend.
