# Instruksi agent — Flutter

Mobile aktif akan di-scaffold di `mobile/flutter/`. Baca [standar mobile Flutter](../../docs/engineering/mobile-standards.md), [protokol sync](../../docs/features/mobile-sync-protocol.md) untuk fitur P2, FSD layar, serta kontrak OpenAPI yang dipakai.

- Susun per fitur: Screen → ViewModel → Repository → remote/local Service; `core/` hanya memuat fasilitas lintas fitur. Tambah layer domain/use case bila kompleksitas nyata memerlukannya.
- Generated DTO tidak diedit manual dan tidak langsung menjadi model UI. Pertahankan decimal string/precision, server `guid`/`version`, serta local draft ID dan idempotency key sesuai kontrak.
- Gunakan penyimpanan lokal terenkripsi dan secure store untuk credential; login OIDC memakai browser sistem dengan PKCE. Offline queue tidak mengesahkan transaksi atau approval.
- Jalankan format/analyze/test/build dan tes perangkat untuk perilaku sync, revoke, crash recovery, serta permission yang berubah.

`lib/`, `test/`, dan folder platform dibuat pada work order scaffold; struktur detailnya ada pada standar mobile.
