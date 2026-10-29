# QA-RM — Vektor uji seluruh roadmap setelah MVP

**Fixture:** tenant T, entity E-A/E-B, branch B1/B2, warehouse W1/W2, IDR base, policy P1; GUID sintetis menurut [DATA-003](../features/mvp-data-dictionary.md). Nilai nominal string decimal. Semua vektor diuji pada domain unit, PostgreSQL integration (row lock/unique), API auth/idempotency/ETag, event replay, dan UI/E2E sesuai risiko. Ini expected behavior sebelum kode, bukan klaim runtime lulus.

| ID / tahap | Given → When | Expected authoritative result dan invariant |
|---|---|---|
| P2-01 RFQ | PR line 24 pcs, quote 2 carton pada conversion 12 pcs, quote lain 24 pcs; compare | Keduanya 24 base pcs; FX/UOM snapshot dan score explanation tersimpan; missing conversion 422 |
| P2-02 RFQ race | PR approved 10, dua award concurrent 7 dan 6 | Satu ditolak/di-requote; cumulative award≤10, satu PO per award operation |
| P2-03 bid | RFQ OPEN deadline besok, buyer mengubah weight | 409 revision required; bid lama tetap history; vendor B tidak melihat quote A |
| P2-04 blanket | Cap100, release60+40, dua release tambahan1 serentak | Keduanya 422 `CONTRACT_CAP_EXCEEDED`; counter≤100; retry existing release returns same PO |
| P2-05 sales return | Delivered/invoiced10 @200 tax11% cost110; accepted return3 | Memo gross666, net600,tax66; inventory330 jika sellable, COGS inverse330; original immutable |
| P2-06 purchase return | GRN/invoice10 @100 tax11%, accepted return3 | Supplier debit memo net300,tax33; cumulative return≤10; AP/tax/stock inverse once |
| P2-07 return race | Invoice issue dan pre-invoice return3 on accepted10 | Finance row lock chooses order; if return first invoice≤7; if issue first memo path; no double credit |
| P2-08 transfer | Ship10 W1→W2; receive7 sellable+2 hold, discrepancy1 | W1 sellable−10, W2 +9, transit1 until claim; total valued qty10 and no revenue |
| P2-09 transfer race | Two receive commands each qty7 against ship10 | One succeeds, second≤3 or 422; replay same operation one movement |
| P2-10 bin | Relocate5 of lot L bin A→B with capacity B=4 | 422, no movement/balance change; retry after capacity change creates paired legs only |
| P2-11 wave | Reservation5, two wave release attempts for same pick | One active wave assignment; reserved/allocated remain5, not10 |
| P2-12 count | Expected10, first count8, threshold1, no second count | Review/post blocked; second count9 then approved adjustment−1 with watermark and journal link |
| P2-13 offline | Draft order saved offline, app restarts, network drops after server commit | Local draft survives; retry same client command yields one SO/server GUID; stale price→NEEDS_REVIEW |
| P2-14 revoke | Device/scope revoked before push/pull/push notification click | 403/reset; restricted cache locked/purged; no cross-entity data opened |
| P2-15 reports | Transfer projection misses one event | `as_of`/watermark lag visible, report marked STALE; replay restores checksum; export not silently final |
| P3-01 approval | Quorum 2-of-3, decisions A/B concurrent, maker is C | A+B advances once; maker C denied 403; old revision callback ignored |
| P3-02 delegation | Delegator is maker, delegates to D | D approval denied SoD; expiry/revoke also denies; decision audit records both identities |
| P3-03 budget | Authorized100, PO commit40, actual20, cancel remaining20 | Available60 after actual, 80 after cancel; concurrent reserve cannot overspend |
| P3-04 expense | Same receipt hash/number submitted twice, period closed | Second exception; no duplicate payable/journal; next open-period correction linked |
| P3-05 promotion | Gross100, percent10 and fixed5 same exclusion group | One winner by priority/GUID; net90 or95 per policy, never85; explanation records rejected rule |
| P3-06 promotion race | Global cap100, two SO each consume70 | At most one completes; second quote/submit 422 cap; no negative remaining |
| P3-07 bank | Statement opening100, lines +50−20, closing130 | Close equation holds; duplicate source row rejected, suggestion does not post GL |
| P3-08 bank race | Two lines attempt to match same payment60 | One match; other exception/409, no duplicate settlement |
| P3-09 FX | USD100 carrying IDR1,500,000, close rate15,200 | Delta +20,000 journal balanced once; next open period inverse−20,000; source unchanged |
| P3-10 schedule | Same scheduled instant claimed by two workers | One report job/run; scope revoked before run→FAILED/NO_ACCESS, no export data |
| P3-11 adapter | Valid external event delivered twice then invalid signature | One mapped command for valid event; invalid 401/DLQ and no domain write |
| P3-12 intercompany | 5 units source cost100, price120; ship then destination timeout | Source pending with transit/due-from evidence; no false CLOSED; replay makes one destination receipt/due-to; reconciliation before close |
| EXP-01 assembly | BOM A=2B@10+1C@5, WO3A, issue all, complete2A | WIP75 after issue, finished inventory50, WIP25 remains; no extra component consumption |
| EXP-02 assembly race | Same serial component in two WO issue commands | One accepted; other 409, no negative stock or duplicate WIP journal |
| EXP-03 POS | Sale2×100 tax11%, provider timeout after capture | Query provider status; one sale/capture222, stock−2, revenue200/tax22, receipt once |
| EXP-04 POS refund | Completed sale222, refund100 then refund123 concurrent | Cumulative refund≤222; excess denied, inverse inventory/tax only for eligible returned line |
| EXP-05 TMS | Carrier milestone DELIVERED arrives before PICKUP, POD still missing | Park/order milestone; Finance invoice not issued until WMS POD accepted |
| EXP-06 analytics | Reporting store misses event N while N+1 arrives | Gap detected, metric STALE, export withheld; replay yields same owner hash/watermark |
| EXP-07 forecast | Model suggests PO20 while user lacks purchase permission | Suggestion read only; no PO/commitment created; approval+normal Purchase command required |
| EXP-08 split | Finance→Accounting split during invoice issue, journal owner timeout | Invoice `POSTING_PENDING/EXCEPTION`, not ISSUED; payment/close blocked; reconciler replay one journal |

## Gate per tahap

Phase 2: multi branch UAT, offline sync ≥ target PRD, transfer/return/stock/GL reconciliation zero unexplained delta, bin scan device tests, scoped push, report watermark. Phase 3: Controller/Tax/Process Owner sign-off untuk policy, bank/FX/intercompany control, no unresolved ledger mismatch, provider contract+failure tests. Expansion: business case/sizing, WIP/POS provider/TMS proof, analytics source reconciliation and model governance, optional split dual-run/rollback. Security ASVS/MASVS, accessibility WCAG 2.2 AA, SLO/performance, backup/restore, operational runbooks, and license/credential evidence diuji pada environment nyata. Test statis dokumen/kontrak tidak menggantikan gate tersebut.
