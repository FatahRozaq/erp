# ADR-0007 — Runner migration transaksional dan role database

**Status:** diterima untuk B-02.1, 30 Oktober 2026. **Owner:** Platform/SRE, Database Lead.

## Keputusan

Tool Go terpisah di `backend/golang/tools/migrate` membaca manifest owner/dependency dan SQL di `backend/database/`. Empat database owner tetap terpisah. Setiap invocation menggunakan satu koneksi deploy khusus, mengambil session advisory lock untuk seluruh schema owner dalam urutan nama, memvalidasi semua history, lalu menjalankan schema sesuai dependency. `accounting/000001` mendahului `finance/000001` sesuai ADR-0006. Mengunci seluruh schema owner juga melindungi baseline lintas schema dan inisialisasi ledger dari runner bersamaan.

Ledger privat `erp_migration.history` ber-key `(schema_name, version)` menyimpan nama file, SHA-256, actor role, waktu dan durasi. SQL dan row ledger commit dalam satu transaksi per file. File applied yang hilang, diubah, dinomori ulang, atau tidak lagi sesuai manifest membuat runner gagal sebelum apply berikutnya. Tidak ada auto-adopt schema lama, skip checksum, force version, auto-down, atau SQL nontransactional. Explicit transaction control dalam file ditolak. Kegagalan rollback file aktif; file sebelumnya tetap committed. Rerun membaca ledger untuk menyelesaikan status commit yang tidak pasti setelah koneksi terputus.

Koneksi runtime tidak dapat menjalankan runner. Role deploy per owner tidak superuser/CREATEDB/CREATEROLE/BYPASSRLS dan memiliki hak CREATE dalam database owner. Runtime hanya mendapat CONNECT dan grant objek eksplisit melalui migration. Provisioning cluster/database/role memerlukan administrator dan dipisahkan dari runner schema; script bootstrap lokal berisi kredensial sintetis dan tidak untuk produksi. Ledger adalah metadata operasional privat, sehingga memakai key schema/version dan actor role, bukan GUID publik/soft delete seperti tabel bisnis.

Default EXECUTE function untuk PUBLIC dicabut sebelum baseline pertama. Migration tambahan mengatur grant tabel/kolom/function dan memperketat trigger fiscal-period lama. Function metadata per runtime owner menjaga immutable identity/scope/created fields, version bertambah satu, actor serta timestamp mutasi; function berjalan SECURITY INVOKER dengan search_path tetap. Pengecekan identitas actor dan authorization bisnis tetap berada di service pada slice berikutnya. Audit/ledger bisnis append-only untuk runtime; tidak ada UPDATE/DELETE/TRUNCATE. Penambahan field audit lama memakai provenance `legacy-baseline` yang eksplisit, kemudian input module/source diwajibkan bagi row baru.

## Kompatibilitas dan pemulihan

Sebelas SQL baseline tetap byte-identical. Tidak ada writer bisnis aktif sebelum B-02.1; reader sqlc master tetap kompatibel. Perubahan menambah grant, kolom audit dan trigger; tidak menghapus fakta. Sebelum upgrade terhadap data lama, cek metadata/version/actor dan constraint pada fixture representatif. Rollback kode tidak membatalkan history/schema. Migration gagal yang belum tercatat boleh diperbaiki lalu diulang; migration applied hanya diperbaiki lewat file versi baru. Restore checkpoint diuji ke database terisolasi sebelum rerun. Pipeline backup/PITR dan target RPO/RTO tetap B-02.3.

Sumber: [PostgreSQL advisory locks](https://www.postgresql.org/docs/18/explicit-locking.html#ADVISORY-LOCKS), [default privileges](https://www.postgresql.org/docs/18/sql-alterdefaultprivileges.html), [function security](https://www.postgresql.org/docs/18/sql-createfunction.html).
