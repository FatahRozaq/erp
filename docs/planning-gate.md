# Gerbang kelengkapan perencanaan sebelum coding ERP

**Audit diperbarui oleh R-01, 29 Oktober 2026. Keputusan: baseline Foundation+MVP tersedia, dengan GAP-01–03 yang harus dilengkapi sebelum coding slice terkait.** [Audit R-01](roadmap/r-01-audit.md) dan [backlog](roadmap/implementation-backlog.md) menggantikan klaim sebelumnya bahwa semua detail F-01–F-10 bebas gap. Status ini menilai dokumen, bukan aplikasi, UAT atau izin aktivasi transaksi riil.

## 1. Arti siap untuk coding

Dokumen Foundation+MVP menyediakan requirement/scope, FSD, kontrak, data, UX dan expected test vector untuk alur inti. Coverage artefak tidak otomatis memenuhi [Definition of Ready PRD §56](enterprise-erp-prd.md#56-definition-of-ready) untuk seluruh field dan flow: GAP-01–03 tetap NEEDS_SPEC pada backlog R-01. Perubahan yang menggeser policy, data, API atau aksi UI harus memperbarui paket yang terkait sebelum handler/client dibuat; implementasi tidak boleh menebak nilai tenant.

Migration/seed **baru** adalah hasil tahap coding yang memakai [DATA-003](features/mvp-data-dictionary.md), bukan dokumen yang harus pura-pura sudah ada. Sebelas migration awal diuji sebagai bukti subset SQL yang ada. Test runtime, lint governance dengan workspace login, visual accessibility review, benchmark, restore drill, UAT, dan sign-off policy legal entity adalah gate merge/release/produksi sesuai tahapnya. Nilai tax/COA/credit/approval aktif pada tenant riil tetap memerlukan process owner; engine/config dan fixture sintetis dapat dibangun dari baseline yang telah diputuskan.

## 2. Traceability capability

| PRD | Paket desain yang menutupnya | Status planning |
|---|---|---|
| F-01 Org/IAM | [Foundation FSD](features/foundation-fsd.md), [MVP-003 akses](features/mvp-completion-contract.md#f-01f-02--akses-dan-master), [Platform API](../contracts/openapi/platform/v1.yaml), [DATA-003](features/mvp-data-dictionary.md), [UX-003](features/mvp-ux-detail.md), [QA-002](quality/mvp-contract-vectors.md) | **NEEDS_SPEC subset GAP-01** |
| F-02 Master | [FSD slice awal](features/first-slice-fsd.md), Foundation/MVP-003, [Master API](../contracts/openapi/master/v1.yaml) dan Platform party API, DATA-003/UX-003/QA-002 | **NEEDS_SPEC subset GAP-02** |
| F-03 Sales/price/credit | [O2C FSD](features/o2c-fsd.md), [MVP-003 revisi/override](features/mvp-completion-contract.md#f-03f-04--revisi-transaksi-dan-override), [Sales API](../contracts/openapi/sales/v1.yaml), Platform price/policy API, DATA-003/UX-003/QA-002 | **NEEDS_SPEC quotation/repeat GAP-03** |
| F-04 PR/PO/GRN | [P2P FSD](features/p2p-fsd.md), MVP-003, [PR](../contracts/openapi/requisition/v1.yaml), [PO](../contracts/openapi/purchase/v1.yaml), [GRN](../contracts/openapi/inventory/v1.yaml), DATA-003/UX-003/QA-002 | **SIAP** |
| F-05 Stock/reservation/adjustment | [Inventory/WMS FSD](features/inventory-wms-fsd.md), [MVP-003 lot/serial](features/mvp-completion-contract.md#f-05f-06--lotserial-reservation-pack-dan-pod), [Operations API](../contracts/openapi/operations/v1.yaml), DATA-003/UX-003/QA-002 | **SIAP** |
| F-06 Pick/pack/delivery/POD | Inventory/WMS FSD, MVP-003 partial/correction, Operations API dengan pack/dispatch line, [event delivery](../contracts/events/README.md), DATA-003/UX-003/QA-002 | **SIAP** |
| F-07 AR/AP/payment/tax document | [Finance/GL FSD](features/finance-gl-fsd.md), [MVP-003 koreksi](features/mvp-completion-contract.md#f-07f-08--koreksi-finance-close-dan-report), [Finance API](../contracts/openapi/finance/v1.yaml), DATA-003/UX-003/QA-002 | **SIAP** |
| F-08 GL/close/report | Finance/GL FSD, MVP-003 close attestation, [Accounting API](../contracts/openapi/accounting/v1.yaml), DATA-003 termasuk transisi draft→posted dari SQL awal, UX-003/QA-002 | **SIAP** |
| F-09 Approval/tax/policy | [Policy contract](features/mvp-policy-contract.md), Foundation FSD, MVP-003 SoD/callback, typed Platform policy API, [Workflow API](../contracts/openapi/workflows/v1.yaml), event approval/policy, UX-003/QA-002 | **SIAP** |
| F-10 Import/document/notification/report | [Platform FSD](features/platform-workflows-fsd.md), [IMP-001 CSV](features/mvp-import-templates.md), MVP-003, Workflow API, DATA-003/UX-003/QA-002 | **SIAP** |

Paket lintas fitur: [standar engineering](engineering/README.md), [ADR arsitektur](architecture/architecture-decisions.md), [threat model](architecture/security-threat-model.md), [desain fisik](features/mvp-physical-data-design.md), [peta layar](features/mvp-ux-screen-map.md), [rencana QA](quality/mvp-verification-plan.md), [SLO/workload](engineering/slo-workload.md), dan [cutover/runbook](operations/mvp-cutover-and-runbook.md). Semua capability F-01–F-10 memakai [matriks command](features/mvp-command-matrix.md) serta [kontrak API](../contracts/openapi/README.md)/[event](../contracts/events/README.md) sebagai sumber versi.

## 3. Bukti audit dokumen dan batas bukti

- **API:** total seluruh roadmap 16 OpenAPI 3.1.1, 258 operasi dan 585 contoh request/response langsung. Semua lulus Postman CLI syntax lint, validator OpenAPI 3.1 dan validasi contoh JSON Schema lokal. Angka dan failure spesifik Foundation+MVP diuji menurut QA-002; fase lanjut menurut [QA-RM](roadmap/roadmap-test-vectors.md). Ini belum membuktikan server/consumer menjalankannya.
- **Event:** 43 JSON Schema Draft 2020-12 beserta 43 contoh lulus schema + format check. Producer/consumer, replay, gap dan DLQ ditetapkan pada [matriks event](../contracts/events/README.md). Belum ada worker runtime.
- **Data:** 11 migration SQL awal berhasil di-apply pada empat database owner PostgreSQL 18 lokal, termasuk perubahan PO `vendor_account_guid`; kamus DATA-003 menyebut tabel/kolom baru, koreksi kompatibilitas SQL awal, seed dan urutan berikutnya. SQL untuk sisa tabel belum ditulis karena itulah pekerjaan implementasi yang akan dimulai.
- **UX/QA/ops:** FSD, wireframe tekstual, field/error/loading/pending, fixture, threat model, cutover dan runbook tersedia. Verifikasi visual, aksesibilitas, performa, backup/restore dan UAT adalah bukti runtime berikutnya.

## 4. Batas scope dan gate berikutnya

F-11 mobile offline, F-12 return/transfer, F-13/F-14 enterprise controls dan bounded Enterprise Expansion kini mempunyai [paket desain siap coding](roadmap/roadmap-planning-gate.md). Urutan fase tetap berlaku; kelulusan desain fase lanjut tidak memindahkan fiturnya ke scope pilot MVP. Scope MVP mengecualikan credit memo, transfer intercompany, bank feed, scheduled report, external tax submission otomatis, dan approval paralel; koreksi yang membutuhkan fitur itu menjadi exception terkontrol sesuai MVP-003.

Urutan implementasi: Foundation IAM/org/master/policy → Commercial PO/PR/SO/credit → Operations GRN/reservation/WMS → Finance AR/AP/GL → Platform jobs/reporting → E2E dan pilot. Tiap slice harus menambah migration/fixture, handler/worker/UI, contract tests, authz/SoD/concurrency/idempotency/reconciliation, observability dan reviewer domain. Nilai legal entity pilot, source-system mapping nyata, IdP/deployment specifics, kapasitas, retention schedule final, serta tanda tangan Product/Tax/Controller/Security adalah keputusan aktivasi **produksi**, bukan asumsi dalam kode. Bila nilai riil belum tersedia, konfigurasi tetap tidak aktif dan transaksi fail closed.

**Kesimpulan:** dokumen teknis untuk memulai coding seluruh roadmap sesuai urutan dan batas fase sudah siap. Go-live tiap fase menunggu gate runtime dan owner activation yang relevan.
