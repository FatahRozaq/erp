# Instruksi agent — Go/Echo

Backend aktif ada di `backend/golang/services/<owner>/`. Baca [standar backend Go/Echo](../../docs/engineering/backend-standards.md), [standar migration/function](../../docs/engineering/database-functions-and-migrations.md), [standar database](../../docs/engineering/database-standards.md), serta FSD dan kontrak domain yang sedang dikerjakan.

- Echo v5 hanya berada pada adapter HTTP. Handler memetakan request/response dan error; application mengorkestrasi use case; domain menyimpan invariant; adapter PostgreSQL/broker menangani I/O. Jangan impor Echo di domain atau worker.
- Setiap deployable memakai `go.mod` sendiri ketika di-scaffold. `go.work` lokal, bila diperlukan, berada di `backend/golang/`; build CI menguji modul deployable secara terpisah.
- Tempatkan migration di `backend/database/migrations/<schema>/` dan query sqlc di `backend/database/queries/<schema>/`; ikuti [instruksi database](../database/AGENTS.md). Function PostgreSQL yang dipanggil Go memiliki signature typed, grant minimum, wrapper typed di adapter PostgreSQL, dan integration/concurrency test pada PostgreSQL asli. Jangan menaruh DDL di handler, startup, atau SQL manual produksi.
- Uji auth/scope, idempotency, `If-Match`/version, error aman, duplicate/retry, race, audit/outbox atomik, dan reconciliation untuk command yang berubah.

`services/` berisi aplikasi Go; source SQL kanonik berada di `backend/database/`. Tambahkan modul aplikasi, query dan migration hanya saat slice terkait dikerjakan.
