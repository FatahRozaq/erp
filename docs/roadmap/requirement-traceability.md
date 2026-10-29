# TR-001 — Requirement → slice → work order

**Baseline R-01.** Matriks ini melacak coverage perencanaan, bukan hasil tes atau bukti runtime. [Backlog BL-001](implementation-backlog.md) memberikan acceptance, owner/reviewer, dependency, FSD/kontrak/data/UX/QA per slice. `NEEDS_SPEC` tetap dihitung sebagai scope tercatat, tetapi belum siap kode. Status gap ada pada [audit R-01](r-01-audit.md).

## Requirement bernomor PRD

| Requirement | Slice implementasi/verifikasi |
|---|---|
| AC-ACC-01 | [M-03.1](implementation-backlog.md#m-03), [M-07.3](implementation-backlog.md#m-07) |
| AC-APP-01 | [F-03.1](implementation-backlog.md#f-03) |
| AC-BUD-01 | [P3-02.1](implementation-backlog.md#p3-02) |
| AC-BUD-02 | [P3-02.1](implementation-backlog.md#p3-02) |
| AC-FIN-01 | [M-03.3](implementation-backlog.md#m-03), [M-07.2](implementation-backlog.md#m-07) |
| AC-IAM-01 | [F-01.2](implementation-backlog.md#f-01) |
| AC-IAM-02 | [F-01.2](implementation-backlog.md#f-01) |
| AC-IMP-01 | [M-08.1](implementation-backlog.md#m-08) |
| AC-INV-01 | [M-05.1](implementation-backlog.md#m-05) |
| AC-INV-02 | [M-02.1](implementation-backlog.md#m-02) |
| AC-MDM-01 | [F-02.1](implementation-backlog.md#f-02) |
| AC-MOB-01 | [P2-04.3](implementation-backlog.md#p2-04) |
| AC-PUR-02 | [M-02.1](implementation-backlog.md#m-02) |
| AC-RET-01 | [P2-02.1](implementation-backlog.md#p2-02) |
| AC-RET-02 | [P2-02.1](implementation-backlog.md#p2-02) |
| AC-RFQ-01 | [P2-01.1](implementation-backlog.md#p2-01), [P2-01.2](implementation-backlog.md#p2-01) |
| AC-SAL-01 | [M-04.2](implementation-backlog.md#m-04) |
| AC-SAL-02 | [M-04.2](implementation-backlog.md#m-04) |
| AC-TRF-01 | [P2-03.1](implementation-backlog.md#p2-03) |
| AC-WMS-01 | [M-05.2](implementation-backlog.md#m-05) |
| BR-ACC-01 | [F-03.4](implementation-backlog.md#f-03), [M-03.1](implementation-backlog.md#m-03), [M-07.1](implementation-backlog.md#m-07), [M-07.3](implementation-backlog.md#m-07), [P3-04.2](implementation-backlog.md#p3-04), [P3-06.1](implementation-backlog.md#p3-06), [E-01.2](implementation-backlog.md#e-01) |
| BR-APP-01 | [F-03.1](implementation-backlog.md#f-03), [M-01.2](implementation-backlog.md#m-01), [M-04.3](implementation-backlog.md#m-04), [P3-01.1](implementation-backlog.md#p3-01) |
| BR-BUD-01 | [P3-02.1](implementation-backlog.md#p3-02) |
| BR-CRD-01 | [M-04.2](implementation-backlog.md#m-04), [M-04.3](implementation-backlog.md#m-04), [M-07.2](implementation-backlog.md#m-07) |
| BR-FIN-01 | [M-03.2](implementation-backlog.md#m-03), [M-07.2](implementation-backlog.md#m-07), [P2-02.2](implementation-backlog.md#p2-02), [P3-02.2](implementation-backlog.md#p3-02), [P3-04.1](implementation-backlog.md#p3-04), [E-02.2](implementation-backlog.md#e-02) |
| BR-IAM-01 | [B-03.1](implementation-backlog.md#b-03), [F-01.1](implementation-backlog.md#f-01), [F-01.2](implementation-backlog.md#f-01) |
| BR-IAM-02 | [F-01.2](implementation-backlog.md#f-01), [F-03.1](implementation-backlog.md#f-03), [M-01.1](implementation-backlog.md#m-01), [P3-01.2](implementation-backlog.md#p3-01) |
| BR-INT-01 | [P3-05.2](implementation-backlog.md#p3-05), [E-03.2](implementation-backlog.md#e-03) |
| BR-INV-01 | [M-02.1](implementation-backlog.md#m-02), [P2-03.3](implementation-backlog.md#p2-03), [P3-03.2](implementation-backlog.md#p3-03) |
| BR-INV-02 | [M-02.2](implementation-backlog.md#m-02), [M-05.1](implementation-backlog.md#m-05), [E-01.1](implementation-backlog.md#e-01) |
| BR-MDM-01 | [F-02.1](implementation-backlog.md#f-02) |
| BR-MOB-01 | [P2-04.3](implementation-backlog.md#p2-04) |
| BR-PRC-01 | [F-03.2](implementation-backlog.md#f-03), [P3-03.1](implementation-backlog.md#p3-03) |
| BR-PUR-01 | [M-01.2](implementation-backlog.md#m-01), [M-02.1](implementation-backlog.md#m-02), [P2-01.2](implementation-backlog.md#p2-01) |
| BR-SAL-01 | [M-06.1](implementation-backlog.md#m-06), [M-06.2](implementation-backlog.md#m-06), [P2-02.1](implementation-backlog.md#p2-02) |
| BR-TIM-01 | [F-03.2](implementation-backlog.md#f-03), [F-03.4](implementation-backlog.md#f-03), [P2-04.2](implementation-backlog.md#p2-04), [P3-04.2](implementation-backlog.md#p3-04) |
| BR-TRF-01 | [P2-03.1](implementation-backlog.md#p2-03), [P3-06.1](implementation-backlog.md#p3-06) |
| BR-WMS-01 | [M-05.2](implementation-backlog.md#m-05), [P2-03.2](implementation-backlog.md#p2-03) |
| FR-ACC-01 | [F-03.4](implementation-backlog.md#f-03), [M-03.1](implementation-backlog.md#m-03), [M-07.3](implementation-backlog.md#m-07), [P3-04.2](implementation-backlog.md#p3-04), [E-01.2](implementation-backlog.md#e-01) |
| FR-ACC-02 | [M-07.3](implementation-backlog.md#m-07), [P2-05.1](implementation-backlog.md#p2-05), [P3-06.2](implementation-backlog.md#p3-06) |
| FR-APP-01 | [F-03.1](implementation-backlog.md#f-03), [P3-01.1](implementation-backlog.md#p3-01), [P3-01.2](implementation-backlog.md#p3-01) |
| FR-AUD-01 | [B-02.1](implementation-backlog.md#b-02), [B-03.2](implementation-backlog.md#b-03), [F-03.3](implementation-backlog.md#f-03), [M-08.2](implementation-backlog.md#m-08) |
| FR-BUD-01 | [P3-02.1](implementation-backlog.md#p3-02) |
| FR-CRD-01 | [F-03.2](implementation-backlog.md#f-03), [M-04.2](implementation-backlog.md#m-04) |
| FR-DOC-01 | [F-03.3](implementation-backlog.md#f-03), [M-06.1](implementation-backlog.md#m-06), [P2-04.4](implementation-backlog.md#p2-04) |
| FR-FIN-01 | [M-03.2](implementation-backlog.md#m-03), [M-03.3](implementation-backlog.md#m-03), [M-07.1](implementation-backlog.md#m-07), [M-07.2](implementation-backlog.md#m-07), [P2-02.1](implementation-backlog.md#p2-02), [P2-02.2](implementation-backlog.md#p2-02), [E-02.1](implementation-backlog.md#e-02) |
| FR-FIN-02 | [P3-02.2](implementation-backlog.md#p3-02), [P3-04.1](implementation-backlog.md#p3-04), [P3-04.2](implementation-backlog.md#p3-04), [E-02.2](implementation-backlog.md#e-02) |
| FR-IAM-01 | [B-03.1](implementation-backlog.md#b-03), [F-01.2](implementation-backlog.md#f-01), [F-02.3](implementation-backlog.md#f-02), [F-04.1](implementation-backlog.md#f-04), [F-04.2](implementation-backlog.md#f-04) |
| FR-IAM-02 | [F-01.2](implementation-backlog.md#f-01), [P3-01.2](implementation-backlog.md#p3-01) |
| FR-IMP-01 | [M-08.1](implementation-backlog.md#m-08), [P2-05.2](implementation-backlog.md#p2-05) |
| FR-INT-01 | [R-02.2](implementation-backlog.md#r-02), [B-02.2](implementation-backlog.md#b-02), [P3-05.2](implementation-backlog.md#p3-05), [E-03.2](implementation-backlog.md#e-03) |
| FR-INV-01 | [M-02.1](implementation-backlog.md#m-02), [E-01.1](implementation-backlog.md#e-01) |
| FR-INV-02 | [M-02.2](implementation-backlog.md#m-02), [M-05.1](implementation-backlog.md#m-05) |
| FR-INV-03 | [M-02.2](implementation-backlog.md#m-02), [P2-03.1](implementation-backlog.md#p2-03), [P2-03.3](implementation-backlog.md#p2-03) |
| FR-MDM-01 | [F-02.1](implementation-backlog.md#f-02), [F-02.3](implementation-backlog.md#f-02) |
| FR-MDM-02 | [F-02.2](implementation-backlog.md#f-02) |
| FR-MDM-03 | [F-02.2](implementation-backlog.md#f-02) |
| FR-MDM-04 | [P2-04.1](implementation-backlog.md#p2-04) |
| FR-NOT-01 | [M-08.2](implementation-backlog.md#m-08), [P2-04.4](implementation-backlog.md#p2-04) |
| FR-NUM-01 | [F-03.3](implementation-backlog.md#f-03) |
| FR-ORG-01 | [F-01.1](implementation-backlog.md#f-01) |
| FR-ORG-02 | [F-01.1](implementation-backlog.md#f-01) |
| FR-PRC-01 | [F-03.2](implementation-backlog.md#f-03), [M-04.1](implementation-backlog.md#m-04), [P3-03.1](implementation-backlog.md#p3-03), [P3-03.2](implementation-backlog.md#p3-03) |
| FR-PUR-01 | [M-01.1](implementation-backlog.md#m-01), [M-01.2](implementation-backlog.md#m-01), [P2-01.1](implementation-backlog.md#p2-01), [P2-01.2](implementation-backlog.md#p2-01), [E-05.2](implementation-backlog.md#e-05) |
| FR-PUR-02 | [M-02.1](implementation-backlog.md#m-02), [M-03.2](implementation-backlog.md#m-03), [M-03.3](implementation-backlog.md#m-03), [P2-02.2](implementation-backlog.md#p2-02) |
| FR-RPT-01 | [M-08.3](implementation-backlog.md#m-08), [P2-05.1](implementation-backlog.md#p2-05), [P3-05.1](implementation-backlog.md#p3-05), [E-04.1](implementation-backlog.md#e-04), [E-04.2](implementation-backlog.md#e-04), [E-05.1](implementation-backlog.md#e-05) |
| FR-SAL-01 | [M-04.1](implementation-backlog.md#m-04), [M-04.2](implementation-backlog.md#m-04), [M-04.3](implementation-backlog.md#m-04), [P3-03.1](implementation-backlog.md#p3-03), [E-02.1](implementation-backlog.md#e-02) |
| FR-SAL-02 | [M-06.2](implementation-backlog.md#m-06), [M-07.1](implementation-backlog.md#m-07), [P2-02.1](implementation-backlog.md#p2-02), [E-02.2](implementation-backlog.md#e-02) |
| FR-SAL-03 | [P2-04.1](implementation-backlog.md#p2-04), [P2-04.2](implementation-backlog.md#p2-04) |
| FR-SRH-01 | [M-08.2](implementation-backlog.md#m-08) |
| FR-TAX-01 | [R-02.2](implementation-backlog.md#r-02), [F-03.2](implementation-backlog.md#f-03), [M-07.1](implementation-backlog.md#m-07) |
| FR-TRF-01 | [P2-03.1](implementation-backlog.md#p2-03), [P3-06.1](implementation-backlog.md#p3-06) |
| FR-WMS-01 | [M-05.2](implementation-backlog.md#m-05), [M-06.1](implementation-backlog.md#m-06), [P2-03.2](implementation-backlog.md#p2-03), [E-03.1](implementation-backlog.md#e-03) |
| NFR-ACC-01 | [F-04.1](implementation-backlog.md#f-04), [F-04.2](implementation-backlog.md#f-04), [M-09.1](implementation-backlog.md#m-09), [Z-01.1](implementation-backlog.md#z-01) |
| NFR-AUD-01 | [B-03.2](implementation-backlog.md#b-03), [E-05.2](implementation-backlog.md#e-05), [Z-01.2](implementation-backlog.md#z-01) |
| NFR-AVAIL-01 | [M-10.1](implementation-backlog.md#m-10), [M-10.2](implementation-backlog.md#m-10), [Z-01.2](implementation-backlog.md#z-01), [Z-02.1](implementation-backlog.md#z-02) |
| NFR-DATA-01 | [B-02.1](implementation-backlog.md#b-02), [M-09.2](implementation-backlog.md#m-09), [M-10.2](implementation-backlog.md#m-10), [P2-05.3](implementation-backlog.md#p2-05), [P3-06.2](implementation-backlog.md#p3-06), [E-04.1](implementation-backlog.md#e-04), [E-05.1](implementation-backlog.md#e-05), [Z-01.1](implementation-backlog.md#z-01), [Z-02.1](implementation-backlog.md#z-02) |
| NFR-I18N-01 | [F-04.2](implementation-backlog.md#f-04), [P2-05.2](implementation-backlog.md#p2-05) |
| NFR-INT-01 | [B-01.2](implementation-backlog.md#b-01), [P3-05.1](implementation-backlog.md#p3-05), [E-06.2](implementation-backlog.md#e-06) |
| NFR-MAIN-01 | [R-01.1](implementation-backlog.md#r-01), [R-01.2](implementation-backlog.md#r-01), [B-01.1](implementation-backlog.md#b-01), [B-01.2](implementation-backlog.md#b-01), [E-06.1](implementation-backlog.md#e-06), [Z-02.2](implementation-backlog.md#z-02) |
| NFR-MOB-01 | [P2-04.3](implementation-backlog.md#p2-04), [P2-04.4](implementation-backlog.md#p2-04) |
| NFR-OBS-01 | [B-03.2](implementation-backlog.md#b-03), [M-09.1](implementation-backlog.md#m-09), [M-10.1](implementation-backlog.md#m-10), [Z-01.2](implementation-backlog.md#z-01) |
| NFR-PERF-01 | [B-03.2](implementation-backlog.md#b-03), [M-09.1](implementation-backlog.md#m-09), [Z-01.1](implementation-backlog.md#z-01) |
| NFR-PERF-02 | [M-08.3](implementation-backlog.md#m-08), [E-04.2](implementation-backlog.md#e-04) |
| NFR-REC-01 | [B-02.3](implementation-backlog.md#b-02), [M-09.2](implementation-backlog.md#m-09), [E-06.2](implementation-backlog.md#e-06), [Z-01.2](implementation-backlog.md#z-01) |
| NFR-REL-01 | [B-02.2](implementation-backlog.md#b-02), [M-06.2](implementation-backlog.md#m-06), [M-09.1](implementation-backlog.md#m-09), [E-06.2](implementation-backlog.md#e-06), [Z-01.1](implementation-backlog.md#z-01) |
| NFR-SCALE-01 | [R-02.1](implementation-backlog.md#r-02), [M-09.1](implementation-backlog.md#m-09), [E-06.1](implementation-backlog.md#e-06), [Z-01.1](implementation-backlog.md#z-01) |
| NFR-SEC-01 | [B-03.1](implementation-backlog.md#b-03), [M-09.1](implementation-backlog.md#m-09), [P2-04.4](implementation-backlog.md#p2-04), [Z-01.1](implementation-backlog.md#z-01) |
| NFR-UX-01 | [R-02.1](implementation-backlog.md#r-02), [M-09.1](implementation-backlog.md#m-09), [M-10.2](implementation-backlog.md#m-10), [P2-05.3](implementation-backlog.md#p2-05), [Z-02.2](implementation-backlog.md#z-02) |
| US-01 | [M-04.1](implementation-backlog.md#m-04) |
| US-02 | [M-04.2](implementation-backlog.md#m-04) |
| US-03 | [M-05.2](implementation-backlog.md#m-05), [P2-03.2](implementation-backlog.md#p2-03) |
| US-04 | [M-02.1](implementation-backlog.md#m-02) |
| US-05 | [M-03.2](implementation-backlog.md#m-03) |
| US-06 | [M-03.1](implementation-backlog.md#m-03), [M-07.3](implementation-backlog.md#m-07) |
| US-07 | [F-03.1](implementation-backlog.md#f-03), [M-08.2](implementation-backlog.md#m-08) |
| US-08 | [P2-04.3](implementation-backlog.md#p2-04) |
| US-09 | [M-02.2](implementation-backlog.md#m-02), [P2-03.3](implementation-backlog.md#p2-03) |
| US-10 | [M-08.3](implementation-backlog.md#m-08), [P2-05.1](implementation-backlog.md#p2-05), [E-04.2](implementation-backlog.md#e-04) |

## Fitur besar dan FSD seluruh roadmap

| Sumber scope | Slice yang menutup scope |
|---|---|
| PRD F-01; FSD-FND organisasi/IAM | [F-01](implementation-backlog.md#f-01) |
| PRD F-02; FSD-FND master; FSD-001 SKU/UOM | [F-02](implementation-backlog.md#f-02) |
| PRD F-03; FSD-O2C sales/credit/price | [M-04](implementation-backlog.md#m-04) |
| PRD F-04; FSD-P2P dan FSD-001 PO/GRN | [M-01](implementation-backlog.md#m-01), [M-02](implementation-backlog.md#m-02), [M-03](implementation-backlog.md#m-03) |
| PRD F-05/F-06; FSD-INV-WMS; FSD-O2C reservation/POD | [M-02](implementation-backlog.md#m-02), [M-05](implementation-backlog.md#m-05), [M-06](implementation-backlog.md#m-06), [P2-03](implementation-backlog.md#p2-03) |
| PRD F-07/F-08; FSD-FIN finance/GL/report | [F-03](implementation-backlog.md#f-03), [M-03](implementation-backlog.md#m-03), [M-07](implementation-backlog.md#m-07), [P2-05](implementation-backlog.md#p2-05), [P3-04](implementation-backlog.md#p3-04) |
| PRD F-09; FSD-FND policy; FSD-P3 approval/budget | [F-03](implementation-backlog.md#f-03), [P3-01](implementation-backlog.md#p3-01), [P3-02](implementation-backlog.md#p3-02) |
| PRD F-10; FSD-PLT; IMP-001 import; UX-003 | [F-03](implementation-backlog.md#f-03), [M-08](implementation-backlog.md#m-08), [P2-05](implementation-backlog.md#p2-05), [P3-05](implementation-backlog.md#p3-05) |
| PRD F-11; SYNC-001; FSD-P2 route/visit/push | [P2-04](implementation-backlog.md#p2-04) |
| PRD F-12; FSD-RET; FSD-P2 return dua arah | [P2-02](implementation-backlog.md#p2-02) |
| PRD F-13; FSD-P2 RFQ/blanket | [P2-01](implementation-backlog.md#p2-01) |
| PRD F-14; FSD-P3 budget/expense | [P3-02](implementation-backlog.md#p3-02) |
| FSD-P3 promotion | [P3-03](implementation-backlog.md#p3-03) |
| FSD-P3 scheduler/adapters | [P3-05](implementation-backlog.md#p3-05) |
| FSD-P3 intercompany | [P3-06](implementation-backlog.md#p3-06) |
| PRD54; FSD-EXP1 assembly | [E-01](implementation-backlog.md#e-01) |
| PRD54; FSD-EXP2 POS | [E-02](implementation-backlog.md#e-02) |
| PRD54; FSD-EXP3 TMS | [E-03](implementation-backlog.md#e-03) |
| PRD54; FSD-EXP4 reporting/forecast | [E-04](implementation-backlog.md#e-04), [E-05](implementation-backlog.md#e-05) |
| PRD54; FSD-EXP5 split bersyarat | [E-06](implementation-backlog.md#e-06) |
| PRD38–52/55–57; deployment, SLO, data migration, rollout | [B-01](implementation-backlog.md#b-01), [B-02](implementation-backlog.md#b-02), [B-03](implementation-backlog.md#b-03), [M-09](implementation-backlog.md#m-09), [M-10](implementation-backlog.md#m-10), [Z-01](implementation-backlog.md#z-01), [Z-02](implementation-backlog.md#z-02) |

## Aturan perubahan scope

Requirement baru harus memperoleh ID PRD atau referensi section FSD yang stabil, lalu slice dengan owner, acceptance, dependency dan kelima sumber teknis sebelum READY. Jangan menghapus baris SHOULD karena bukan MUST. Gap detail tidak berarti requirement dibuang. Setelah implementasi, tambahkan lokasi tes dan laporan run pada acceptance slice; checklist WO baru dicentang bila semua slice dan gate paketnya terbukti.


## Objective dan KPI bisnis PRD §5–6

| Objective / KPI | Slice instrumentasi dan bukti | Owner / syarat ukur |
|---|---|---|
| OBJ-01; source-to-ledger ≥99,5%; auto-journal coverage100% | M-03.1, M-07.3, M-09.1, M-10.2 | Controller; numerator/denominator source eligible dan reconciliation aktual |
| OBJ-02; stock accuracy ≥99,5% | M-02.2, P2-03.3, P2-05.1 | Inventory Controller; count fisik dibanding buku, scope SKU-lokasi dan periode jelas |
| OBJ-03; SO approval −30%, receipt→invoice −25%; conversion +10%, OTIF≥95% | M-01.2, M-05.2, M-08.3, M-10.2, P2-05.1 | Sales/Operations; baseline 4–8 minggu dicatat R-02, event timestamps authoritative, jangan klaim improvement tanpa baseline |
| OBJ-04; balanced journal100%, double posting0; AR overdue −15% | M-03.1, M-07.2–M-07.3, M-10.2 | Controller/Finance; posted-only metrics, aging as-of dan cohort konsisten |
| OBJ-05; scope leak0 | B-03.1, F-01.2, M-09.1, Z-01.1 | Security; authz matrix termasuk direct URL dan semua owner |
| OBJ-06; valid offline accepted dalam15min≥95%; sync success keseluruhan≥99,5% | P2-04.3–P2-04.4, P2-05.3 | Mobile Lead; dua ukuran berbeda (latency-window dan eventual success), perangkat/jaringan pilot dicatat |
| Approval SLA≥90% | F-03.1, M-08.3, P3-01.2 | Process Owner; due time policy dan event decision, escalation P3 |
| API availability≥99,9% bulanan | B-03.2, M-10.2, Z-01.2 | SRE; eligible request/success sesuai SLI, tidak disimpulkan dari smoke test |
