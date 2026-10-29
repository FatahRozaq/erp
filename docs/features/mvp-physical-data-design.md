# DATA-002 — Desain fisik Foundation+MVP sebelum migration berikutnya

**Status:** rancangan tabel/constraint; 11 migration awal yang sudah ada tetap sumber SQL aktual untuk subsetnya. Dokumen ini menentukan sisa tabel agar migration dapat ditulis tanpa memilih ownership, key atau presisi sendiri. Semua tabel mengikuti [standar PostgreSQL](../engineering/database-standards.md), [model logis](mvp-data-model.md) dan [ADR arsitektur](../architecture/architecture-decisions.md). Detail pajak/COA disimpan sebagai policy version dan diaktifkan per entity; tidak di-hardcode di schema.

## Konvensi bersama dan migration order

`M` = mutable row: `id bigint identity PK`, `guid uuidv7 UNIQUE NOT NULL`, `tenant_guid` bila tenant-scoped, `legal_entity_guid` bila entity-scoped, `created_at/by`, `updated_at/by`, `deleted_at/by`, `version bigint>0`. `A` = append-only row: `id/guid`, scope, `created_at/by`, source/operation/correlation, tanpa update/delete runtime. Line mutable memakai FK composite `(tenant_guid,legal_entity_guid,parent_id)` ke parent; referensi lintas owner adalah GUID tanpa SQL FK. Decimal qty/amount `numeric(20,6)`, unit average/FX `numeric(24,10)`; currency ISO code dan amount currency original/base terpisah. Instant `timestamptz`, business date `date`; semua UUID disimpan `uuid`. PII terenkripsi di kolom/objek dengan key reference, bukan ciphertext pada event.

**Urutan:** Platform org/IAM→master/policy/numbering→Commercial SO/credit/PR/PO→Operations reservation/WMS/ledger→Finance invoice/open item/payment/posting/GL→Platform import/doc/report projection. Deploy migration expand sebelum handler; backfill dan constraint validation pada data sintetis/real rehearsal; contract setelah binary lama lepas. Data source yang sudah posted tidak diubah oleh migration bisnis. Down migration hanya untuk schema baru kosong; data correction memakai forward fix. Tiap langkah punya lock budget, backup/PITR marker dan restore proof.

## Platform: organization, IAM, master, policy, platform jobs

| Tabel / kelas | Kolom domain (selain standar) dan FK lokal | Constraint/indeks wajib |
|---|---|---|
| `organization.tenants` M | `code,name,status,timezone_default` | active code unik global; status enum |
| `organization.companies` M | `tenant_id,code,name,status`; FK tenant | `(tenant_guid,code)` aktif unik |
| `organization.legal_entities` M | `company_id,code,currency,timezone,tax_registration_ref,status`; FK company scope | code tenant unik; company tenant sama; currency/timezone wajib |
| `organization.branches` M | `legal_entity_id,code,name,status`; FK entity | `(tenant,entity,code)` aktif unik |
| `organization.warehouses` M | `legal_entity_id,code,name,status,default_location_guid`; FK entity | entity tidak boleh berubah setelah movement; code scope unik |
| `organization.branch_warehouse_assignments` M | `branch_id,warehouse_id,effective_from/to`; FK keduanya same entity | no interval overlap per pair; `from<to` bila end ada |
| `iam.users` M | `issuer,subject,display_name,status,session_version` | `(issuer,subject)` unik; session_version monotonic |
| `iam.memberships` M | `user_id,tenant_id,status,effective_from/to`; local FK | user+tenant active interval tidak overlap |
| `iam.roles` M | `code,name,status,permission_version` | code tenant unik; built-in role immutable setelah publish |
| `iam.role_permissions` M | `role_id,permission_code`; FK role | role+permission unik |
| `iam.scope_grants` M | `user_id,role_id,entity_guid,branch_guid?,warehouse_guid?,effective_from/to,grantor_guid,reason` | grant subset diperiksa domain; active interval/pair unik; parent scope cocok |
| `iam.sessions` M | `user_id,device_guid?,refresh_family_hash,session_version,expires_at,revoked_at` | no raw token; family hash unik; expired/revoked tidak aktif |
| `master.parties` M | `party_type,code,name,status,merged_into_guid?` | tenant+type+code unik permanen; customer/vendor adalah jenis party |
| `master.party_accounts` M | `party_id,legal_entity_guid,payment_term_days,currency,tax_profile_guid?,credit_policy_guid?,bank_token_guid?,status` | party+entity unik permanen; perubahan sensitif lewat proposal/checker |
| `master.sensitive_change_requests` M | `account_id,field,ciphertext_ref,masked_value,maker_guid,checker_guid?,status,reason` | satu PENDING per account+field; maker≠checker |
| `master.party_addresses` M | `party_id,address_type,country,region,city,postal,encrypted_detail,effective_from/to` | interval per party+type tidak overlap |
| `master.master_aliases` A | `source_type,source_system,external_id,target_guid` | `(tenant,source_system,source_type,external_id)` unik permanen |
| `policy.policy_versions` M | `policy_type,content_json,content_hash,status,test_result_hash` | published content immutable; code+version unik |
| `policy.activations` A | `policy_version_id,entity_guid,effective_from/to,approved_by_1/2` | active range nonoverlap per type/entity; two distinct approvers |
| `policy.approval_instances/steps/decisions` M/A | `source_guid,revision,policy_version_guid,maker_guid,step_no,approver_guid,decision,reason` | one decision per step/version; maker≠approver; source revision unique |
| `policy.tax_rules/price_rules` M | `rule_version_guid,entity_guid,customer_class,sku_class,transaction_type,effective_from/to,rate/factor/rounding` | no ambiguous overlapping precedence; published immutable |
| `platform.number_sequences` M | `entity_guid,document_type,fiscal_year,next_value` | key unique; row lock on allocation; number never reused |
| `platform.import_jobs/row_results` M/A | `template_version,object_guid,file_hash,status,row_no,error_code,target_guid` | job+row unique; external row operation unique |
| `platform.attachments` M | `owner_type/guid,object_key,sha256,mime,size,scan_status,retention_class,version_no` | owner+version unique; object key private unique |
| `platform.notifications` M | `event_id,recipient_guid,channel,status,attempt_count` | `(recipient,event_id,channel)` unique |
| `platform.report_jobs` M | `report_type,parameters_hash,scope_hash,watermark,status,output_object_key?,expires_at?` | private object dan scoped download |

Org/role/policy activation overlap dijaga transaksi SERIALIZABLE + lock scope key; interval exclusion constraint boleh dipakai hanya jika extension tersedia dan migration diuji. Akses database app dipisah per schema, tetapi Platform code tetap memeriksa scope semantik. Event hanya memuat GUID dan versi snapshot yang diperlukan, tidak row PII.

## Commercial: sales, credit, purchase

| Tabel / kelas | Kolom domain dan FK lokal | Constraint/indeks wajib |
|---|---|---|
| `sales.sales_orders/lines` M | customer_account_guid, branch_guid, currency, business_date, status, revision, totals; line sku_guid, warehouse_guid, qty_base, price/tax/discount snapshots | `(tenant,entity,document_no)` permanen; line_no unik; qty>0; approved revision immutable |
| `sales.price_tax_snapshots` A | `sales_order_line_id,rule_guid/version,base_price,discount,net,tax,gross,uom_ratio` | line+revision unique; sums exact after rounding |
| `sales.order_revisions` A | `sales_order_id,revision,snapshot_hash,release_operation_guid?,approval_instance_guid?` | revision unik; history immutable |
| `credit.accounts` M | customer_account_guid,entity_guid,limit_base,currency,status | account+entity unique; lock row before exposure check |
| `credit.exposure_buckets` M | `account_id,source_portion_guid,bucket_type,amount_base,fx_snapshot_guid,status` | one active bucket per source portion; amount≥0; transfer atomic |
| `credit.deposits/overrides` M | `account_id,posted_amount,unallocated; SO_guid,limit,expires,approvers,consumed_at` | deposit eligible≤unallocated; override once+expiry |
| `credit.reversal_holds` M | `account_id,original_payment_guid,reversal_operation_guid,status,reason` | satu active hold per reversal; credit submit/dispatch fail closed sampai Finance reversal event applied |
| `purchase.requisitions/lines` M | requester,branch,need_by,status; line sku/qty/warehouse | document number unique; line qty>0; conversion source unique |
| `purchase.purchase_orders/lines` M | migration awal tersedia | `approved_qty≥received_projection`; approved snapshot, source operation unique |

`SubmitSO` dan credit bucket berada dalam Commercial deployable tetapi modul schema/role terpisah; transaksi lokal gabungan hanya untuk exposure+SO mutation yang memerlukan atomisitas. Approval tetap owner Platform dan disinkron melalui saga. Credit status tidak diturunkan dari read replica.

## Operations: inventory, warehouse

| Tabel / kelas | Kolom domain dan FK lokal | Constraint/indeks wajib |
|---|---|---|
| `inventory.receipt_limits`, `goods_receipts/lines`, `cost_pools`, `stock_balances`, `stock_movements` | migration awal tersedia | cumulative receipt≤approved; movement source+leg unik; balance nonnegative |
| `inventory.lots/serials` M | sku_guid,warehouse_guid,lot_no,expiry,status; serial_no,lot_id,status | lot+SKU/warehouse unique; serial+SKU tenant unique; expiry check |
| `inventory.reservations/lines` M | SO_guid,warehouse_guid,status,expires_at; line sku/lot/qty_requested/held/consumed | op GUID unique; held+consumed≤requested; source line+leg unique |
| `inventory.stock_adjustments/lines` M/A | reason,evidence_guid,checker,status; line sku/lot/book/count/delta/cost snapshot | posted adjustment immutable; source+leg unique; negative guard |
| `warehouse.pick_tasks/lines/scans` M/A | reservation_guid,assignee,lease,status; line sku/lot/allocated/picked; scan serial/device/time | one active claim; picked≤allocated; serial scan unique per source |
| `warehouse.packs/lines` M | pick_task_id,seal_ref,status; line sku/lot/qty | packed≤picked; pack line unique |
| `warehouse.deliveries/lines` M | SO_guid,branch/warehouse,recipient/status; line shipped/accepted/rejected/in_transit,cost_snapshot | accepted+rejected+in_transit=shipped; source line+portion unique |
| `warehouse.pod_evidence/portions` M/A | delivery_line_id,recipient,object_guid,sha256,scan_status; portion qty/time/actor | proof required before accept; source portion GUID unique; qty cumulative guard |

POD evidence object berada di Platform storage tetapi Operations menguasai acceptance/proof metadata. Operations tidak memakai URL upload sebagai bukti; checksum/scan `CLEAN` dan object ownership diverifikasi. `return_inspections` Phase 2 migration awal bukan bagian MVP gate.

## Finance: AR/AP, payment, accounting

| Tabel / kelas | Kolom domain dan FK lokal | Constraint/indeks wajib |
|---|---|---|
| `finance.invoices/lines` M/A | sales/vendor type,party_account_guid,document_no,business_date,due_date,currency,net/tax/gross,status; line source_portion_guid,qty,price,tax/cost snapshots | issued source portion unique; gross=sum lines; issued only if journal posted local transaction |
| `finance.billing_correction_claims` M | `billing_source_portion_id,correction_guid,expected_source_version,status,applied_event_id?` | satu HELD per source; claim dan issue lock billing source row sama; no unsafe timeout release |
| `finance.open_items` M | source_type,source_guid,invoice_id?,original_gross,allocated,credited,outstanding,due_date | invoice FK hanya untuk invoice source; opening AR/AP memakai source import, bukan fake invoice; `outstanding=original−allocated−credited≥0`; lock on allocation |
| `finance.payments/allocations` M/A | party_account_guid,bank_ref,amount,currency,fx_snapshot,status; allocation payment_id/open_item_id/amount | bank ref per account/entity unique; allocated≤open; sum allocation+unapplied+fee=payment |
| `finance.posting_intents` M | migration awal tersedia; source_guid,action,payload_hash,status | source+action unique; status/journal link consistent |
| `finance.tax_documents` M | invoice_guid,rule_version,external_ref,status,submitted_at,accepted_at | external ref unique; history/response immutable version |
| `accounting.accounts/fiscal_periods/journals/journal_lines` | migration awal tersedia | period nonoverlap; posted journal balanced and immutable |
| `accounting.posting_rules` M | entity_guid,source_type,leg,account_guid,dimension_rule,effective_from/to,status | no active overlap/ambiguous precedence; account active |
| `accounting.gl_balances` M | entity_guid,period_id,account_id,dimensions,debit/credit,watermark | key unique; projection equals posted lines |
| `accounting.close_attestations` A | entity_guid,period_id,owner,source_watermark,count/hash,signed_by,recorded_at | one valid/latest per owner+period; stale/missing blocks close |

Journal line imbalance tidak cukup dicegah CHECK row; posting procedure/transaction mengunci journal, menghitung debit/kredit dan baru mengubah state `POSTED`; integration tests wajib membuktikannya. Cross-owner source GUID tidak diberi SQL FK; background reconciliation menangkap orphan/lag.

## Reconciliation queries yang wajib ada

| ID | Harian/per close | Ketentuan |
|---|---|---|
| R-01 | stock balance vs sum movement per scope key | delta=0, termasuk HOLD/IN_TRANSIT |
| R-02 | cost pool vs movement value dan Inventory GL | delta≤rounding policy residual yang dijelaskan, bukan auto-fix |
| R-03 | PO approved vs receipt limit/GRN accepted | total≤approved; missing event/lag diberi umur |
| R-04 | delivery shipped vs accepted+rejected+in_transit | delta=0; POD pending Finance terdaftar |
| R-05 | source accepted vs invoice portion+accepted unbilled | delta=0; billed sekali |
| R-06 | invoice gross vs open item+allocated+credited | delta=0 per source/party/entity |
| R-07 | AR/AP open item vs GL control account | delta=0 per entity/period setelah suspense/timing dipisah |
| R-08 | posting intent vs journal, journal debit vs credit | orphan/imbalance=0 sebelum close |

Tipe/nullability/kunci dan urutan migration/seed yang melengkapi katalog ini ada di [DATA-003](mvp-data-dictionary.md). Migration berikutnya menyalin tabel/constraint relevan ke owner directory, menambah EXPLAIN pada fixture representatif, concurrent writer test dan rollback/forward-fix note. Tidak membuat seluruh tabel sekaligus tanpa use case/handler yang memakainya; keputusan gating per capability dicatat di [planning gate](../planning-gate.md).
