# ADR-0004 — Migration dan function PostgreSQL berversi

**Status:** diterima sebagai baseline desain pada 29 Oktober 2026. **Owner:** Architecture, Database Lead, Backend Leads. **Cakupan:** semua deployable Go/Echo dan seluruh roadmap. Rincian operasional ada di [standar function/migration](../engineering/database-functions-and-migrations.md).

## Keputusan

Semua perubahan schema, index, trigger, role/grant, seed terkendali, dan **function PostgreSQL** dipasang lewat migration SQL milik owner. Backend Go memanggil function database pada operasi yang membutuhkan invariant atomik dekat data, misalnya alokasi nomor, reservasi kredit/stock, penerapan movement, posting jurnal seimbang, dan claim job. Function bukan tempat untuk HTTP auth, UI, panggilan jaringan, atau saga lintas owner. Application Go tetap memvalidasi principal/scope, mengorkestrasi use case dan transaksi, serta menulis audit/outbox dalam transaksi owner yang sama.

Function menggunakan nama schema-qualified `schema.verb_object_vN`, parameter/return typed, `SECURITY INVOKER` sebagai default, volatility yang benar, dan hak `EXECUTE` minimum. Perubahan implementasi yang kompatibel boleh memakai `CREATE OR REPLACE FUNCTION` melalui migration baru; perubahan signature/return/semantik memerlukan function `v2`, caller migration, masa kompatibilitas, lalu contract terpisah. [PostgreSQL CREATE FUNCTION](https://www.postgresql.org/docs/18/sql-createfunction.html) tidak mengizinkan perubahan return type melalui `OR REPLACE` dan mempertahankan ownership/permission lama. Function `SECURITY DEFINER` memerlukan review keamanan khusus dan `search_path` yang hanya memuat schema tepercaya dengan `pg_temp` terakhir.

## Konsekuensi

1. Setiap work order yang mengubah invariant data menilai apakah constraint, SQL statement CAS, atau function adalah bentuk terkecil yang benar. Keputusan dicatat di review. Function wajib untuk kelas operasi atomik yang ditetapkan di [standar](../engineering/database-functions-and-migrations.md#2-function-yang-direncanakan-per-owner), bukan dibuat untuk setiap CRUD.
2. Migration yang sudah dijalankan tidak diedit. Transisi memakai expand → backfill → verifikasi → switch → contract, dengan rollback atau forward-fix sesuai sifat data. Function `v1` dan `v2` dapat hidup berdampingan selama rolling deploy.
3. Tes PostgreSQL asli membuktikan hasil, race, scope, privilege, duplicate, error mapping, dan integrasi function dengan audit/outbox. Unit Go saja tidak cukup.
4. SQL function/trigger awal di migration lama menjadi baseline historis; jika perlu hardening privilege/`search_path`, tambahkan migration baru, bukan menulis ulang file lama.
