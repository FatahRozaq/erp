# Enterprise ERP — Standar Repository dan Kontrak Lintas Aplikasi

**Status:** baseline desain, diperbarui 30 Oktober 2026. **Berlaku untuk:** backend Go/Echo v5, web Next.js dengan acuan UI shadcn-admin MIT, mobile Flutter, kontrak API/event, database migration/function, dan infrastruktur. Dokumen ini menerjemahkan [Master PRD](../enterprise-erp-prd.md) menjadi aturan struktur kode. Detail implementasi berada pada [backend](backend-standards.md), [database](database-standards.md), [migration/function DB](database-functions-and-migrations.md), [frontend](frontend-standards.md), dan [mobile](mobile-standards.md). Keputusan bisnis yang belum final dicatat di [Implementation Readiness](../implementation-readiness.md).

## 1. Prinsip yang wajib dijaga

1. **Batas domain lebih penting daripada jumlah service.** MVP memiliki deployable `gateway`, `platform`, `commercial`, `operations` dan `finance` sesuai PRD §29. Setiap deployable dapat berisi beberapa modul internal; pemecahan deployable hanya setelah kontrak, ownership, dan kebutuhan skalanya jelas.
2. **Satu pemilik untuk setiap fakta bisnis.** Kode di luar owner tidak menulis tabel owner. Komunikasi lewat API/command atau event berkontrak. Pengecualian transaksi lokal Finance–Accounting MVP didokumentasikan di PRD.
3. **Kontrak ditetapkan sebelum implementasi.** OpenAPI dan event schema adalah artefak kanonik untuk komunikasi lintas deployable; perubahan harus di-review bersama consumer. UI/mobile menghasilkan request dari kontrak yang sama.
4. **Kode mengikuti alur bisnis.** Nama modul, command, event, folder, dan tes memakai istilah PRD: `sales_order`, `goods_receipt`, `stock_reservation`, `journal`. Jangan membuat folder generik seperti `helpers`, `common`, atau `utils` untuk menyembunyikan ownership.
5. **Keamanan dan audit berada di server.** Permission UI hanya membantu pengalaman pengguna; service memeriksa actor, tenant, legal entity, scope, document state, dan SoD. GUID tidak menggantikan authorization.
6. **Readability menjadi gate review.** Fungsi mengerjakan satu tujuan, nama menyatakan maksud, error memberi konteks, dan transaksi DB tidak menyertakan panggilan jaringan. Abstraksi dibuat setelah kebutuhan ulang nyata, bukan sebelum ada dua penggunaan.

## 2. Struktur folder repository yang dituju

Pohon ini adalah **target setelah scaffold**; repository sudah memisahkan `backend/database`, `backend/golang`, `frontend/nextjs`, dan `mobile/flutter`, serta berisi dokumen dan kontrak OpenAPI/event. Skeleton aplikasi B-01 sudah ada; modul bisnis dan migration runner belum diimplementasikan. Folder/domain di dalam tiap stack ditambah saat slice terkait dikerjakan, sehingga tidak perlu membuat folder kosong. `AGENTS.md` di root dan direktori stack mengarahkan agent ke requirement yang berlaku.

```text
erp/
├── AGENTS.md                        # Instruksi agent lintas repository
├── backend/
│   ├── AGENTS.md                    # Aturan backend lintas stack
│   ├── database/                    # SQL kanonik, setara golang
│   │   ├── AGENTS.md
│   │   ├── migrations/<schema>/      # DDL, function, grant berversi per schema
│   │   ├── queries/<schema>/         # Query bernama sqlc per schema
│   │   └── sqlc.yaml                # Input SQL dan output Go per owner
│   └── golang/
│       ├── AGENTS.md                # Go + Echo v5
│       └── services/
│           ├── gateway/             # Edge API dan policy enforcement
│           ├── platform/            # Identity, organization, master, policy
│           ├── commercial/          # Sales, purchase, credit
│           ├── operations/          # Inventory, warehouse, transfer
│           └── finance/             # AR/AP, payment, accounting
├── frontend/
│   ├── AGENTS.md                    # Aturan frontend lintas stack
│   └── nextjs/
│       ├── AGENTS.md                # Next.js App Router + shadcn-admin, TypeScript
│       └── src/                     # Dibuat saat scaffold web
├── mobile/
│   ├── AGENTS.md                    # Aturan mobile lintas stack
│   └── flutter/
│       ├── AGENTS.md                # Flutter/Dart
│       └── lib/                     # Dibuat saat scaffold mobile
├── contracts/
│   ├── openapi/<domain>/v1.yaml     # Kontrak REST kanonik
│   ├── events/<domain>/<event>/v1.json
│   └── proto/                       # Hanya bila internal gRPC dibutuhkan
├── infra/
│   ├── compose/                     # DEV lokal
│   ├── kubernetes/                  # Production setelah keputusan platform
│   └── observability/               # Dashboard, alert, collector config
├── docs/
│   ├── enterprise-erp-prd.md
│   ├── implementation-readiness.md
│   ├── engineering/
│   ├── adr/                         # Architecture Decision Records
│   ├── roadmap/                     # Phase 2, Phase 3, Enterprise Expansion
│   └── features/                    # FSD per vertical slice
├── scripts/                          # Tooling build/migration, tanpa logic bisnis
├── .github/
│   ├── workflows/
│   └── CODEOWNERS
└── README.md                         # Cara menjalankan stack dan tautan dokumen
```

Setiap service Go memakai Echo v5 hanya pada adapter HTTP menurut [ADR-0003](../adr/0003-echo-metronic.md), dengan `go.mod` sendiri jika benar-benar deployable independen; `go.work` di `backend/golang/` boleh membantu pengembangan lokal multi-module, tetapi CI membangun tiap service secara terisolasi agar dependency eksplisit. [Referensi Go workspaces](https://go.dev/ref/mod#workspaces). Konvensi `src/app` dan file khusus App Router mengikuti [dokumentasi struktur Next.js](https://nextjs.org/docs/app/getting-started/project-structure). Flutter menggunakan pemisahan UI dan data per fitur sesuai [panduan arsitektur Flutter](https://docs.flutter.dev/app-architecture/guide).

Direktori level pertama memisahkan kanal produk; direktori level kedua memisahkan implementasi teknologi. [Peta struktur seluruh modul](target-module-structure.md) menunjukkan bentuk saat roadmap selesai. Bila kelak menilai stack lain, buat direktori saudara seperti `backend/<stack-baru>/`, `frontend/<stack-baru>/`, atau `mobile/<stack-baru>/` beserta standar stack dan ADR-nya. Implementasi baru harus tetap memakai PRD, ownership, kontrak, dan gate yang sama; baseline Go/Echo, Next.js dengan acuan shadcn-admin, dan Flutter berubah hanya melalui keputusan terpisah. Jangan membagi runtime satu aplikasi di antara dua direktori stack.

`backend/database/` adalah direktori SQL bersama untuk stack Go aktif dan dapat dipakai ulang oleh stack backend lain kelak; kepemilikan tabel tetap per schema/service. sqlc menghasilkan kode Go ke adapter PostgreSQL service pemilik, bukan ke domain atau frontend. [ADR-0006](../adr/0006-database-sql-layout.md) mencatat transisi path tanpa mengubah isi 11 migration awal.

**Repository dan deployment:** satu repository Git cukup untuk seluruh source dan kontrak. Backend terdiri dari lima deployable independen (`gateway`, `platform`, `commercial`, `operations`, `finance`), frontend Next.js satu deployable, dan migration/job database dijalankan terpisah terhadap PostgreSQL yang di-host/dioperasikan sebagai layanan tersendiri. Satu repository tidak berarti satu container atau satu server. CI membangun artefak per path/owner, memberi tag image dari commit yang sama, lalu deployment tiap layanan menggunakan image, konfigurasi, secret, health check, dan rollback sendiri. Migration dijalankan sekali secara terkontrol sebelum versi aplikasi yang membutuhkannya; database persisten tidak dibuat ulang pada setiap deploy dan secret tidak masuk Git. Mobile memakai pipeline build/distribusi sendiri dari repository yang sama. Jumlah repository baru dievaluasi jika ownership, kontrol akses source, atau lifecycle rilis benar-benar berbeda.

## 3. Ownership dan dependency rules

| Artefak | Owner | Boleh depend pada | Tidak boleh |
|---|---|---|---|
| `backend/golang/services/<service>/internal/<module>` | Tim domain | Modul sendiri; interface port untuk kontrak luar | Import `internal` service lain atau query DB lain |
| `contracts/openapi/<domain>` | Service API owner | Schema komponen lokal dan standar error | Menduplikasi definisi canonical di frontend |
| `contracts/events/<domain>` | Producer | Envelope bersama, payload minimal | Mengirim row DB/PII penuh atau event tanpa version |
| `frontend/nextjs/src/features/<feature>` | Web feature owner | Generated API client dan shared UI stabil | Import file privat feature lain |
| `mobile/flutter/lib/features/<feature>` | Mobile feature owner | Repository/API contract dan core platform | Menganggap cache lokal authoritative untuk stock/credit |
| `backend/database/migrations/<schema>` | Service/module owner pemilik schema | Tabel, index, trigger, function dan grant schema yang dimilikinya | Alter tabel owner lain atau edit migration yang sudah dijalankan |
| `backend/database/queries/<schema>` | Service/module owner pemilik schema | Query bernama sqlc dan migration schema yang sama | Query lintas owner, SQL dinamis dari input atau edit generated Go manual |
| `infra` | Platform/SRE | Manifest artifact berversi | Secrets dalam repository |

**CODEOWNERS:** tiap service, contract, database migration, web/mobile feature, dan infra punya reviewer utama; perubahan finance/inventory juga perlu reviewer domain/controller sesuai risiko. PR yang mengubah contract harus menyertakan dampak consumer dan strategi compatibility.

### Penempatan modul sampai tahap final

| Deployable awal | Modul fase lanjut yang ditambahkan saat slice dibuat | Batas ownership |
|---|---|---|
| `platform` | approval graph, scheduler, connector registry, reporting projection/analytics/forecasting | Policy, IAM, job, read model dan rekomendasi; tidak menulis ledger domain |
| `commercial` | RFQ/blanket, purchase return orchestration, route/visit, promotion, intercompany source, POS sale | Dokumen komersial/price/credit/checkout; stock dan posting Finance via owner command/event |
| `operations` | transfer/bin/wave/count, intercompany stock legs, discrete assembly/WIP, TMS milestone | Stock movement, reservation, WMS/POD, work order dan transport fact |
| `finance` | supplier debit memo, budget/expense, bank/FX, intercompany books, POS payment/journal | AP/AR/payment/journal dan monetary control authoritative |

Folder modul dipakai di dalam deployable di atas; `contracts/openapi/manufacturing`, `pos`, `tms`, dan `analytics` adalah batas kontrak, bukan perintah untuk langsung membuat empat microservice. Dedicated reporting store final memiliki database/read role sendiri dan menerima event/CDC terverifikasi; pemisahan deployable baru hanya melalui ADR dan cutover pada [FSD-EXP](../roadmap/enterprise-expansion-fsd.md#5-selective-service-split).

## 4. Kontrak data lintas layer

| Konsep | Bentuk standar | Catatan |
|---|---|---|
| Internal row key | `id BIGINT` lokal per tabel/DB | Tidak dikirim di API/event, tidak dijadikan FK lintas owner |
| Public/cross-owner key | `guid UUIDv7` | Opaque; disimpan sebagai UUID DB, string di JSON/Dart/TS |
| Actor | `actor_guid` plus `actor_type=user/service/system` | `created_by`/`updated_by`/`deleted_by` memakai actor GUID; audit mencatat delegator |
| Uang dan kuantitas | Decimal string JSON, contoh `"125000.00"` dan `"12.500000"` | Tidak mengirim JSON number yang dibaca sebagai floating point |
| Instant | RFC 3339 dengan offset/UTC, DB `timestamptz` | Display sesuai IANA timezone user |
| Tanggal bisnis | `YYYY-MM-DD` dan timezone legal entity | Tidak diturunkan dari GUID atau timezone device |
| Concurrency | `version BIGINT` dari 1, naik pada setiap update mutable | HTTP memakai ETag/If-Match atau expected_version pada command |
| Request trace | `request_id`, `correlation_id`, W3C trace context | Trace untuk eksekusi, correlation untuk saga bisnis |
| API error | `success=false, code, message, details, request_id` | Kode stabil, pesan lokal, details tidak membocorkan PII |
| Event | `event_id, aggregate_guid, aggregate_version, tenant_guid, legal_entity_guid?, occurred_at, recorded_at, correlation_id, causation_id, schema_version` | At-least-once; consumer inbox wajib |

**Tenant context:** tenant/legal entity aktif berasal dari token/session dan membership yang divalidasi; parameter legal entity dalam request adalah pilihan konteks yang diverifikasi, bukan klaim otorisasi. Cross-service reference memakai GUID dan owner lookup/event snapshot. Kode tidak melakukan `SELECT` lintas schema owner hanya karena berada pada cluster PostgreSQL sama.

## 5. Kontrak API dan event

- REST publik memakai `/api/v1` dan OpenAPI berisi schema request/response, required/nullability, format decimal/UUID/date, permission, status code, idempotency, ETag, pagination, retryability, dan contoh success/error. PRD §33 hanya pola; spesifikasi operasional per domain dibuat sebelum handler/client.
- Pakai satu versi OpenAPI yang dipin dan tervalidasi oleh generator/linter. [OpenAPI 3.2.1 tersedia sebagai spesifikasi terbaru pada Oktober 2026](https://spec.openapis.org/oas/); baseline implementasi boleh 3.1.x bila toolchain yang dipilih belum mendukung 3.2.1 penuh. Keputusan versi ditulis dalam ADR dan dikunci di CI.
- Source-of-truth berada di `contracts/openapi`; generated client di web/mobile diberi header generated dan tidak diedit manual. Generation reproducible dan drift checked di CI. Koleksi Postman, jika dipakai untuk runnable examples/assertions, dihasilkan/ditautkan dari kontrak tanpa menjadi definisi kedua yang saling bertentangan.
- Event schema berada di `contracts/events`, satu versi per breaking change. Consumer tidak mengasumsikan global ordering atau exactly-once. Producer menyimpan outbox dalam transaksi lokal; consumer inbox dedup permanent berdasarkan event ID/operation ID.
- Penambahan field optional kompatibel; penghapusan/rename/ubah makna memerlukan v2, periode dual support, consumer migration, dan deprecation date.

## 6. Penamaan file dan kode

| Area | Konvensi |
|---|---|
| Go | Package pendek lowercase per domain, file `sales_order.go`/`submit_order.go`; exported identifier hanya untuk kontrak publik; interface kecil di sisi pemakai |
| TypeScript/React | Fitur kebab-case folder, komponen PascalCase, hook `use...`, type/schema bernama domain; route file Next.js mengikuti nama khusus framework |
| Dart/Flutter | Library/file snake_case, class UpperCamelCase, variable lowerCamelCase; nama fitur mengikuti domain |
| SQL | Schema/tabel/kolom/index snake_case; tabel plural; nama constraint/index memakai `<table>_<purpose>_fk`, `_uq`, `_chk`, `_idx`. Primary key mengikuti nama default PostgreSQL `<table>_pkey` |
| SQL function/migration | Function `schema.verb_object_vN` dengan signature typed; definisi/grant/trigger hanya melalui `backend/database/migrations/<schema>/<sequence>_<name>.up.sql`, versi lama dipertahankan selama rolling deploy |
| Event | `domain.aggregate.past_tense.vN`; command menggunakan verba imperatif |
| Permission/error | `domain.resource.action` dan `DOMAIN_RESOURCE_REASON` |
| Test | Berdampingan dengan unit yang diuji; integration/E2E pada folder tes khusus dengan nama skenario bisnis |

Gunakan formatter resmi bahasa dan linter yang dipin. Tidak ada aturan panjang fungsi/coverage angka tunggal sebagai pengganti review; tes menutup invariant, concurrency, permissions, dan failure path. Komentar menjelaskan **alasan** atau aturan bisnis, bukan mengulang kode.

## 7. Dokumentasi dan alur perubahan

Urutan untuk vertical slice: (1) tutup decision bisnis terkait di [readiness review](../implementation-readiness.md), (2) FSD dengan state/permission/sequence/angka contoh, (3) OpenAPI/event schema dan contoh, (4) migration schema/function/grant dan adapter Go, (5) PostgreSQL integration/contract tests, (6) operational dashboard/runbook. ADR mencatat pilihan A/B, alasan, risiko, konsekuensi dan tanggal. PRD tetap sumber tujuan/aturan; FSD dan kontrak menjadi sumber detail implementasi. Jika kontrak mengubah makna PRD, ubah keduanya dalam PR yang sama.

**Definition of review:** reviewer dapat menemukan command, invariant, tabel/function owner, error, audit event, dan tes dari nama file/PR tanpa menebak folder. Format, lint, contract compatibility, migration check, secret scan, dependency scan, unit/integration tests, serta build web/mobile dijalankan CI sesuai perubahan. B-01 menambahkan workflow CI di `.github/workflows/ci.yml`; hasil hosted CI baru tercatat setelah repository dipush dan workflow dijalankan.
