# Enterprise ERP Platform

B-01 menyediakan skeleton runtime untuk lima service Go/Echo, web Next.js, Flutter, dan infra lokal. Belum ada API bisnis, auth, migration runner, worker, atau integrasi visual Metronic. Seluruh kontrak dan 11 migration SQL tetap kanonik dan belum dijalankan oleh aplikasi pada startup.

## Bootstrap

| Stack | Perintah dari root repository |
|---|---|
| Go/Echo | `cd backend/golang/services/platform && go run ./cmd/api` (ganti `platform` dengan `gateway`, `commercial`, `operations`, atau `finance`) |
| Next.js | `cd frontend/nextjs && npm ci && npm run dev` |
| Flutter | `cd mobile/flutter && flutter pub get --enforce-lockfile && flutter run` |
| Infra lokal | `podman-compose -f infra/compose/compose.yaml up --build -d` |

Toolchain dipin di `go.mod` per service (Go 1.25.10), `frontend/nextjs/package-lock.json` (Node 24.21.0 di CI), dan Flutter 3.47.8 di CI serta `mobile/flutter/pubspec.lock`. Jalankan pemeriksaan kontrak dengan `python3 -m pip install -r scripts/requirements-contracts.txt && python3 scripts/validate_contracts.py`. CI pada `.github/workflows/ci.yml` menggunakan hanya fixture/kredensial lokal sintetis, tanpa secret repository. Lihat [panduan Compose](infra/compose/README.md) dan [bukti B-01](docs/roadmap/b-01-evidence.md).

## Dokumen rujukan

1. [Instruksi agent](AGENTS.md) dan [standar engineering](docs/engineering/README.md).
2. [Master PRD](docs/enterprise-erp-prd.md), [FSD](docs/features/README.md), dan [kontrak](contracts/openapi/README.md).
3. [Backlog](docs/roadmap/implementation-backlog.md), [work order](docs/roadmap/ai-work-orders.md), dan [timeline](docs/roadmap/implementation-timeline.md).
4. [Dependency pilot dan aset](docs/roadmap/r-02-dependency-register.md). Source/lisensi Metronic, IdP, policy riil, dan provider sandbox belum tersedia; gunakan fixture desain sampai owner menyediakan input itu.
