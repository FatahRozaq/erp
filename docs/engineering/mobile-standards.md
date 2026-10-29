# Standar aplikasi mobile ERP

**Status:** rancangan implementasi, 28 Oktober 2026  
**Berlaku untuk:** `mobile/flutter` (Flutter/Dart; Android dan iOS)  
**Sumber kebutuhan:** [Enterprise ERP PRD](../enterprise-erp-prd.md), terutama F-11, bab 33, 37–40, dan 49. Offline order/visit adalah scope **P2**; aturan di sini menjadi kontrak persiapan dan tidak menjanjikan fitur tersebut pada MVP.

## 1. Keputusan arsitektur

Gunakan pemisahan **presentation (Screen + ViewModel)** dan **data (Repository + Service)**. Screen menampilkan state dan meneruskan aksi; ViewModel mengelola state layar; Repository adalah satu-satunya jalur baca/tulis data fitur; Service membungkus HTTP, SQLite, secure storage, kamera, GPS, atau plugin platform. Tambah use case/domain layer hanya ketika aturan lintas repository kompleks atau dipakai banyak layar. Ini mengikuti [panduan arsitektur Flutter](https://docs.flutter.dev/app-architecture/guide) dan [rekomendasi resminya](https://docs.flutter.dev/app-architecture/recommendations).

Untuk titik awal, pakai `provider` sebagai dependency injection, `ChangeNotifier`/`Listenable` untuk ViewModel, dan `go_router` untuk navigasi. Semua dependency diberikan lewat constructor/DI; tidak ada service singleton global yang dapat dimutasi bebas. Pilihan ini dapat direvisi melalui ADR bila ukuran state nyata menuntut pendekatan lain. UI memperoleh model immutable, bukan DTO jaringan mentah. Kode generated dari `contracts/openapi/<domain>/v1.yaml` hanya dipakai di batas remote service dan tidak diedit tangan.

## 2. Struktur folder

```text
mobile/flutter/
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── android/                       # konfigurasi OS, tidak berisi business rule
├── ios/                           # konfigurasi OS, tidak berisi business rule
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── bootstrap.dart          # init DB, konfigurasi, DI
│   │   ├── router.dart
│   │   └── app_scope.dart          # context tenant/entity/user yang aktif
│   ├── core/
│   │   ├── api/                   # HTTP client, retry policy, ApiFailure
│   │   ├── auth/                  # OIDC, token vault, device session
│   │   ├── database/              # encrypted SQLite, migration, DAO dasar
│   │   ├── sync/                  # coordinator, outbox, cursor, conflict
│   │   ├── logging/               # telemetry/redaction
│   │   ├── format/                # currency, date, UOM
│   │   └── ui/                    # tema dan widget umum
│   ├── generated/openapi/         # hasil generator, read-only dalam review
│   └── features/
│       ├── sales_orders/
│       │   ├── data/
│       │   │   ├── sales_order_api_service.dart
│       │   │   ├── sales_order_local_service.dart
│       │   │   ├── sales_order_repository_impl.dart
│       │   │   └── sales_order_mapper.dart
│       │   ├── domain/             # model + interface repo + use case bila perlu
│       │   │   ├── sales_order.dart
│       │   │   └── sales_order_repository.dart
│       │   └── presentation/
│       │       ├── sales_order_screen.dart
│       │       ├── sales_order_view_model.dart
│       │       └── widgets/
│       ├── visits/                # P2, saat fiturnya dimulai
│       └── approvals/             # online-only
├── test/                          # cermin fitur/core, unit + widget
└── integration_test/              # perjalanan pengguna di device
```

Folder `domain/` dapat dihilangkan pada fitur online yang sederhana; interface repository tetap ditempatkan dekat fitur, dan ViewModel tetap bergantung pada interface. `core/sync` hanya orkestrasi teknis lintas fitur; aturan merge bisnis berada di fitur terkait. Jangan membuat satu `screens/`, `models/`, atau `services/` global berisi seluruh modul. Nama fitur memakai `snake_case` (`sales_orders`), sesuai [Effective Dart](https://dart.dev/effective-dart/style).

## 3. Dependensi dan gaya kode

```text
Screen → ViewModel → Repository interface → Repository implementation
Repository implementation → remote/local Service → generated DTO / SQLite / OS
core → tidak mengimpor feature; feature → boleh mengimpor core
```

- Nama file/folder `lowercase_with_underscores`; class/enum/type `UpperCamelCase`; method/field `lowerCamelCase`; private member diawali `_`. Gunakan `dart format`, `dart analyze`, dan `flutter_lints`. Lihat [Effective Dart](https://dart.dev/effective-dart).
- Satu ViewModel mewakili satu view/screen utama. Screen berisi layout, animasi, dan event wiring; parsing respons, retry, validasi bisnis, dan keputusan sinkronisasi berada di Repository/ViewModel/use case.
- JSON mengikuti field OpenAPI (`snake_case` bila kontrak begitu); mapper mengubahnya ke model Dart immutable. Pisahkan `SalesOrderRemoteDto`, `SalesOrderLocalRecord`, dan `SalesOrder` ketika kebutuhan offline/versi berbeda. Jangan menyamakan record SQLite dengan domain entity server.
- GUID server adalah identitas eksternal untuk route/API; `local_id` UUID mengidentifikasi draft yang belum diterima server. `id` internal PostgreSQL tidak dikirim ke mobile. Pertahankan `server_version` untuk optimistic concurrency. Nomor SO, harga, kredit, stok, diskon final, dan status disahkan server.
- Tanggal API UTC dengan timezone bisnis eksplisit; tampilan memakai timezone pengguna/legal entity. Uang/kuantitas presisi ditransfer sebagai decimal string dan tidak dihitung memakai `double` untuk total final. Formatter dan perhitungan lokal yang diperlukan memakai decimal arithmetic yang dipilih/diuji terpisah.
- Config environment (base URL, client ID OIDC, feature flag public) berasal dari build flavor/runtime config yang tervalidasi. Tidak ada client secret, signing key, atau API key privileged di binary.

## 4. Auth, scope, dan penyimpanan lokal

Login mobile memakai OIDC Authorization Code + PKCE melalui **browser sistem**, bukan WebView tertanam; [RFC 8252](https://www.rfc-editor.org/info/rfc8252/) adalah acuan native OAuth. Token/credential ada di secure keystore/keychain melalui adapter yang ditinjau. Access token tidak dicatat di log atau disimpan dalam SQLite. Refresh rotation/reuse detection, device registration, revoke, dan reauth mengikuti PRD. Biometrics hanya membuka credential lokal, tidak mengganti otorisasi server.

SQLite lokal harus terenkripsi dengan implementasi yang diuji pada Android/iOS; kunci database berada di keystore/keychain dan terpisah dari data. Pilihan library SQL/encryption ditetapkan lewat spike kompatibilitas, migrasi schema, recovery key loss, dan tes perangkat. Flutter memberi pola [persistent storage dengan SQL](https://docs.flutter.dev/app-architecture/design-patterns/sql); PRD menambah syarat enkripsi. Jangan menyimpan customer master, alamat, foto, token, atau payload sync di shared preferences/penyimpanan tak terenkripsi.

Partisi cache per `(tenant, user, legal_entity, scope_version)` dan koleksi. Offline read hanya dari snapshot yang masih dalam TTL dan pernah diotorisasi saat online. Cache sensitif maksimal 7 hari sesuai [baseline retensi](../decisions/mvp-business-policy.md#g-16oq-09--data-retensi-dan-lokasi-operasi-indonesia); policy tenant boleh lebih pendek. Tampilkan `last_synced_at`, staleness, dan status offline pada layar agar pengguna tahu data mungkin berubah. Scope revoke menghapus data terbatasi ketika perangkat berikutnya online; perangkat yang masih offline tidak bisa ditarik paksa, sehingga lock lokal, enkripsi, TTL, dan kebijakan perangkat adalah kontrol pembatas risiko.

Saat logout, device revoke, token reuse, atau pergantian tenant/user: hentikan sync, hapus token, kunci, cache, dan berkas sementara sesuai kebijakan. Pergantian legal entity/scope harus menghapus cache yang tak lagi diizinkan dan mengulang bootstrap. Outbox belum terkirim dari scope yang dicabut tidak boleh diam-diam dikirim memakai hak baru; perlakukan sebagai konflik akses yang memerlukan keputusan server/proses owner.

Izin kamera, barcode, GPS, notifikasi, dan foto diminta saat fitur dipakai; GPS memerlukan consent dan tujuannya jelas. Redaksi log, enkripsi, network TLS, platform permissions, dan pengujian storage/auth/network mengikuti [OWASP MASVS](https://mas.owasp.org/MASVS/) serta [panduan keamanan Flutter](https://docs.flutter.dev/security). Certificate pinning hanya bila threat model dan proses rotasi sertifikat mendukungnya.

## 5. Pembagian mode online/offline

| Fitur | Mode | Aturan |
|---|---|---|
| Sales route, visit, draft SO | Offline-capable P2 | Local draft/outbox; server mengesahkan hasil saat sync |
| Customer/product/price snapshot | Offline read P2 | TTL/versi/scope; label staleness, server wins saat refresh |
| Supervisor approval, credit override, payment, posting | Online-only | Tidak ada keputusan final offline |
| Warehouse scan dan delivery/POD | Online-first atau offline terbatas menurut fitur | Queue hanya untuk aksi yang kontraknya idempotent dan disetujui owner |
| Journal, policy admin, bulk import, financial close | Web only | Tidak ada layar mobile |

Repository menjadi sumber data tunggal yang menggabungkan local/remote. Untuk draft offline, simpan model dan outbox **dalam satu transaksi SQLite** sebelum menampilkan `PENDING_SYNC`; jaringan boleh gagal tanpa menghilangkan draft. Untuk approval online-only, tunggu hasil server sebelum mengubah status final UI. Pola write lokal lalu sinkronisasi dan pilihan online-only dijelaskan di [Flutter offline-first](https://docs.flutter.dev/app-architecture/design-patterns/offline-first).

## 6. Kontrak sinkronisasi P2

Kontrak final harus dinyatakan di `contracts/openapi/<owner-domain>/v1.yaml` milik layanan yang mengoperasikan sync, bukan hanya pada UI. Endpoint PRD: `GET /api/v1/mobile/sync/pull?cursor=...` dan `POST /api/v1/mobile/sync/push`. Bentuk contoh berikut adalah **proposal implementasi**; owner endpoint dan nama field final disahkan bersama backend sebelum coding.

### Local record dan outbox

```text
local_id (UUID), server_guid?, tenant_guid, legal_entity_guid, device_guid,
scope_version, local_version, server_version?, sync_status,
last_sync_at?, created_local_at, updated_local_at

outbox: command_guid, aggregate_local_id, aggregate_server_guid?,
command_type, payload_schema_version, base_server_version?,
idempotency_key, payload_json, state, attempts, next_retry_at,
last_error_code?, created_local_at
```

`idempotency_key` dibuat sekali per command dan tidak diganti saat retry. Outbox tidak menyimpan approval/posting offline. State lokal mengikuti PRD: `LOCAL_DRAFT → PENDING_SYNC → SYNCING → ACCEPTED | NEEDS_REVIEW | REJECTED`; crash di `SYNCING` kembali ke antrean retry dengan key sama. `REJECTED` tidak menghapus draft; pengguna melihat alasan dan dapat membuat command baru setelah revisi.

### Urutan siklus

1. **Bootstrap:** login online, registrasi perangkat, terima daftar koleksi/scope, `scope_version`, snapshot version/TTL, server time, dan cursor awal. Simpan snapshot dan cursor secara atomik per koleksi. Jangan menggunakan jam perangkat sebagai otoritas urutan.
2. **Push:** kirim command FIFO per aggregate; aggregate lain boleh paralel terbatas. Sertakan device, tenant, scope, command GUID, idempotency key, base version, dan schema version. Server memeriksa hak/versi/aturan saat menerima, lalu mengembalikan hasil **per command** (`accepted`, `needs_review`, `rejected`, `pending`) beserta `server_guid`, `server_version`, nomor final bila ada, error code, dan operation ID bila async.
3. **Ack:** commit ack, local↔server ID map, versi, dan status dalam satu transaksi lokal. Jika respons hilang setelah server menerima, retry dengan key sama harus mengembalikan outcome yang sama. Ack diterima tidak berarti SO disetujui; layar membedakan `ACCEPTED` dari state bisnis server.
4. **Pull:** minta delta per `(tenant,user,scope_version,collection,cursor)`, termasuk record baru/berubah dan **tombstone** untuk penghapusan atau data yang tak lagi boleh tampil. Terapkan satu batch record+tombstone+cursor dalam satu transaksi SQLite; cursor maju hanya sesudah commit. Tombstone tidak boleh membuang draft lokal yang belum diputuskan tanpa mencatat konflik akses.
5. **Reset cursor:** bila cursor kedaluwarsa, schema/snapshot version berubah tidak kompatibel, atau `scope_version` berubah, server memberi sinyal reset terstruktur. Klien menghapus cache scoped lama, mengambil snapshot ulang, lalu melanjutkan dengan cursor baru; outbox yang haknya masih valid diverifikasi ulang. Jangan mencoba terus memakai cursor lama.

Pull cursor harus opaque, monotonik dalam scope/koleksinya, dan tidak ditafsirkan klien. Server menyediakan batas batch, `has_more`, tombstone retention yang cukup untuk periode offline maksimum, dan aturan reset ketika gap tidak bisa ditutup. Tidak ada jaminan urutan global lintas aggregate. Foto/POD memakai upload terpisah dengan checksum/resume bila kontrak mendukung; jangan menganggap metadata command sukses berarti file sudah terunggah.

### Konflik, retry, dan revoke

- Server selalu menang untuk master, harga, stok, kredit, status workflow, dan transaksi posted. Perubahan harga/customer blocked/credit/stok saat sync menghasilkan `NEEDS_REVIEW` atau `REJECTED` dengan kode stabil dan informasi aman. Notes/visit dapat merge hanya bila field berbeda dan versi dasar diketahui; konflik pada field sama meminta pilihan pengguna. Tidak ada overwrite senyap.
- Retry `429/503`, timeout, dan jaringan putus dengan exponential backoff+jitter; hanya command ber-idempotency key. `401` mencoba refresh terkontrol lalu meminta login bila gagal. `403`/device revoked menghentikan queue dan memicu purge sesuai kebijakan. `409/412` masuk alur konflik/versi, bukan retry buta.
- Background sync adalah **best effort**. Jalankan juga saat app dibuka, kembali ke foreground, jaringan pulih, dan manual refresh. Jadwal OS tidak boleh dijadikan satu-satunya cara memenuhi target; [Android WorkManager](https://developer.android.com/reference/androidx/work/WorkManager) menunda pekerjaan menurut constraint, sedangkan [Apple Background Tasks](https://developer.apple.com/documentation/uikit/using-background-tasks-to-update-your-app) berjalan atas keputusan sistem.

## 7. Error UX, telemetry, dan pengujian

Normalisasi error HTTP/OpenAPI ke `ApiFailure(status, code, message, requestId, retryable, safeDetails)` di `core/api`; ViewModel mengubahnya menjadi state layar. Tampilkan alasan yang dapat ditindaklanjuti, status sinkronisasi, waktu terakhir berhasil, jumlah pending, dan tindakan “coba lagi”/“tinjau konflik”. `request_id` tersedia untuk support. Jangan mengekspos stack trace, payload mentah, atau detail PII.

Telemetry mobile mencatat event terstruktur (`mobile.sync.command.accepted`, `mobile.sync.conflict`, `mobile.auth.revoked`), `request_id`, `trace_id`/`traceparent`, `correlation_id`, pseudonymous `device_guid`, durasi, jumlah attempt, dan kode hasil. Log lokal hanya diagnostik ber-retention pendek; audit bisnis tetap dicatat server sesuai PRD. Jangan log token, alamat, rekening, tax ID, foto, atau isi order. Instrumentasi harus tetap aman saat offline dan mengirim diagnostik hanya setelah consent/policy telemetry terpenuhi.

Gerbang PR mobile:

1. `dart format`, `dart analyze`, `flutter test`, dan build Android/iOS target lulus; `pubspec.lock` dipertahankan untuk reproduksibilitas aplikasi.
2. Unit test Service/Repository/ViewModel dengan fake clock, fake API/DB, dan kasus retry/idempotency; widget test status loading/offline/conflict, navigasi, aksesibilitas, izin platform, dan format lokal. Lihat [strategi testing Flutter](https://docs.flutter.dev/testing/overview).
3. Integration test di perangkat/emulator: restart setelah draft dibuat, crash saat push/ack/pull, respons hilang, duplicate replay, token expiry/revoke, switch scope, cursor reset/tombstone, konflik harga/stok/customer, file upload terputus, dan perubahan jam perangkat.
4. Uji Android dan iOS nyata untuk keystore, migrasi DB terenkripsi, background constraints, izin kamera/GPS, cold start, dan wipe. Data uji sintetis; tidak ada PII produksi di fixture/log.

## 8. Keputusan lintas tim sebelum implementasi P2

- Backend menentukan schema `push/pull`, outcome per command, cursor reset signal, tombstone retention, ID map, operasi `202`, dan `scope_version` di OpenAPI.
- Security/Product menyetujui offline TTL per data class, perilaku unsent draft saat revoke/scope berubah, device registration/recovery, kebijakan remote wipe, dan klasifikasi foto/GPS.
- Mobile memilih dan memverifikasi adapter SQLite terenkripsi, secure store, OIDC, upload, dan background task pada perangkat target. Library dipin di lockfile dan diuji upgrade keamanannya.
- Ukur metrik PRD `≥95%` command valid tersinkron dalam 15 menit **setelah koneksi stabil dan app mendapat kesempatan eksekusi**; pecah pelaporan foreground/background dan Android/iOS agar batas OS terlihat.
