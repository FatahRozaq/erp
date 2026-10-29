# B-01 — Bukti scaffold dan CI

**Tanggal:** 29 Oktober 2026. **Scope:** work order B-01 saja. B-02 runtime data/event, B-03 auth/telemetry, dan F-04 integrasi Metronic tidak dikerjakan.

## Hasil

- Lima deployable Go/Echo v5 (`gateway`, `platform`, `commercial`, `operations`, `finance`) mempunyai `go.mod`/`go.sum`, binary `cmd/api`, Dockerfile, endpoint proses `/health/live`, dan smoke test. Tidak ada DDL atau auth stub yang mengklaim fitur bisnis.
- Web Next.js 16 App Router mempunyai shell dan wrapper `src/components/ui` + `src/components/layout`, Dockerfile, `package-lock.json`, serta 16 generated OpenAPI types dengan pemeriksaan drift. `vendor-manifest.json` menunjukkan Metronic belum diperoleh; tidak ada source/aset vendor.
- Flutter 3.47.8 mempunyai platform Android, iOS, web, lockfile, app shell dan widget test. `com.example` adalah application ID sementara; native signing/distribution belum siap.
- Compose lokal mempunyai Postgres 18, Redis, NATS JetStream, MinIO rilis berchecksum, lima API dan web. Kredensial Compose hanya nilai development lokal, tidak dipakai CI. `CODEOWNERS` menetapkan owner repository sementara dari identitas Git lokal; reviewer domain/controller yang sebenarnya masih perlu ditetapkan saat PIC tersedia.
- `.github/workflows/ci.yml` menjalankan pemeriksaan kontrak, inventaris migration, format/lint/build/test Go, web, dan Flutter. Workflow tidak mereferensikan `secrets.*` atau konfigurasi production.

## Bukti lokal

| Pemeriksaan | Hasil |
|---|---|
| `go vet ./...`, `go test ./...`, `go build ./cmd/api` pada kelima modul | Lulus |
| `npm ci`, format, lint, typecheck, generator drift, unit test, `next build` | Lulus |
| Flutter `pub get --enforce-lockfile`, `dart format`, `flutter analyze`, `flutter test`, `flutter build web` | Lulus |
| `python scripts/validate_contracts.py` | 16 OpenAPI, 43 event schema, 43 contoh lulus |
| `python scripts/check_migration_inventory.py` | 11 migration SQL tetap ada |
| SHA-256 sebelum/sesudah B-01 untuk 11 migration dan seluruh 104 file kontrak | Identik |
| `podman-compose ... config` dan `up --build -d` | 10 container berjalan; Postgres healthy, Redis PONG, MinIO/Go/web HTTP 200 |
| Clone Git bersih dan perintah CI setara | Dicatat setelah verifikasi akhir |

## Batas bukti

- Hosted GitHub Actions belum berjalan karena repository lokal belum memiliki remote. Native APK/IPA belum dibangun di host ini karena Android SDK/Xcode tidak tersedia; build Flutter web membuktikan kompilasi app shell, sedangkan platform native telah dihasilkan dari SDK yang sama.
- `/health/live` hanya liveness proses, bukan readiness DB/broker. Migrasi SQL belum dijalankan oleh runtime; B-02 akan membangun runner, function/grant test, owner DB, event, dan backup/restore.
- Metronic menunggu source/lisensi, sesuai R-02 dan F-04. CODEOWNERS harus diverifikasi terhadap reviewer GitHub aktual ketika repository remote dan PIC tim ditetapkan.
- Input pilot dan G0 pada R-02 tetap terbuka untuk aktivasi nyata. B-01 hanya memerlukan fixture/konfigurasi development sintetis.

**Pekerjaan berikutnya:** B-02 untuk migration/function dan runtime data/event. B-03 menyusul setelah B-02; jangan centang G1 hanya berdasarkan B-01.
