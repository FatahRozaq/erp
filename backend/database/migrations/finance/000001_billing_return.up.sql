CREATE TABLE finance.billing_source_portions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  delivery_line_guid uuid NOT NULL,
  source_portion_guid uuid NOT NULL,
  invoice_line_guid uuid,
  delivered_accepted_qty_base numeric(20,6) NOT NULL CHECK (delivered_accepted_qty_base > 0),
  pre_invoice_return_qty_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (pre_invoice_return_qty_base >= 0),
  gross_invoiced_qty_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (gross_invoiced_qty_base >= 0),
  credited_post_invoice_qty_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (credited_post_invoice_qty_base >= 0),
  unit_net_price_base numeric(20,6) NOT NULL CHECK (unit_net_price_base >= 0),
  outbound_unit_cost_base numeric(24,10) NOT NULL CHECK (outbound_unit_cost_base >= 0),
  tax_rule_version_guid uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT billing_source_portions_scope_id_uq UNIQUE (tenant_guid,legal_entity_guid,id),
  CONSTRAINT billing_source_portions_source_uq UNIQUE (tenant_guid,legal_entity_guid,source_portion_guid),
  CONSTRAINT billing_source_portions_qty_chk CHECK
    (pre_invoice_return_qty_base + gross_invoiced_qty_base <= delivered_accepted_qty_base
      AND credited_post_invoice_qty_base <= gross_invoiced_qty_base),
  CONSTRAINT billing_source_portions_invoice_pair_chk CHECK
    ((gross_invoiced_qty_base = 0 AND invoice_line_guid IS NULL) OR
      (gross_invoiced_qty_base > 0 AND invoice_line_guid IS NOT NULL)),
  CONSTRAINT billing_source_portions_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);

CREATE TABLE finance.credit_memos (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  sales_return_guid uuid NOT NULL,
  business_operation_guid uuid NOT NULL,
  document_no text,
  business_date date NOT NULL,
  status text NOT NULL CHECK (status IN ('DRAFT','ISSUED','VOIDED')),
  issued_at timestamptz,
  issued_by uuid,
  net_base numeric(20,6) NOT NULL CHECK (net_base >= 0),
  tax_base numeric(20,6) NOT NULL CHECK (tax_base >= 0),
  gross_base numeric(20,6) NOT NULL CHECK (gross_base = net_base + tax_base),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT credit_memos_scope_id_uq UNIQUE (tenant_guid,legal_entity_guid,id),
  CONSTRAINT credit_memos_return_uq UNIQUE (tenant_guid,legal_entity_guid,sales_return_guid),
  CONSTRAINT credit_memos_operation_uq UNIQUE (tenant_guid,business_operation_guid),
  CONSTRAINT credit_memos_number_uq UNIQUE (tenant_guid,legal_entity_guid,document_no),
  CONSTRAINT credit_memos_issued_pair_chk CHECK ((issued_at IS NULL) = (issued_by IS NULL)),
  CONSTRAINT credit_memos_issued_state_chk CHECK
    (status <> 'ISSUED' OR (document_no IS NOT NULL AND issued_at IS NOT NULL)),
  CONSTRAINT credit_memos_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);

CREATE TABLE finance.credit_memo_lines (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  credit_memo_id bigint NOT NULL,
  source_portion_id bigint NOT NULL,
  credited_qty_base numeric(20,6) NOT NULL CHECK (credited_qty_base > 0),
  net_base numeric(20,6) NOT NULL CHECK (net_base >= 0),
  tax_base numeric(20,6) NOT NULL CHECK (tax_base >= 0),
  inventory_value_base numeric(20,6) NOT NULL CHECK (inventory_value_base >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  CONSTRAINT credit_memo_lines_header_fk FOREIGN KEY (tenant_guid,legal_entity_guid,credit_memo_id)
    REFERENCES finance.credit_memos (tenant_guid,legal_entity_guid,id),
  CONSTRAINT credit_memo_lines_portion_fk FOREIGN KEY (tenant_guid,legal_entity_guid,source_portion_id)
    REFERENCES finance.billing_source_portions (tenant_guid,legal_entity_guid,id),
  CONSTRAINT credit_memo_lines_source_uq UNIQUE (credit_memo_id,source_portion_id)
);
