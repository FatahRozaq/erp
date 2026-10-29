# Instruksi agent — Metronic Next.js

Frontend aktif akan di-scaffold di `frontend/nextjs/`. Baca [standar frontend](../../docs/engineering/frontend-standards.md), [ADR Echo/Metronic](../../docs/adr/0003-echo-metronic.md), FSD/UX layar, dan kontrak OpenAPI terkait.

- Gunakan Next.js App Router dan TypeScript. Route/layout tetap tipis; kode fitur berada di `src/features/`; wrapper UI di `src/components/`; aset Metronic berizin terisolasi di `src/vendor/metronic/` dan dilacak di vendor manifest.
- Alur data browser → same-origin BFF Next.js → Go gateway. BFF memeriksa sesi, scope, origin/CSRF pada mutasi; gateway tetap memutuskan authorization dan aturan bisnis. Hindari catch-all proxy dan data ERP dalam cache bersama.
- Generated OpenAPI client/type tidak diedit manual. Terapkan `guid`, decimal string, `version`/ETag, error code, dan request ID sesuai kontrak.
- Jangan menyalin demo auth, demo data, secret, atau migration vendor Metronic ke aplikasi ERP. Integrasi aset menunggu source dan lisensi yang sah.

`src/` dibuat pada work order scaffold; struktur detailnya ada pada standar frontend.
