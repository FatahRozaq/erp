# Instruksi agent — mobile

Berlaku untuk seluruh `mobile/`. Baca [instruksi root](../AGENTS.md), [standar repository](../docs/engineering/repository-standards.md), FSD fitur dan kontrak API/event yang relevan.

- Server tetap authoritative untuk stok, kredit, harga, approval, posting, dan scope. Klien memakai `guid` publik, `version`, idempotency key, dan error code kontrak.
- Data lokal dan credential mengikuti kebijakan enkripsi, retensi, revoke, serta redaksi telemetry. Jangan simpan token dalam log atau penyimpanan biasa.
- Fitur offline dan sync mengikuti scope fase dalam roadmap; jangan memindahkan fitur P2 ke MVP hanya karena struktur kodenya disiapkan.
- Uji alur online/offline, restart, duplicate/retry, scope revoke, dan konflik sesuai fitur yang diimplementasikan pada perangkat target.

Aturan implementasi aktif ada di [flutter/AGENTS.md](flutter/AGENTS.md). Stack mobile lain memerlukan instruksi spesifik sendiri tanpa mengganti baseline Flutter.
