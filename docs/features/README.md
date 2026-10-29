# Paket spesifikasi implementasi

1. [FSD slice pertama SKU→PO→GRN→stock ledger](first-slice-fsd.md): actor, guard, state, transaksi, angka, test.
2. [Matriks command MVP](mvp-command-matrix.md): urutan owner, race, recovery dan error.
3. [Model data MVP](mvp-data-model.md): ownership, aggregate, constraint dan migration order.
4. [FSD return Phase 2](returns-fsd.md): pre/post invoice, tax/cost reversal dan replacement.
5. [Protokol mobile sync Phase 2](mobile-sync-protocol.md): push, delta, tombstone, scope reset, conflict.
6. [Kontrak layar web](web-screen-contract.md): route, role, state dan wireframe tekstual slice pertama.
7. [Workload/SLO](../engineering/slo-workload.md): target ukur, fixture dan UAT.
8. [Foundation FSD](foundation-fsd.md), [O2C FSD](o2c-fsd.md), [P2P FSD](p2p-fsd.md), [Inventory/WMS FSD](inventory-wms-fsd.md), [Finance/GL FSD](finance-gl-fsd.md), dan [Platform workflow FSD](platform-workflows-fsd.md): detail alur MVP yang sebelumnya belum ada.
9. [Desain data fisik MVP](mvp-physical-data-design.md) dan [kamus fisik/migration](mvp-data-dictionary.md): owner, tipe, constraint, urutan, seed, dan penyesuaian SQL awal.
10. [Peta layar MVP](mvp-ux-screen-map.md) dan [detail UX kritikal](mvp-ux-detail.md): route, field, permission, state, dan wireframe tekstual.
11. [Keputusan penutup MVP](mvp-completion-contract.md) dan [kontrak policy](mvp-policy-contract.md): batas rilis, exception, reversal, dan simulasi typed.
12. [Template impor MVP](mvp-import-templates.md): CSV exact, validasi, row result, dedup dan opening balance.

Kontrak mesin: [OpenAPI](../../contracts/openapi/README.md), [event JSON Schema](../../contracts/events/README.md), dan DDL awal di `backend/golang/services/*/migrations`. [Threat model](../architecture/security-threat-model.md), [rencana QA](../quality/mvp-verification-plan.md), [vektor kontrak](../quality/mvp-contract-vectors.md), dan [cutover/runbook](../operations/mvp-cutover-and-runbook.md) melengkapi paket lintas fitur. Phase 2, Phase 3 dan Enterprise Expansion lanjut di [paket roadmap](../roadmap/README.md). Status gerbang sebelum coding mengikuti [audit perencanaan](../planning-gate.md) dan [gerbang seluruh roadmap](../roadmap/roadmap-planning-gate.md). Persetujuan policy produksi dan bukti runtime tidak dapat digantikan oleh dokumen.
