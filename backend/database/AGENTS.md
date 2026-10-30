# Instruksi agent — database SQL

Baca [instruksi backend](../AGENTS.md), [standar database](../../docs/engineering/database-standards.md), [standar migration/function](../../docs/engineering/database-functions-and-migrations.md), dan [ADR-0006](../../docs/adr/0006-database-sql-layout.md).

- Satu folder `migrations/<schema>/` untuk satu schema PostgreSQL yang nyata. Versi migration berurutan dan immutable per schema; jangan mengubah isi SQL yang pernah dijalankan. Semua DDL, function, trigger dan grant baru untuk schema itu berada dalam migration folder yang sama. Pengecualian baseline lintas schema di `accounting/000001_grni_posting.up.sql` dijelaskan pada ADR-0006; jangan menirunya.
- Satu folder `queries/<schema>/` untuk query bernama sqlc yang dipakai owner schema itu. Query harus memakai parameter terikat dan scope tenant/entity yang sesuai. Jangan menaruh query bisnis di schema owner lain.
- Konfigurasi `sqlc.yaml` memetakan setiap query set aktif ke migration schema dan output adapter Go owner. Tambah mapping saat query pertama di schema itu dibuat; hasil generate tidak diedit manual. Query/function yang tidak didukung parser sqlc tetap memakai adapter typed dan tes PostgreSQL nyata.
- Migration runner menggunakan role deploy tersendiri dan tidak berjalan saat service start. Perubahan DB memerlukan bukti fresh apply, upgrade, privilege, concurrency dan rollback/forward-fix sesuai work order terkait.
