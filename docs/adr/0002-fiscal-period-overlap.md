# ADR-0002 — Guard interval fiscal period tanpa extension

**Status:** diterima untuk migration awal. **Tanggal:** 28 Oktober 2026. **Owner:** Finance/DB.

## Konteks

Satu legal entity tidak boleh mempunyai dua fiscal period aktif yang tanggalnya overlap. Exclusion constraint GiST gabungan UUID/range membutuhkan extension `btree_gist`; extension itu tidak tersedia pada PostgreSQL 18 lokal yang dipakai untuk verifikasi.

## Keputusan

Mutation tanggal/soft delete period wajib transaksi `SERIALIZABLE`. Trigger melakukan predicate overlap check per tenant+entity dan menolak transaksi pada isolation lain. Error `40001` menyebabkan retry **seluruh** command dengan idempotency key yang sama; close period mengubah status dan tidak mengubah interval. Runtime role tidak diberi hak menonaktifkan trigger atau DDL. Rujukan: [PostgreSQL transaction isolation](https://www.postgresql.org/docs/18/transaction-iso.html) dan [trigger functions](https://www.postgresql.org/docs/18/plpgsql-trigger.html).

## Konsekuensi dan bukti

Tidak perlu extension tambahan, tetapi create/edit period harus memakai isolation tepat dan menangani serialization retry. Migration [Finance](../../backend/database/migrations/accounting/000001_grni_posting.up.sql) berhasil pada PostgreSQL 18; overlap berurutan ditolak, dan dua insert overlap paralel menghasilkan tepat satu commit.
