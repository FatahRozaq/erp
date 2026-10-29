# FSD-FND — Foundation, identity, organization, master dan policy MVP

**Status:** rancangan implementasi Foundation (F-01, F-02, F-09). **Owner:** Platform; Finance/Tax/Process Owner menyetujui aktivasi policy. Kontrak lintas layer mengikuti [standar engineering](../engineering/README.md), [G-01/G-04/G-06](../decisions/mvp-business-policy.md), [PRD §17](../enterprise-erp-prd.md#17-kontrak-fitur-besar) dan [NIST SP 800-63-4](https://csrc.nist.gov/pubs/sp/800/63/4/final). IdP OIDC eksternal menjadi authority autentikasi; ERP menguasai membership, scope, permission dan session version. Token yang valid tidak otomatis memberi akses ke entity.

## 1. Organisasi dan scope

Tenant memiliki banyak Company; Company memiliki banyak LegalEntity; LegalEntity memiliki Branch dan Warehouse. Branch dapat menggunakan beberapa Warehouse dalam LegalEntity yang sama melalui assignment berversi; warehouse tidak berpindah LegalEntity setelah transaksi pertama. Setiap node memiliki GUID, kode unik tenant+jenis selama aktif, nama, status `DRAFT|ACTIVE|INACTIVE`, effective range dan actor/version. Parent cycle, effective overlap untuk hubungan yang sama, tenant/entity mismatch, dan penonaktifan node dengan transaksi aktif ditolak. Riwayat assignment tidak ditulis ulang; perubahan menghasilkan versi efektif baru. `X-Legal-Entity-Guid` dalam API adalah pilihan konteks yang harus termasuk membership dan scope actor, bukan sumber hak.

| Command | Guard tambahan | Commit atomik dan hasil | Error tetap |
|---|---|---|---|
| `CreateOrgNode` | `organization.manage`; parent ACTIVE; jenis parent sah; kode unik | node DRAFT+audit+outbox; ETag versi 1 | `ORG_PARENT_INVALID`, `ORG_CODE_EXISTS` |
| `ActivateOrgNode` | maker≠checker; effective range tidak overlap; referensi parent aktif | ACTIVE+scope_version tenant naik+audit | `APPROVAL_SOD_VIOLATION`, `ORG_EFFECTIVE_OVERLAP` |
| `AssignBranchWarehouse` | same tenant/entity; warehouse aktif; waktu efektif sah | assignment baru; assignment lama ditutup, tidak dihapus | `WAREHOUSE_ENTITY_MISMATCH` |
| `DeactivateOrgNode` | tidak ada tugas/ledger open yang bergantung; versi cocok | INACTIVE dan revoke scope baru; histori transaksi tetap | `ORG_NODE_IN_USE` |

## 2. Identity, session dan authorization

Login memakai Authorization Code + PKCE; gateway memverifikasi signature, issuer, audience, expiry dan key rotation. Platform memetakan `(issuer, subject)` ke user GUID dan tenant membership; user `INVITED→ACTIVE→SUSPENDED→DEACTIVATED`. Role catalog bersifat tenant scoped; permission catalog versioned. Grant mengikat role, legal entity, branch/warehouse optional, effective start/end, pemberi dan alasan. Pemberi hanya dapat mendelegasikan subset hak dan scope sendiri; admin tidak dapat menaikkan haknya sendiri. SoD maker/approver dinilai dari actor asli walau ada delegation. Service principal memakai workload identity dan role khusus, tidak menyamar sebagai user. Permission internal `finance.billing_source.claim/read` hanya untuk Operations→Finance; `credit.reversal_hold.create/read/release` hanya untuk Finance→Commercial. Token workload harus memiliki audience owner, tenant/entity scope, dan permission tepat; endpoint internal tidak menerima user/BFF token. Abort claim dan release hold memverifikasi state owner di server, tidak mempercayai boolean caller sebagai bukti.

Setiap request memeriksa user ACTIVE, session version, membership aktif, permission aksi, entity/branch/warehouse scope dan state dokumen. Cache keputusan authz maksimal 30 detik; suspend/revoke menaikkan `session_version` dan menerbitkan invalidation, sehingga seluruh akses lama berhenti ≤60 detik. Jika Platform tidak dapat memverifikasi status terkini setelah cache kedaluwarsa, aksi mutasi fail closed. Browser BFF menyimpan sesi server side dan cookie HttpOnly/Secure/SameSite; mobile menyimpan token di secure storage. Lihat [OWASP ASVS 5.0](https://asvs.owasp.org/downloads/) sebagai checklist pengujian, bukan klaim sertifikasi.

| Command | Guard | Hasil | Test wajib |
|---|---|---|---|
| `InviteUser` | Security Admin; email unik tenant; scope pemberi mencakup grant awal | INVITED, tautan sekali pakai dengan TTL, audit tanpa token di log | duplicate email; user lintas tenant |
| `GrantRole` | `iam.role.assign`, grant subset, maker≠checker untuk privilege finansial/admin | grant effective version baru, session_version naik | self escalation; grant out-of-scope |
| `SuspendUser` / `RevokeSessions` | admin berizin, reason wajib, version cocok | state/session_version naik; semua BFF/device refresh ditolak | token lama ditolak ≤60 detik |
| `AuthorizeCommand` | token dan context valid, permission+ABAC+SoD | allow/deny terlog tanpa PII | direct URL branch B oleh actor branch A → 403 |

## 3. Master dan policy

SKU/UOM mengikuti [FSD slice pertama](first-slice-fsd.md). Customer dan Vendor mempunyai identity tenant, account per LegalEntity, status `DRAFT|ACTIVE|BLOCKED|INACTIVE`, alamat berversi, tax profile GUID, payment terms dan sensitivitas bank account. CustomerAccount per entity memiliki credit policy version, limit/base currency dan ownership Sales; VendorAccount per entity memiliki procurement terms dan verified bank token. Field sensitif dienkripsi dan perubahan bank/tax ID perlu checker kedua; API mengembalikan masked value. Master yang direferensikan tidak dihapus, tetapi dipensiunkan. Duplicate merge membuat alias GUID/legacy ID dengan riwayat, tanpa mengubah source transaksi lama.

Policy `DRAFT→TESTED→PUBLISHED→RETIRED`; hanya versi PUBLISHED dengan interval yang mencakup business date boleh dipakai. Aktivasi per LegalEntity memuat approval dua pihak untuk tax/credit/approval/posting rule, hasil simulasi fixture, effective range tanpa overlap, actor dan hash snapshot. Command finansial/stok menolak `POLICY_NOT_ACTIVE` bila policy terkait belum aktif; tidak memakai fallback diam diam. Perubahan policy tidak menilai ulang dokumen posted atau approved tanpa revision eksplisit. Numbering per `(tenant,entity,document_type,fiscal_year)` dikunci dalam transaksi owner saat nomor dipakai; nomor yang sudah commit tidak pernah dipakai ulang, gap karena rollback/batal dicatat sesuai audit.

| Command | Guard | Hasil | Contoh negatif |
|---|---|---|---|
| `PublishCustomerOrVendor` | checker untuk bank/tax/credit, alamat dan terms valid, version cocok | snapshot aktif + event minimal; transaksi lama tetap memakai snapshot lama | bank berubah tanpa approval → 403 |
| `SimulatePolicy` | fixture lengkap dan permission policy.manage | output rule match, threshold, tax/credit result, no mutation | rule overlap → 422 |
| `ActivatePolicy` | TESTED, dua approver sah, interval unik, effective date | activation version dan outbox; policy lama ditutup efektif | maker sebagai checker → 403 |
| `QuoteTaxOrPrice` | rule active pada entity/date/customer/SKU | decimal string, rule GUID/version, rounding trace | rule tidak ada → 422 |

## 4. Fixture deterministik dan acceptance

Fixture sintetis: tenant `T`, company `C`, entity `E-A` dan `E-B`, branch `B-A`, warehouse `W-A` pada `E-A`; user `U-sales` hanya `B-A`, `U-buyer` pada `E-A`, `U-approver` terpisah, `U-security`, service principal `S-inventory`. Customer `CUS-1` memiliki account terpisah pada `E-A`/`E-B`; vendor `VEN-1` aktif hanya pada `E-A`. SKU `SKU-1` base UOM pcs dan conversion carton→12 pcs version `V1`. Tax, posting, credit dan approval policy `P1` aktif pada `E-A` untuk business date fixture.

| Given | When | Then |
|---|---|---|
| `U-sales` punya branch `B-A` saja | GET/SUBMIT dokumen branch lain dengan GUID yang diketahui | 403/404 sesuai kebijakan disclosure, tidak ada audit action sukses |
| `U-sales` disuspend | request lama/refresh setelah 60 detik | 401/403, session version tidak cocok |
| `U-security` mencoba grant role admin untuk dirinya | grant dikirim | 403, no write dan audit deny |
| Customer `CUS-1` aktif di `E-A`, tidak di `E-B` | SO dibuat pada `E-B` | 422 `CUSTOMER_ACCOUNT_INACTIVE` |
| Conversion V1 sudah dipakai GRN | conversion V2 diaktifkan | GRN lama tetap 12 pcs/carton, V2 hanya transaksi baru |
| Tax policy belum aktif pada business date | invoice issue | 422 `TAX_POLICY_MISSING`; tidak ada nomor/jurnal |

Kontrak endpoint dan tabel fisik ditautkan dari [gerbang perencanaan](../planning-gate.md) saat lengkap. FSD ini menetapkan perilaku, bukan bukti bahwa semua dependency sudah berjalan.
