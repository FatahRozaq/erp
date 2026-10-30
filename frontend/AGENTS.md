# Instruksi agent — frontend

Berlaku untuk seluruh `frontend/`. Baca [instruksi root](../AGENTS.md), [standar repository](../docs/engineering/repository-standards.md), PRD/FSD layar yang dikerjakan, serta kontrak di `contracts/openapi/`.

- Frontend mengikuti kontrak API kanonik dan identitas publik `guid`; `id` database tidak menjadi route atau state klien. Decimal, waktu, versi dokumen, dan error code mengikuti kontrak.
- UI tidak menjadi pemilik authorization, transaksi, audit, atau perhitungan final; semua mutasi harus melalui backend yang memeriksa scope.
- Simpan kode per fitur, komponen bersama hanya untuk primitive stabil, dan kode vendor/generated terisolasi. Uji layar loading, error, empty, permission, stale version, aksesibilitas, dan alur pengguna yang berubah.
- Jangan simpan token atau data sensitif dalam browser storage/log; ikuti threat model dan standar stack.

Aturan implementasi web saat ini ada di [nextjs/AGENTS.md](nextjs/AGENTS.md). Stack frontend lain memerlukan instruksi spesifik sendiri tanpa mengganti baseline Next.js dengan acuan shadcn-admin.
