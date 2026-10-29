# Threat model awal Foundation+MVP

**Scope:** web BFF, mobile online, gateway, Platform/Commercial/Operations/Finance, PostgreSQL per owner, Redis, JetStream dan private object storage. **Metode:** trust-boundary review + threat/control/test per data flow; baseline mengacu pada [OWASP ASVS 5.0](https://asvs.owasp.org/downloads/), [OWASP API Security Top 10](https://owasp.org/API-Security/editions/2023/en/0x11-t10/), dan [NIST SP 800-63-4](https://csrc.nist.gov/pubs/sp/800/63/4/final). Ini rencana kontrol, bukan klaim audit/sertifikasi. Pemilik Security menyetujui implementasi dan hasil uji sebelum pilot.

## Aset dan batas kepercayaan

| Boundary | Aset | Keputusan kontrol |
|---|---|---|
| Browser→BFF | session, CSRF, izin UI | cookie HttpOnly/Secure/SameSite, anti-CSRF untuk mutasi, CSP, no token browser storage; BFF tidak memegang rule bisnis |
| Mobile→Gateway | access/refresh token, cache, POD | PKCE, device binding/revocation, secure storage, local encryption, TTL; sync command server authoritative |
| Gateway→service | actor, tenant/entity/scope, trace | signed/validated token atau internal identity; gateway header tidak dipercaya tanpa autentikasi internal; service tetap authorize resource |
| Service→owner DB | transaksi, ledger, PII | role least privilege per schema, parameterized SQL, row scope server, append-only role, migration role terpisah |
| Outbox→JetStream→inbox | event, source GUID, operation | schema/version, publisher auth, subject ACL, inbox dedup, replay audit, DLQ, no secret/PII penuh |
| API→object store | POD, invoice, CSV | signed URL per object/action pendek, quarantine/scan/hash, private bucket, no URL di log, retention/hold |
| Finance→report/export | AR/AP/GL dan PII | query scope sebelum pagination, watermark, export authorization, encrypted delivery, audit download |

## Ancaman prioritas dan verifikasi

| ID | Skenario serangan/kegagalan | Kontrol yang harus diuji | Gate |
|---|---|---|---|
| TM-01 | GUID entity/branch lain ditebak (BOLA/IDOR) | owner lookup dibatasi tenant/entity/branch; cross-scope 403/404; tidak ada count/search leak | setiap API query/command |
| TM-02 | Header tenant/entity dipalsukan melalui gateway/BFF | context dari identity tepercaya; service memvalidasi membership dan signature; header client tidak memberi hak | auth integration test |
| TM-03 | Admin menaikkan hak sendiri/delegator menjadi approver | grant subset, maker≠checker termasuk delegation, dual approval privilege sensitif, audit before/after | IAM/approval tests |
| TM-04 | Token lama dipakai setelah suspend/revoke | session version/invalidation ≤60 detik, refresh rotation/reuse detection, fail closed mutasi saat cache stale | device/BFF tests |
| TM-05 | Duplicate/replay event atau HTTP command menggandakan stock/journal | idempotency response, operation registry/source uniqueness, inbox dedup, at-least-once tests | inventory/finance tests |
| TM-06 | File CSV/POD berbahaya atau signed URL bocor | MIME+magic/hash/size/scan, quarantine, URL TTL/object ACL, URL tak dicatat, formula-escape export | upload/export tests |
| TM-07 | SQL injection/SSRF/XSS/CSRF pada search, report atau webhook | parameterized queries, allowlist egress, output encoding, CSP, CSRF protection, webhook HMAC+timestamp | security suite |
| TM-08 | Ledger/audit diubah/hilang oleh admin aplikasi | DB role no UPDATE/DELETE, reversal-only, hash chain/daily signed digest, restore sampling | DB permission + integrity test |
| TM-09 | Data tenant tercampur di cache/projection | cache key mencakup tenant/entity/scope version; switch scope purge; query filter sebelum aggregation; purge revoked records | web/mobile/search test |
| TM-10 | Secret/PII muncul di log/trace/notification | allowlisted structured fields, redaction, restricted access/retention, sampling, no URL/token/full payload | log snapshot test |
| TM-11 | Backup tidak dapat dipulihkan atau region melanggar policy | encrypted backup/WAL, restore rehearsal, region Indonesia untuk data pembukuan, legal hold | DR/UAT gate |
| TM-12 | Dependency outage mengakibatkan izin fail open atau posting separuh | deadline/circuit breaker, fail closed auth/finance, status pending, retries bounded, reconciliation queue | fault-injection suite |

## Data minimization dan incident path

Tax ID, rekening, alamat, nomor telepon dan bukti POD disimpan hanya pada owner yang memerlukan, terenkripsi sesuai kelas dan ditampilkan masked secara default. Audit mencatat actor/action/source/hasil dengan nilai sensitif disamarkan; full body atau token tidak dicatat. PII export dan document download mempunyai permission tersendiri, purpose/reason, watermark dan audit. Security event severity tinggi memicu revoke session, isolasi token/service credential, penyimpanan bukti, dan runbook pemulihan; posted transaction tidak dihapus untuk menutupi insiden. Retention mengikuti [G-16](../decisions/mvp-business-policy.md#g-16oq-09--data-retensi-dan-lokasi-operasi-indonesia).

**Review gate:** Security Lead meninjau setiap boundary/ID di atas, menambah ancaman spesifik deployment/IdP/object store nyata, lalu menautkan hasil pen-test/fault test pada release evidence. Nilai residual risk dan pengecualian memakai ADR/owner/expiry, tidak diam-diam dikecualikan.
