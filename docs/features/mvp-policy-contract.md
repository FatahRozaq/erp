# POL-001 — Bentuk policy dan simulasi Foundation+MVP

**Owner:** Platform menyimpan versi/aktivasi; Tax, Controller, Credit Controller dan Process Owner menyetujui isi. Policy yang dipakai command disnapshot sebagai GUID+content hash+effective interval; published version immutable. Dokumen ini menerjemahkan [G-04–G-07](../decisions/mvp-business-policy.md) menjadi input/output yang harus tersedia sebelum handler dibuat. Aktivasi per legal entity tanpa dua approver sah dan fixture lulus ditolak.

| Jenis policy | Field wajib per versi | Pemilihan deterministik | Gagal tertutup bila |
|---|---|---|---|
| `TAX` | jurisdiction, entity PKP status, party tax class, SKU/service class, transaction type, effective range, VAT rate, DPP factor numerator/denominator, inclusive, exemption evidence rule, withholding type/rate, rounding, GL map, regulation reference | exact entity+class+type+date; specificity tertinggi; dua rule sama spesifik overlap ditolak saat publish | tidak ada rule, klasifikasi khusus tidak jelas, exemption evidence hilang |
| `PRICE` | entity, currency, customer segment/account optional, SKU, UOM, base unit price, effective range, priority, minimum margin rule | exact account > segment > default; effective version terakhir yang sudah terbit, priority unik per scope | tidak ada harga, rule overlap ambigu, cost floor hilang saat diskon manual |
| `CREDIT` | entity/customer account, limit base currency, eligible deposit rules, FX source/age/buffer, override enabled/max/expiry/SoD | account exact; tiap source portion satu bucket; gunakan primary DB dan lock account sebelum check | rate stale >72 h, account blocked, limit nol tanpa prepaid flow, bucket inconsistency |
| `APPROVAL` | document type, amount lower/upper inclusive flags, role, scope, discount threshold, SoD, effective range | first exact document/entity rule with nonoverlap interval; amount/discount step digabung tanpa self approval | gap/overlap threshold, no approver, maker=checker/delegator |
| `POSTING` | source type/action, debit/credit leg, account type/code, required dimensions, currency/FX, rounding residual account, effective range | exact entity/source/action/class/date; setiap leg punya satu account valid | mapping hilang/ambiguous, account inactive, period closed, journal imbalance |
| `NUMBERING` | entity, document type, fiscal year, prefix, width, next value, gap policy | satu row lock per key; nomor final saat commit document | key/config absent, duplicate number, year mismatch |

Semua versi mempunyai `policy_guid`, `policy_type`, `version`, `content_hash`, `status`, `created_by/at`, `tested_at/result_hash`, `published_at/by`, `effective_from/to`. Runtime cache keyed `(entity,type,version)` dan invalidasi dari event; jika cache kedaluwarsa dan owner tidak tersedia, command kritikal menolak. Mutasi policy aktif membuat versi baru dan effective interval baru; tidak menulis ulang invoice/PO/SO lama.

## Simulasi wajib sebelum publish

| Policy | Fixture input | Expected output |
|---|---|---|
| TAX | ID nonmewah, net 120.000, 12%×11/12, exclusive | DPP 110.000, VAT 13.200, gross 133.200 |
| TAX | rule barang mewah tanpa PPnBM rate/class | `TAX_POLICY_MISSING`, tidak memakai rule nonmewah |
| PRICE | SKU base 200, manual discount 5%, cost 110 | net unit 190; approval Sales Manager tambahan; tax dari net |
| CREDIT | limit 1.000, gross buckets 850, eligible deposit 100, new SO 300 | net exposure 750, available 250, SO hold |
| APPROVAL | gross 9.999.999; 10.000.000; 100.000.000; 100.000.001 | Supervisor; Manager; Manager; Director |
| APPROVAL | maker dan approver GUID sama | 403 `APPROVAL_SOD_VIOLATION` |
| POSTING | POD 3×200, tax 66, cost 330 | AR 666/revenue 600/output tax 66; COGS 330/in-transit 330; balanced |
| NUMBERING | dua submit paralel satu entity/type/year | dua nomor berbeda; retry operation sama mendapat nomor pertama |

Simulasi response menyimpan input hash, matched rule GUID/version, output fields, numeric trace, pass/fail dan error code. Publish memerlukan fixture positif/negatif sesuai jenis, tidak hanya satu contoh happy path. Policy activation awal memakai effective date masa depan atau saat belum ada transaksi; backdated activation setelah posted document ditolak. Exception Controller yang mengizinkan correction adalah dokumen baru, bukan overwrite.
