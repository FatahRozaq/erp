# Standar Backend Go — Enterprise ERP

**Status:** baseline desain sebelum implementasi. **Berlaku untuk:** semua API dan worker Go dengan Echo v5 sebagai HTTP adapter. **Sumber kebutuhan:** [PRD](../enterprise-erp-prd.md) §§19–35, 48–57 dan [ADR-0003](../adr/0003-echo-metronic.md). **Bahasa:** nama kode/kontrak dalam English; penjelasan boleh Indonesia. Keputusan bisnis terbuka di PRD §58 tetap memerlukan sign-off pemilik proses sebelum fitur terkait diaktifkan.

## 1. Batas layanan dan kepemilikan

MVP memakai sedikit deployable dengan modul yang terpisah secara kode dan data. Modul tidak menjadi microservice baru hanya karena memiliki tabel sendiri. Rujukan Go resmi menganjurkan `cmd` untuk executable dan `internal` untuk kode server yang tidak diekspor; struktur di bawah mengikuti itu tanpa memaksakan banyak lapisan untuk kasus sederhana ([Go module layout](https://go.dev/doc/modules/layout)).

| Direktori | Deployable / modul | Sumber fakta utama |
|---|---|---|
| `backend/golang/services/gateway` | Go API Gateway | Routing, auth enforcement dan rate limit untuk BFF web, mobile, dan integrasi; bukan owner fakta bisnis |
| `backend/golang/services/platform` | Identity, Organization, Master, Policy, Document metadata | User/scope, organisasi, master dan policy version |
| `backend/golang/services/commercial` | Sales, Purchase, Credit | Komitmen order, source price/credit snapshot |
| `backend/golang/services/operations` | Inventory, WMS, receipt, delivery, transfer | Movement, balance, reservation, pekerjaan gudang |
| `backend/golang/services/finance` | AR/AP, invoice, payment, Accounting | Open item, settlement, posting intent, journal, period |

`finance` dan `accounting` tetap dua modul dengan pemilik tabel berbeda, tetapi satu deployable dan transaksi lokal untuk invoice→journal pada MVP sesuai PRD §26/29. Pengecualian lintas schema ini dicatat dalam ADR dan test rekonsiliasi. Deployment worker ada pada `cmd/worker` milik layanan yang menguasai job; worker tidak diberi hak menulis tabel domain lain. Gateway di `backend/golang/services/gateway` hanya menangani edge concern. Tidak ada akses SQL lintas pemilik, import `internal` antar modul layanan, atau package `shared` berisi aturan bisnis.

Setiap deployable memiliki `go.mod` sendiri. Gunakan `go.work` di `backend/golang/` hanya untuk pengembangan lokal bila diperlukan; build dan CI tiap deployable tetap memakai modulnya sendiri. Kontrak antar layanan hidup di `contracts/openapi/<domain>/v1.yaml` dan `contracts/events/<domain>/`; hanya kontrak yang boleh menjadi dependensi lintas owner. Tetapkan pemilik modul, schema, kontrak, dan migrasi di `CODEOWNERS`.

## 2. Struktur file per layanan

Contoh `operations`; pola yang sama berlaku pada `platform`, `commercial`, dan `finance`, sedangkan `gateway` cukup dengan package edge yang dipakai. Direktori dibuat hanya saat ada kode nyata. Jangan membuat satu package per class atau antarmuka generik sebelum ada pemakai.

```text
backend/golang/services/operations/
├── go.mod
├── go.sum
├── cmd/
│   ├── api/main.go                 # bootstrap HTTP, shutdown, readiness
│   └── worker/main.go              # relay outbox / consumer milik Operations
├── internal/
│   ├── bootstrap/                  # config, wiring eksplisit, lifecycle
│   ├── inventory/
│   │   ├── domain/                 # StockBalance, Movement, invariant, errors
│   │   ├── application/            # ReserveStock, PostMovement, interfaces yang dipakai
│   │   └── adapters/
│   │       ├── http/               # Echo route/handler, DTO, error mapper
│   │       ├── postgres/           # SQL repository, typed DB function calls, transaction adapter
│   │       └── jetstream/          # relay/consumer event
│   └── warehouse/                  # pola modul, hanya package yang diperlukan
├── migrations/
│   ├── inventory/                  # versioned table/index/function/GRANT SQL migrations
│   └── warehouse/
└── README.md                       # cara run, env, owner, kontrak, runbook link
```

`cmd` hanya membangun dependensi dan menjalankan server/worker. `domain` berisi aturan yang dapat diuji tanpa HTTP, broker, atau database. `application` mengorkestrasi satu use case, transaksi, otorisasi aksi dan publikasi outbox; definisikan interface kecil di package pemakai. Adapter menerjemahkan transport/SQL/broker ke tipe domain; DTO transport dan row SQL tidak dibocorkan ke domain. Dependency mengarah `adapter → application → domain`, bukan sebaliknya. Cross-domain request melalui port/contract, bukan pemanggilan repository milik modul lain. Untuk pembacaan dashboard, proyeksi terpisah boleh memakai CQRS; CRUD biasa tetap sederhana sesuai PRD §28.

Satu file diberi nama menurut perilaku (`reserve_stock.go`, `sales_order_handler.go`), bukan `utils.go`/`common.go` besar. Package pendek, huruf kecil, tanpa `service`/`manager` yang tidak menjelaskan domain. Gunakan `gofmt`, `go vet`, penamaan Go `MixedCaps`, dan komentar pada API yang diekspor serta invariant yang sulit terlihat ([Effective Go](https://go.dev/doc/effective_go)). Jangan menambah abstraksi hanya untuk meniru pola framework.

### Echo v5 sebagai batas HTTP

Gunakan modul `github.com/labstack/echo/v5` dengan Go ≥1.25 sesuai [instalasi resmi](https://echo.labstack.com/guide/installation/); kunci patch saat scaffold. `cmd/api` hanya membuat instance Echo, memasang middleware berurutan, mendaftarkan route, health endpoint dan shutdown. `internal/<module>/adapters/http` memiliki handler `func(c *echo.Context) error`, DTO request/response, dan mapper error; application menerima `context.Context`, `Principal`, dan command typed. Domain/worker tidak mengimpor Echo. Jangan menyimpan `*echo.Context` setelah handler selesai atau mengirimnya ke goroutine.

Urutan boundary: trusted proxy/request ID/trace → Recover → request log ber-redaksi → body/timeout/rate limit → OIDC/workload authentication → tenant/entity/scope authorization → DTO bind/validate → application. Gunakan allowlist path/query/header dan DTO khusus; [Echo memperingatkan risiko bind ke business struct](https://echo.labstack.com/guide/binding/) karena field privileged dapat terisi dari input. Validasi domain berjalan setelah DTO, bukan diganti oleh validator format. [HTTPErrorHandler terpusat](https://echo.labstack.com/guide/error-handling/) mengubah typed error ke envelope Problem ERP; respons yang sudah committed tidak ditulis ulang. Secure headers/CORS/trusted proxy dikonfigurasi eksplisit per ingress, bukan memakai semua default middleware tanpa threat model. Uji 401/403/404 scoped, 409/412/422, panic, timeout, payload terlalu besar, dan duplikasi idempotency lewat Echo router nyata.

### Migration dan function DB pada adapter PostgreSQL

Backend **wajib memakai SQL migration berversi** untuk tabel, constraint, index, trigger, function dan grant. `cmd/api`/`cmd/worker` tidak menjalankan DDL otomatis saat start; migration runner deploy memakai role terpisah. Setiap function DB yang dipakai Go mempunyai wrapper typed di `adapters/postgres` dan dipanggil dengan parameter terikat lewat `sql.Tx` milik use case. Function menegakkan invariant lokal atomik (stock, credit, nomor, journal, budget dan sejenisnya); Go tetap menangani authorization, policy, orkestrasi lintas owner, audit/outbox dan error HTTP. Jangan menyebarkan panggilan `SELECT schema.function(...)` sebagai string bebas di handler/domain. [ADR-0004](../adr/0004-versioned-database-functions.md) dan [standar function/migration](database-functions-and-migrations.md) menetapkan versi, ownership, keamanan dan tes.

## 3. Satu command, satu jalur mutasi

Alur wajib: decode dan batas ukuran → validasi bentuk request → authenticate → authorize permission **dan** scope tenant/legal entity/branch/warehouse → load state/version → validasi invariant domain → transaksi owner → state + audit + outbox + idempotency result → commit → response. Semua aksi state machine di PRD §20 adalah command; `POST /{guid}/submit` tidak dapat diganti dengan `PATCH status`. Karena GUID bisa ditebak/dibagikan, GUID bukan bukti hak akses; semua lookup dan mutasi harus dibatasi scope server. OWASP menempatkan broken object level authorization sebagai risiko API utama ([OWASP API1:2023](https://api-security.owasp.org/editions/2023/en/0xa1-broken-object-level-authorization/)).

Transaksi Go memakai `BeginTx(ctx, ...)`, seluruh query **termasuk function DB** lewat `sql.Tx`/adapter transaksi yang sama, `defer Rollback`, dan `Commit` setelah semua penulisan kritikal. Jangan membuat `BEGIN`/`COMMIT` SQL manual atau memakai `sql.DB` di tengah `Tx`; dokumentasi Go memperingatkan bahwa ini dapat memberi pandangan data yang tidak konsisten/deadlock ([Go transactions](https://go.dev/doc/database/execute-transactions)). Untuk stock/credit/period/numbering, lakukan lock urutan key tetap dan cek ulang invariant pada primary DB. Batas waktu request dan transaksi berasal dari `context.Context`; jangan menahan transaksi terbuka saat memanggil jaringan eksternal.

Error domain bersifat typed/stabil dan dipetakan di transport: `400` malformed, `401` unauthenticated, `403` forbidden, `404` tidak ada/di luar scope, `409` konflik/idempotency mismatch, `412` ETag lama, `422` invariant bisnis, `429` rate limit, `503` dependency kritikal. Pesan pengguna aman dan dapat diterjemahkan; detail internal ke log. `request_id` selalu dikembalikan. Retry hanya pada operasi idempotent dengan deadline, backoff berjitter, jumlah percobaan terbatas dan status akhir terlihat operator.

## 4. Kontrak API

`contracts/openapi/<domain>/v1.yaml` adalah sumber kontrak HTTP; implementasi dan klien harus cocok dengannya. Gunakan OpenAPI 3.1.x yang didukung toolchain dan pin versinya; spesifikasi resmi mendefinisikan format lintas bahasa yang dapat dipakai manusia dan tooling ([OAS 3.1.2](https://spec.openapis.org/oas/v3.1.2.html)). Koleksi Postman boleh berisi contoh, assertion, dan flow uji, tetapi tidak menjadi sumber definisi yang berbeda dari OpenAPI.

- Rute eksternal `/api/v1`; path memakai `guid` opaque, bukan `id` BIGINT internal. Request/response mengirim angka uang/qty sebagai string decimal; instant ISO 8601 dengan offset/UTC; business date sebagai `YYYY-MM-DD`.
- Setiap operasi menyatakan permission, data scope, request/response schema, error code, idempotency, `If-Match`/ETag, status async, batas paging/filter/sort, dan contoh sukses/gagal. Field yang belum didukung tidak diam-diam diabaikan pada command kritikal.
- Mutasi kritikal memakai `Idempotency-Key` dengan scope `(tenant_guid, principal/client, method, route/action, key)`, hash request, hasil atau operation reference, dan TTL 24–72 jam. Key sama dengan body berbeda → `409`. `business_operation_guid` dari sumber dibuat sekali dan dipakai ulang saat retry; registry operasi dan source portion key tetap unik permanen setelah TTL API habis. `version` hanya untuk CAS, bukan deduplikasi bisnis (lihat [standar database](database-standards.md)).
- Update agregat memakai `If-Match` dari `version`; expected version lama → `412`. Command async mengembalikan `202` dan operation URL; state `PENDING`/exception nyata tersimpan, bukan sukses semu.
- Filter/sort hanya allowlist dan parameter SQL; `page_size` default 25 maksimum 200, cursor stabil untuk daftar besar. Scope diterapkan sebelum hasil dan total dihitung. Gunakan query parameter terikat, bukan interpolasi input; Go secara eksplisit merekomendasikan parameter SQL untuk mencegah injection ([Go SQL injection](https://go.dev/doc/database/sql-injection)).
- Perubahan breaking kontrak memerlukan versi baru dan masa kompatibilitas; CI memeriksa schema, contoh request/response, otorisasi, idempotency, dan consumer yang terdampak.

## 5. Event, outbox, inbox

Fakta domain memakai nama `domain.aggregate.past_tense.v1` dan schema di `contracts/events/<domain>/`. Envelope minimum: `event_id` UUIDv7, `aggregate_guid`, `aggregate_version`, `tenant_guid`, `legal_entity_guid` bila ada, `occurred_at`, `recorded_at`, `correlation_id`, `causation_id`, `schema_version`, dan payload seperlunya. `occurred_at` menyatakan aksi bisnis dari server tepercaya; `recorded_at` diisi DB dengan `statement_timestamp()` saat insert outbox, lalu disalin tanpa perubahan ke envelope publish/replay. Ukur outbox/consumer lag dari `recorded_at`. Jangan taruh PII lengkap dalam event. Event versi lama immutable; field optional boleh ditambah secara kompatibel, breaking schema memakai `v2` dan migrasi consumer yang direncanakan.

Simpan perubahan bisnis dan row outbox dalam transaksi PostgreSQL owner yang sama. Relay menerbitkan ke NATS **JetStream** lalu menandai pengiriman setelah broker acknowledgment; crash dapat mengirim ulang. Consumer durable explicit ack mencatat `(consumer_name,event_id)` di inbox dalam transaksi yang sama dengan efeknya, lalu ack broker. Gap versi per aggregate diparkir dan direkonsiliasi; DLQ harus punya alert, owner, dan replay berizin. JetStream memberi at-least-once delivery dan redelivery bila ack tidak datang, sehingga idempotensi consumer tetap wajib ([NATS JetStream](https://docs.nats.io/concepts/jetstream)). Event tidak digunakan untuk memutus keputusan stok/kredit yang memerlukan state otoritatif saat commit.

## 6. Security, konfigurasi, dan observability

- OIDC/OAuth token diverifikasi audience, issuer, expiry dan scopes; setiap endpoint/worker menegakkan permission serta scope data. Maker-checker dan SoD diuji pada command, bukan hanya UI. Service-to-service memakai identitas workload; secret dari secret store/runtime, tanpa nilai di Git atau log.
- Validate payload, batas body/upload dan query cost; outbound request punya timeout; inbound webhook memverifikasi HMAC atas raw body, timestamp/replay window dan event ID. File attachment disimpan di object storage berizin, di-scan malware, dan disajikan melalui URL berumur pendek.
- Setiap log aplikasi berupa JSON terstruktur dari `log/slog` atau adapter setara: `time`, `level`, `service`, `operation`, `request_id`, `trace_id`, `span_id`, `tenant_guid`, `legal_entity_guid`, `actor_guid`, `error_code`, `duration_ms`. Log bukan audit trail; jangan log token, secret, rekening, payload PII, atau SQL parameter sensitif. OpenTelemetry menjelaskan korelasi log dengan trace/span ID ([OTel Logs](https://opentelemetry.io/docs/specs/otel/logs/)). Audit bisnis adalah record durable dalam transaksi domain (lihat [standar database](database-standards.md)).
- Health: liveness berarti proses hidup; readiness berarti bisa menerima traffic tanpa mengirim command berisiko ke dependency mati. Metrik minimum: request rate/error/p95, DB pool wait, lock/deadlock, outbox age, broker lag, DLQ, reconciliation mismatch, posting pending. Setiap alert punya owner dan runbook.
- Konfigurasi melalui env/secret terketik, divalidasi saat start dan dicatat tanpa nilai rahasia. Timezone penyimpanan UTC; tanggal bisnis dihitung dari IANA timezone legal entity. Feature flag yang memengaruhi posting punya owner, log keputusan, dan rollback plan.

## 7. Testing dan gerbang review

Unit test memeriksa invariant dan state transition (qty, credit bucket, price/tax rounding, SoD, period close). Integration test dengan PostgreSQL asli memeriksa constraints, **signature/grant/hasil function DB**, transaksi, konkurensi reservation, idempotency, outbox/inbox, serta rollback. Contract test memeriksa OpenAPI dan contoh error; E2E menutup O2C/P2P/R2R. Fuzz/property test dipakai pada parser/UOM/decimal atau input kompleks yang punya risiko nyata; Go mendukung fuzz test bawaan ([Go fuzzing](https://go.dev/doc/tutorial/fuzz)). Jangan mengejar angka coverage tanpa menguji invariant.

Sebelum merge: `gofmt`, `go vet`, unit + integration relevan, lint dan dependency/secret scan, migration rehearsal, contract compatibility, authorization matrix, audit evidence, dan uji concurrency/reconciliation bila menyentuh stock/finance. Perubahan boundary atau pengecualian standar memerlukan ADR. `README.md` layanan berisi cara run/test, env names, owner, kontrak, dashboard dan runbook. Kode yang baru tidak diterima bila hanya happy path yang diuji untuk posting finansial atau stok.

## 8. Keputusan yang masih harus dikunci

Costing, tax jurisdiction, waktu revenue/COGS, kredit, approval, dan retensi kini memiliki [baseline implementasi](../decisions/mvp-business-policy.md); service harus memuat policy version dan menolak command bila policy legal entity belum aktif. Identitas `id` BIGINT lokal + `guid` UUIDv7 serta referensi lintas owner berakhiran `_guid` mengikuti PRD §25 dan [standar database](database-standards.md). Pemisahan Finance–Accounting tetap mengikuti baseline MVP transaksi lokal; evaluasi pemisahan berada pada `OQ-15`.
