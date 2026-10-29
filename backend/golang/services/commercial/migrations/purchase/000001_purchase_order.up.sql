CREATE SCHEMA IF NOT EXISTS purchase;

CREATE TABLE purchase.purchase_orders (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  branch_guid uuid NOT NULL,
  vendor_account_guid uuid NOT NULL,
  document_no text,
  currency_code text NOT NULL CHECK (currency_code = 'IDR'),
  status text NOT NULL CHECK (status IN ('DRAFT','WAITING_APPROVAL','APPROVED','PARTIALLY_RECEIVED','RECEIVED','CLOSED','REJECTED','CANCELLED')),
  policy_version_guid uuid,
  business_date date,
  approved_at timestamptz,
  approved_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT purchase_orders_scope_id_uq UNIQUE (tenant_guid,legal_entity_guid,id),
  CONSTRAINT purchase_orders_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL)),
  CONSTRAINT purchase_orders_approval_pair_chk CHECK ((approved_at IS NULL) = (approved_by IS NULL))
);
CREATE UNIQUE INDEX purchase_orders_number_uq ON purchase.purchase_orders (tenant_guid,legal_entity_guid,document_no) WHERE document_no IS NOT NULL;
CREATE INDEX purchase_orders_list_idx ON purchase.purchase_orders (tenant_guid,legal_entity_guid,status,business_date DESC,id DESC) WHERE deleted_at IS NULL;

CREATE TABLE purchase.purchase_order_lines (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  purchase_order_id bigint NOT NULL,
  line_no integer NOT NULL CHECK (line_no > 0),
  sku_guid uuid NOT NULL,
  base_uom_guid uuid NOT NULL,
  approved_qty_base numeric(20,6) NOT NULL CHECK (approved_qty_base > 0),
  received_qty_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (received_qty_base >= 0 AND received_qty_base <= approved_qty_base),
  unit_price_base numeric(20,6) NOT NULL CHECK (unit_price_base >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT purchase_order_lines_po_fk FOREIGN KEY (tenant_guid,legal_entity_guid,purchase_order_id)
    REFERENCES purchase.purchase_orders (tenant_guid,legal_entity_guid,id),
  CONSTRAINT purchase_order_lines_line_uq UNIQUE (purchase_order_id,line_no),
  CONSTRAINT purchase_order_lines_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);
CREATE INDEX purchase_order_lines_po_idx ON purchase.purchase_order_lines (tenant_guid,legal_entity_guid,purchase_order_id);
