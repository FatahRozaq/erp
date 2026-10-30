# Instruksi agent — backend

Berlaku untuk seluruh `backend/`, termasuk stack backend yang mungkin ditambahkan kelak. Baca [instruksi root](../AGENTS.md), [standar repository](../docs/engineering/repository-standards.md), [standar database](../docs/engineering/database-standards.md), dan [standar migration/function](../docs/engineering/database-functions-and-migrations.md) sebelum mengubah persistence atau kontrak. SQL kanonik berada di [database/](database/README.md), setara dengan direktori `golang/`.

- Setiap domain memiliki owner untuk tabel, command, event, dan audit. Jangan menulis tabel owner lain atau membuat jalur SQL lintas owner.
- Gunakan migration berversi untuk schema, index, constraint, trigger, function, dan grant. Runtime tidak menjalankan DDL saat startup; migration runner memakai role terpisah. Bukti deploy, compatibility, rollback atau forward-fix, dan uji PostgreSQL menyertai perubahan.
- Catat `id`, `guid`, actor/timestamp create-update-delete, `version`, audit log, dan application log sesuai standar database; jangan keluarkan internal `id` atau data sensitif melalui API/log.
- Jaga idempotency, optimistic concurrency, authorization dan scope tenant/entity pada setiap command. Outbox/inbox dan audit berada dalam transaksi owner yang sesuai.
- Kontrak HTTP/event berasal dari `contracts/`; perubahan yang memengaruhi consumer harus mempertahankan compatibility atau memakai versi baru.

Aturan implementasi Go saat ini ada di [golang/AGENTS.md](golang/AGENTS.md). Stack backend lain memerlukan instruksi spesifik sendiri tanpa mengganti baseline Go/Echo.
