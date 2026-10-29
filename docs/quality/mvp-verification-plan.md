# QA-001 — Rencana verifikasi dan traceability Foundation+MVP

**Tujuan:** menghubungkan requirement PRD ke bukti yang dapat diulang sebelum pilot. [Definition of Ready/Done](../enterprise-erp-prd.md#56-definition-of-ready) dan [SLO/workload](../engineering/slo-workload.md) berlaku. Tes runtime belum ada karena aplikasi belum dibuat; tabel ini menentukan fixture, failure dan exit condition sebelum coding, sehingga tidak menebak kriteria lulus saat implementasi.

## Tingkat bukti

1. **Contract static:** OpenAPI/event JSON Schema parse, `$ref`, required/nullability/example positif/negatif, compatibility diff, permission/error matrix.
2. **Domain unit/property:** uang decimal/rounding, UOM, cost, tax, credit exposure, approval thresholds, state transition dan source eligibility.
3. **PostgreSQL integration:** migration up/forward fix, tenant/entity FK/unique, transaction rollback, SERIALIZABLE period/interval, row lock concurrency, audit/outbox/idempotency atomicity.
4. **Service integration:** OIDC scopes, BFF cookie/CSRF, owner API contract, JetStream duplicate/out-of-order/gap/DLQ, object scan, Redis outage fail mode.
5. **E2E business:** O2C, P2P, R2R dengan partial, duplicate, failure/retry, correction, reconciliation dan UI state.
6. **Pilot NFR/UAT:** workload representatif, p95/p99/5xx, backup restore RPO/RTO, accessibility WCAG 2.2 AA, security ASVS mapped, signed process-owner evidence.

## Traceability minimum

| Requirement / FSD | Fixture inti | Positif | Negatif/concurrency | Bukti exit |
|---|---|---|---|---|
| F-01 / [Foundation](../features/foundation-fsd.md) | T/E-A/E-B/B-A/W-A; U-sales/U-admin/U-approver | scoped user membuat dokumen E-A | direct URL E-B, self grant, suspend token ≤60 s, parent cycle | authz matrix dan audit deny |
| F-02 / Foundation + [slice 1](../features/first-slice-fsd.md) | SKU pcs/carton 1:12, CUS/VEN account | publish master, GRN 2 carton→24 pcs | conversion 0/overlap, bank change tanpa checker | snapshot lama tetap |
| F-03 / [O2C](../features/o2c-fsd.md) | limit 1.000, two SO gross 700 | one SO passes; approval→reservation | two parallel submit, duplicate key, maker approve, price missing | one commitment, no overspend |
| F-04 / [P2P](../features/p2p-fsd.md) | PO 10 @100 | GRN 6+4, GRNI 1.000, AP 1.110 | GRN +1, invoice before receipt, price 105 | no overstock/double AP |
| F-05/F-06 / [Inventory/WMS](../features/inventory-wms-fsd.md) | stock 10 @110, SO 5 | reserve/pick/dispatch/POD 3+2 | 100 reservation race, serial double scan, POD duplicate, Finance outage | balances and source portions reconcile |
| F-07/F-08 / [Finance/GL](../features/finance-gl-fsd.md) | AR 666, payment 400; AP 666, payment 300 | open AR 266/AP 366; balanced journals | duplicate bank ref, period closed, unbalanced journal, GL mismatch | trial balance/AR/AP controls zero delta |
| F-09 / Foundation | approval boundaries 9.999.999/10.000.000/100.000.000/100.000.001; VAT examples G-04 | expected role/tax | gap/overlap rule, tax absent, self decision | simulation snapshot/version and audit |
| F-10 / [Platform workflows](../features/platform-workflows-fsd.md) | CSV 100 rows/3 error; clean and malicious object | 97 valid rows, scoped search/report | changed hash, cross-entity search, scan fail, event duplicate | no duplicate/PII leak |

Setiap scenario ditulis Given/When/Then di tes dengan trace ID `Fxx-ACxx`, fixture dan expected ledger/GL. Kegagalan test mencatat actual vs expected, owner dan source operation GUID; flaky test tidak diabaikan. Tidak memakai coverage percentage sebagai satu-satunya gate. Test data sintetis, bebas PII nyata; data rehearsal produksi dimasking dengan persetujuan Security/Legal.

## Failure injection dan release gate

MVP wajib menguji crash sebelum/tepat setelah DB commit, broker publish ulang, consumer gap, owner API timeout, Redis unavailable, object scan gagal, Finance posting gagal setelah POD, deadlock/serialization retry, delayed event cut-off, backup restore dan session revoke saat request. Expected state harus eksplisit `PENDING|EXCEPTION|RETRYABLE`, tidak setengah posted atau diam-diam sukses. Semua posting stok/keuangan direkonsiliasi setelah test; unexplained delta=0.

Load profile awal dari [SLO/workload](../engineering/slo-workload.md) dipakai untuk development; pilot user/concurrency, puncak order/GRN/POD, ukuran SKU, cabang, koneksi dan scanner nyata harus direkam pada M0 sebelum benchmark final. Target awal API 99,9% dan RPO 15 menit/RTO 4 jam adalah asumsi, bukan hasil uji. Go/no-go pilot menuntut zero double posting/negative stock/unexplained ledger mismatch, security critical/high resolved, backup restore evidence, p95/5xx dalam SLO, dan UAT owner signed. Governance lint Postman workspace dapat ditambahkan saat tersedia; lint sintaks lokal tidak membuktikan perilaku server.
