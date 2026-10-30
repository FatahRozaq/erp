# Peta struktur kode saat seluruh roadmap ERP terpenuhi

**Status:** gambaran target, bukan daftar direktori yang harus dibuat sekarang. **Cakupan:** Foundation, MVP, Phase 2, Phase 3, dan Enterprise Expansion dalam [PRD](../enterprise-erp-prd.md) dan [indeks roadmap](../roadmap/README.md). Stack aktif tetap Go/Echo v5, Next.js + shadcn-admin, Flutter, dan PostgreSQL. Struktur ini merinci [standar repository](repository-standards.md); aturan perilaku dan ownership tetap berada di PRD, FSD, kontrak, ADR, serta standar tiap stack.

Pohon berikut menunjukkan **lokasi modul bila capability terkait sudah diimplementasikan**. Subfolder hanya dibuat ketika berisi kode atau migration nyata. Akhir roadmap tidak otomatis berarti setiap capability menjadi service tersendiri: [FSD Enterprise Expansion](../roadmap/enterprise-expansion-fsd.md#5-selective-service-split) menjadikan service split keputusan berbasis bukti. Nama final subpaket yang lebih rinci boleh disesuaikan saat slice dibuat, tetapi owner dan kontraknya tidak boleh berubah diam-diam.

## 1. Backend Go/Echo dan PostgreSQL

```text
backend/golang/
├── AGENTS.md
├── go.work                            # opsional; hanya untuk pengembangan multi-module
└── services/
    ├── gateway/                       # edge API; tidak memiliki ledger bisnis
    │   ├── go.mod, go.sum
    │   ├── cmd/api/main.go
    │   ├── internal/bootstrap/
    │   ├── internal/authentication/
    │   ├── internal/routing/
    │   ├── internal/scope/
    │   ├── internal/ratelimit/
    │   └── tests/integration/
    ├── platform/
    │   ├── go.mod, go.sum
    │   ├── cmd/{api,worker}/
    │   ├── internal/bootstrap/
    │   ├── internal/runtime/          # idempotency, audit, outbox/inbox, telemetry lokal
    │   ├── internal/identity/
    │   ├── internal/organization/
    │   ├── internal/master/           # product, customer, vendor, employee reference
    │   ├── internal/policy/           # approval, pricing, tax, numbering
    │   ├── internal/document/
    │   ├── internal/notification/
    │   ├── internal/importexport/
    │   ├── internal/search/
    │   ├── internal/reporting/        # operational reports, schedules, scoped export
    │   ├── internal/connector/        # registry, mapping, signed webhook adapter
    │   ├── internal/analytics/        # reporting-store ingestion, metrics, forecast
    │   ├── migrations/{identity,organization,master,policy,runtime,...}/
    │   └── tests/{contract,integration}/
    ├── commercial/
    │   ├── go.mod, go.sum
    │   ├── cmd/{api,worker}/
    │   ├── internal/{bootstrap,runtime}/
    │   ├── internal/sales/            # quotation, SO, sales return
    │   ├── internal/purchase/         # PR, RFQ, blanket, PO, purchase return
    │   ├── internal/credit/
    │   ├── internal/promotion/
    │   ├── internal/fieldsales/       # route, visit, target
    │   ├── internal/pos/              # sale, register/shift, refund orchestration
    │   ├── internal/intercompany/     # commercial source document
    │   ├── migrations/{purchase,sales,runtime,...}/
    │   └── tests/{contract,integration}/
    ├── operations/
    │   ├── go.mod, go.sum
    │   ├── cmd/{api,worker}/
    │   ├── internal/{bootstrap,runtime}/
    │   ├── internal/inventory/        # movement, balance, reservation, count
    │   ├── internal/warehouse/        # receipt, bin, wave, pick/pack, POD
    │   ├── internal/transfer/         # intra/intercompany stock legs
    │   ├── internal/manufacturing/    # BOM, assembly WO, WIP, variance source
    │   ├── internal/transport/        # TMS plan dan append-only milestone
    │   ├── migrations/{inventory,runtime,...}/
    │   └── tests/{contract,integration}/
    └── finance/
        ├── go.mod, go.sum
        ├── cmd/{api,worker}/
        ├── internal/{bootstrap,runtime}/
        ├── internal/finance/          # AR/AP, invoice, payment, bank, expense, FX
        ├── internal/accounting/       # journal, GL, period, statements
        ├── internal/budget/           # commitment dan actual
        ├── internal/intercompany/     # due-to/from, tax, settlement
        ├── migrations/{finance,accounting,runtime,...}/
        └── tests/{contract,integration}/
```

`{...}` pada pohon di atas adalah **notasi ringkas dokumentasi**, bukan nama folder literal. `gateway/` dibuat ketika B-01 di-scaffold; empat owner lain sekarang baru berisi migration SQL. Folder migration yang sudah ada tetap dipertahankan, sedangkan folder baru muncul bersama migration per slice. `analytics/` tetap berada pada owner Platform/Data dengan reporting store dan role DB terpisah; ini tidak memberi hak menulis ledger domain. `scheduler` adalah kemampuan worker Platform/Reporting/Connector, bukan service atau folder generik yang harus ada sendiri.

### Isi satu modul Go yang nyata

```text
services/operations/
├── cmd/api/main.go                    # bootstrap Echo, route, lifecycle
├── cmd/worker/main.go                 # consumer/relay milik Operations
├── internal/inventory/
│   ├── domain/                        # invariant, entity, typed error
│   │   ├── stock_movement.go
│   │   └── stock_movement_test.go
│   ├── application/                   # command/query dan port yang dipakai
│   │   ├── post_movement.go
│   │   └── post_movement_test.go
│   └── adapters/
│       ├── http/                      # Echo handler, DTO, error mapping
│       ├── postgres/                  # repository, typed function call, tx
│       └── jetstream/                 # event relay/consumer
├── migrations/inventory/
│   ├── 000001_receipt_stock.up.sql
│   └── 000002_return_inspection.up.sql
└── tests/integration/                # PostgreSQL asli, race, retry, scope
```

Pola `domain/application/adapters` dipakai saat modul cukup kompleks; package kecil boleh lebih datar. `internal` melindungi implementasi service dari import lintas module Go. Tes unit dekat file Go, tes database/kontrak di bawah service owner. Worker tidak dibuat sebagai pemilik tabel baru. Panduan resmi Go memakai `internal` untuk paket pendukung dan `cmd` untuk executable bila ukuran program memerlukannya: [Go module layout](https://go.dev/doc/modules/layout). Detail dependency dan Echo ada di [standar backend](backend-standards.md).

### Penempatan database, function, audit, dan log

| Artefak | Lokasi dan batas |
|---|---|
| Tabel, index, constraint, function, trigger, grant | `services/<owner>/migrations/<module>/000NNN_name.up.sql`; migration yang telah dijalankan immutable. |
| Pemanggil function DB | `services/<owner>/internal/<module>/adapters/postgres/`; signature dan parameter typed, dalam transaksi owner. |
| Metadata `id`, `guid`, `created_at/by`, `updated_at/by`, `deleted_at/by`, `version` | Kolom pada tabel yang sesuai [standar database](database-standards.md), bukan satu package global yang menyembunyikan ownership. |
| Audit, idempotency, outbox, inbox | Tabel owner melalui migration `runtime/` dan adapter runtime lokal; event/audit satu transaksi dengan mutasi terkait. |
| Application log dan trace | Kode instrumentasi/redaksi di boundary service; output ke collector/platform observability, **bukan** file `logs/` di source repository. |
| Reporting store final | Storage/read role terpisah di bawah owner Platform/Data; projection dan watermark di `platform/internal/analytics/`, source data tetap milik domain. |

DB role runtime tidak diberi DDL; migration dijalankan oleh runner/role deploy terpisah. Function DB dipakai untuk invariant lokal atomik, sedangkan authorization dan orkestrasi lintas owner tetap di Go. Lihat [standar migration dan function](database-functions-and-migrations.md).

## 2. Frontend Next.js + shadcn-admin

```text
frontend/nextjs/
├── AGENTS.md
├── package.json, lockfile, tsconfig.json, next.config.ts
├── vendor-manifest.json              # source, versi, hash, lisensi MIT shadcn-admin
├── public/                            # aset publik yang benar-benar dipakai
├── src/
│   ├── app/
│   │   ├── (auth)/                    # halaman sign-in dan alur browser
│   │   ├── (erp)/
│   │   │   ├── settings/              # org, access, policy, tax, numbering, connector
│   │   │   ├── master/                # product, customer, vendor, employee
│   │   │   ├── purchase/              # PR, RFQ, blanket, PO, return
│   │   │   ├── sales/                 # quote, SO, return, promo, route/visit
│   │   │   ├── credit/
│   │   │   ├── inventory/             # stock, receipt, transfer, count, adjustment
│   │   │   ├── warehouse/             # bin, wave, pick/pack, delivery/POD
│   │   │   ├── finance/               # invoice, AR/AP, payment, bank, FX, budget
│   │   │   ├── accounting/            # journal, period, statements
│   │   │   ├── intercompany/
│   │   │   ├── manufacturing/
│   │   │   ├── pos/
│   │   │   ├── tms/
│   │   │   ├── reports/               # operational, financial, schedules
│   │   │   ├── analytics/             # metrics, forecast, watermark
│   │   │   └── {approvals,exceptions,notifications,search,data}/
│   │   └── api/                       # callback OIDC dan BFF route handlers eksplisit
│   ├── features/                      # kode UI/perilaku per capability
│   │   ├── {organization,access-control,products,customers,vendors,employees}/
│   │   ├── {policies,pricing,tax,numbering,documents,notifications,imports}/
│   │   ├── {requisitions,rfqs,blanket-contracts,purchase-orders,purchase-returns}/
│   │   ├── {quotations,sales-orders,sales-returns,credit,promotions,routes,visits}/
│   │   ├── {receipts,stock,reservations,adjustments,transfers,counts}/
│   │   ├── {bins,waves,picks,deliveries}/
│   │   ├── {sales-invoices,vendor-invoices,payments,bank-reconciliation,fx}/
│   │   ├── {journals,periods,budgets,expenses,intercompany}/
│   │   └── {manufacturing,pos,tms,reports,report-schedules,analytics,forecasting,approvals,exceptions,search,connectors}/
│   ├── components/{ui,layout}/       # wrapper shadcn-admin dan shell milik repo
│   ├── lib/{api,auth,errors,format,query,telemetry}/
│   ├── generated/openapi/             # hasil generator; tidak diedit manual
│   ├── vendor/shadcn-admin/               # source MIT yang diadaptasi terisolasi
│   └── styles/
└── tests/{e2e,accessibility}/
```

`{...}` hanya notasi ringkas. Di `src/app`, folder adalah URL/layout dan file `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`, atau `route.ts` mengikuti aturan framework; kompleksitas fitur tidak diletakkan di route. [Dokumentasi Next.js](https://nextjs.org/docs/app/getting-started/project-structure) mengizinkan `src` dan menjelaskan route groups serta file khusus App Router. `src/features/sales-orders/`, misalnya, berisi `api/`, `components/`, `hooks/`, `schemas/`, `model/`, dan `tests/` seperti [standar frontend](frontend-standards.md). Semua browser mutation melalui BFF dan Go gateway; generated OpenAPI, source template shadcn-admin, dan kode ERP tetap terpisah. Folder `tests/` hanya untuk perjalanan lintas fitur; unit/component tests dekat fiturnya.

## 3. Mobile Flutter

```text
mobile/flutter/
├── AGENTS.md
├── pubspec.yaml, pubspec.lock, analysis_options.yaml
├── android/                           # konfigurasi OS
├── ios/                               # konfigurasi OS
├── lib/
│   ├── main.dart
│   ├── app/{app,bootstrap,router,app_scope}.dart
│   ├── core/
│   │   ├── api/                       # kontrak, retry, error
│   │   ├── auth/                      # OIDC/PKCE dan secure storage
│   │   ├── database/                  # SQLite terenkripsi, migration lokal
│   │   ├── sync/                      # outbox, cursor, conflict coordinator
│   │   ├── logging/                   # telemetry ber-redaksi
│   │   ├── format/
│   │   └── ui/
│   ├── generated/openapi/             # hasil generator
│   └── features/
│       ├── customers/                # snapshot scoped
│       ├── products/                 # snapshot scoped
│       ├── routes/                   # assignment/rencana kunjungan P2
│       ├── visits/                   # check-in/out dan evidence P2
│       ├── sales_orders/             # draft offline dan submit P2
│       ├── warehouse_tasks/          # scan/lease online-first
│       ├── deliveries/              # POD/evidence sesuai kontrak
│       ├── approvals/               # online-only
│       ├── notifications/           # membuka data setelah auth ulang
│       └── sync_status/             # queue, retry, konflik, reset cursor
├── test/                              # unit dan widget, mengikuti feature/core
└── integration_test/                 # alur perangkat, offline/restart/revoke
```

Setiap feature yang kompleks berisi `presentation/` (Screen, ViewModel, widgets), `data/` (Repository implementation, remote/local Service, mapper), dan `domain/` **bila perlu** (model/interface/use case). Flutter merekomendasikan pemisahan UI dan data menjadi View, ViewModel, Repository, dan Service; domain layer opsional: [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide). Folder fitur tidak mencakup seluruh modul web: jurnal, policy admin, bulk import, financial close, POS register, dan analitik penuh tetap web sesuai [standar mobile](mobile-standards.md) dan [UX roadmap](../roadmap/roadmap-ux.md). Offline order/visit tetap Phase 2, bukan MVP.

## 4. Aturan agar struktur tetap rapi saat tumbuh

1. **Satu owner fakta bisnis.** Folder boleh bertambah; tabel, command, function, dan event tetap dimiliki satu domain. Cross-owner lewat kontrak, bukan import internal atau SQL lintas schema.
2. **Satu pola per runtime.** Service Go adalah deployable; feature Next.js adalah unit UI; feature Flutter adalah unit layar/data. Jangan membuat `shared/utils/helpers` berisi logika bisnis dari berbagai owner.
3. **Pemisahan kode mengikuti perubahan nyata.** Tambah subpackage Go atau folder fitur hanya saat tanggung jawab, ukuran, dan tesnya sudah jelas; jangan membuat seluruh pohon target sebagai folder kosong pada B-01.
4. **Bukti mengikuti perubahan.** Unit test dekat kode, integration/contract/E2E test di owner runtime. Migration/function DB, audit, log, security scope, dan recovery diuji sesuai [work order](../roadmap/ai-work-orders.md).
5. **Stack alternatif adalah saudara, bukan campuran.** Bila nanti bereksperimen dengan stack baru, buat `backend/<stack>/`, `frontend/<stack>/`, atau `mobile/<stack>/` beserta ADR dan instruksi stack. PRD dan kontrak bersama tetap sama sampai ada keputusan perubahan requirement.
