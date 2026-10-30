# Database SQL ERP

Direktori ini berada setara dengan `backend/golang/`. `migrations/<schema>/` adalah source DDL/function/grant PostgreSQL kanonik. `queries/<schema>/` berisi query bernama untuk [sqlc](https://docs.sqlc.dev/en/latest/reference/config.html). Kode Go hasil generate berada di adapter PostgreSQL service owner, bukan di folder SQL kanonik.

| Schema saat ini | Owner service |
|---|---|
| `master`, `platform_runtime` | `platform` |
| `purchase`, `sales`, `commercial_runtime` | `commercial` |
| `inventory`, `operations_runtime` | `operations` |
| `finance`, `accounting`, `finance_runtime` | `finance` |

`runtime` lama adalah empat schema berbeda; karena itu foldernya memakai nama `platform_runtime`, `commercial_runtime`, `operations_runtime`, dan `finance_runtime`. Nomor migration dihitung per schema. Sebelas file baseline dipindahkan tanpa mengubah isi; SHA-256-nya dijaga oleh `scripts/check_migration_inventory.py`. Satu pengecualian baseline: `migrations/accounting/000001_grni_posting.up.sql` juga membuat `finance.posting_intents` dan schema `finance`. Karena checksum harus tetap, runner B-02 menerapkan `accounting/000001` sebelum `finance/000001`; migration baru hanya mengubah schema foldernya sendiri. Lihat [ADR-0006](../../docs/adr/0006-database-sql-layout.md).

## sqlc

`sqlc.yaml` memakai format konfigurasi v2. Mapping pertama untuk `master` memakai `queries/master/uoms.sql` dan menghasilkan Go pada adapter Platform. Tambah mapping per schema hanya ketika query pertama tersedia; tiap mapping menunjuk ke `migrations/<schema>/`, `queries/<schema>/` dan output package service pemiliknya. Jalankan dari folder ini:

```bash
sqlc generate
```

Gunakan sqlc v1.31.1 yang dipin di CI. Review perubahan query dan generated Go dalam PR yang sama; jangan edit file generated secara manual. sqlc [membaca direktori migration untuk schema dan mengabaikan down migration](https://docs.sqlc.dev/en/latest/howto/ddl.html), tetapi **tidak menjalankan migration**. Migration runner B-02 tetap memakai role deploy, checksum, lock dan rollback/forward-fix terpisah.

Query hanya membaca/menulis tabel owner sesuai kontrak dan scope. Untuk SQL PostgreSQL yang tidak dipahami sqlc (misalnya function PL/pgSQL tertentu), gunakan wrapper typed di adapter Go dan tes terhadap PostgreSQL asli. File migration yang sudah dijalankan immutable; pemindahan folder ini tidak mengganti nomor maupun isi SQL.
