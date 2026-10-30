# Baseline keputusan arsitektur sebelum coding

**Scope:** baseline Foundation+MVP yang diperluas oleh [paket seluruh roadmap](../roadmap/README.md). Dokumen ini melengkapi [PRD §§28–35](../enterprise-erp-prd.md#28-system-architecture-dan-prinsip), [standar repository](../engineering/repository-standards.md), [ADR receipt](../adr/0001-receipt-limit-owner.md), [ADR fiscal period](../adr/0002-fiscal-period-overlap.md), [ADR Echo/Next.js](../adr/0003-echo-metronic.md), [ADR template shadcn-admin](../adr/0005-shadcn-admin-frontend.md), [ADR migration/function](../adr/0004-versioned-database-functions.md), dan [ADR layout SQL/sqlc](../adr/0006-database-sql-layout.md). Keputusan di bawah dipakai sebagai default code review; perubahan memerlukan ADR bernomor dan contract migration plan.

| Keputusan | Baseline | Konsekuensi/guard |
|---|---|---|
| Deployable MVP | gateway, platform, commercial, operations, finance; modul internal domain, bukan service per entity | ownership data ketat; scaling/pemisahan setelah metrik dan consumer contract stabil |
| Database | PostgreSQL 18; database per deployable, schema per modul; `backend/database/migrations/<schema>/` dan `queries/<schema>/` untuk sqlc; migration dan function DB berversi; Finance+Accounting transaksi lokal pengecualian | role per schema; generated Go di adapter owner; function untuk invariant atomik lokal; no direct SQL lintas deployable; backup/restore per owner dan cross-owner reconcile |
| Identity | IdP OIDC; ERP Platform menyimpan membership/scope/session version; gateway dan service memvalidasi | token bukan permission tunggal; revoke ≤60 s; service-to-service workload identity |
| API | Go Echo v5 sebagai HTTP adapter, REST `/api/v1`, OpenAPI 3.1.1, decimal string, GUID publik, ETag/If-Match, stable error JSON, idempotency | satu source-of-truth di `contracts/openapi`; business logic di application/domain, BFF browser, mobile direct gateway |
| Event | NATS JetStream, outbox/inbox, at-least-once, versioned JSON Schema | no exactly-once assumption, DLQ/replay audit, operation/source key permanen |
| Cache | Redis untuk session/rate/cache non-authoritative | stock/credit/GL posting selalu primary DB; cache key scope version dan invalidation |
| Document | object store private, signed URL pendek, quarantine/scan/hash | metadata owner di DB, URL tidak di-log; issued evidence immutable version |
| Search/report | PostgreSQL FTS/projection awal, watermark/freshness | command tidak memakai projection sebagai authority; OpenSearch hanya lewat ADR berbasis beban |
| Web/mobile | Next.js BFF+TypeScript dengan shadcn-admin MIT UI wrapper dan Flutter repository local/remote | OIDC/session dan database ERP sendiri; server authz; mobile offline order Phase 2; web cache scoped |
| Reliability | 99,9% API target awal, RPO 15 menit/RTO 4 jam target pilot yang perlu biaya/uji | backup WAL/PITR, restore rehearsal, SLO dan runbook sebelum produksi |

**Batas transaksi:** stok/movement/reservation lokal Operations; credit bucket lokal Commercial; invoice/payment/journal lokal Finance; approval decision lokal Platform. Transaksi tidak menahan lock selama network call. Saga state terlihat operator, dengan retry bounded, idempotent ack dan reconciliation. Policy runtime tidak bisa mengubah immutable ledger; correction membuat dokumen baru. [Threat model](security-threat-model.md) memetakan trust boundary dan uji keamanan.
