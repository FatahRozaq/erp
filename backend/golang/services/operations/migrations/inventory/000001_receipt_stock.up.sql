CREATE SCHEMA IF NOT EXISTS inventory;

-- Owner of approved PO quantity available for receipts. Purchase's received_qty is a projection.
CREATE TABLE inventory.receipt_limits (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  purchase_order_guid uuid NOT NULL,
  purchase_order_line_guid uuid NOT NULL,
  sku_guid uuid NOT NULL,
  base_uom_guid uuid NOT NULL,
  approved_qty_base numeric(20,6) NOT NULL CHECK (approved_qty_base > 0),
  received_qty_base numeric(20,6) NOT NULL DEFAULT 0
    CHECK (received_qty_base >= 0 AND received_qty_base <= approved_qty_base),
  unit_cost_base numeric(20,6) NOT NULL CHECK (unit_cost_base >= 0),
  source_event_guid uuid NOT NULL,
  source_aggregate_version bigint NOT NULL CHECK (source_aggregate_version > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT receipt_limits_scope_id_uq UNIQUE (tenant_guid,legal_entity_guid,id),
  CONSTRAINT receipt_limits_po_line_uq UNIQUE (tenant_guid,legal_entity_guid,purchase_order_line_guid),
  CONSTRAINT receipt_limits_source_event_line_uq UNIQUE (source_event_guid,purchase_order_line_guid),
  CONSTRAINT receipt_limits_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);

CREATE TABLE inventory.goods_receipts (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  purchase_order_guid uuid NOT NULL,
  warehouse_guid uuid NOT NULL,
  business_operation_guid uuid NOT NULL,
  status text NOT NULL CHECK (status IN ('DRAFT','POSTED','VOIDED')),
  business_date date,
  posted_at timestamptz,
  posted_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT goods_receipts_scope_id_uq UNIQUE (tenant_guid,legal_entity_guid,id),
  CONSTRAINT goods_receipts_operation_uq UNIQUE (tenant_guid,business_operation_guid),
  CONSTRAINT goods_receipts_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL)),
  CONSTRAINT goods_receipts_posted_pair_chk CHECK ((posted_at IS NULL) = (posted_by IS NULL)),
  CONSTRAINT goods_receipts_posted_state_chk CHECK (status <> 'POSTED' OR posted_at IS NOT NULL)
);
CREATE INDEX goods_receipts_list_idx ON inventory.goods_receipts
  (tenant_guid,legal_entity_guid,status,business_date DESC,id DESC) WHERE deleted_at IS NULL;

CREATE TABLE inventory.goods_receipt_lines (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  goods_receipt_id bigint NOT NULL,
  receipt_limit_id bigint NOT NULL,
  line_no integer NOT NULL CHECK (line_no > 0),
  accepted_qty_base numeric(20,6) NOT NULL CHECK (accepted_qty_base > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT goods_receipt_lines_header_fk FOREIGN KEY (tenant_guid,legal_entity_guid,goods_receipt_id)
    REFERENCES inventory.goods_receipts (tenant_guid,legal_entity_guid,id),
  CONSTRAINT goods_receipt_lines_limit_fk FOREIGN KEY (tenant_guid,legal_entity_guid,receipt_limit_id)
    REFERENCES inventory.receipt_limits (tenant_guid,legal_entity_guid,id),
  CONSTRAINT goods_receipt_lines_line_uq UNIQUE (goods_receipt_id,line_no),
  CONSTRAINT goods_receipt_lines_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);

-- One moving-average pool across warehouses for an entity/SKU/ownership.
CREATE TABLE inventory.cost_pools (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  sku_guid uuid NOT NULL,
  ownership text NOT NULL DEFAULT 'OWNED' CHECK (ownership = 'OWNED'),
  qty_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (qty_base >= 0),
  value_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (value_base >= 0),
  average_unit_cost_base numeric(24,10) NOT NULL DEFAULT 0 CHECK (average_unit_cost_base >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT cost_pools_key_uq UNIQUE (tenant_guid,legal_entity_guid,sku_guid,ownership),
  CONSTRAINT cost_pools_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL)),
  CONSTRAINT cost_pools_zero_chk CHECK (qty_base <> 0 OR value_base = 0)
);

CREATE TABLE inventory.stock_balances (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  warehouse_guid uuid NOT NULL,
  sku_guid uuid NOT NULL,
  ownership text NOT NULL DEFAULT 'OWNED' CHECK (ownership = 'OWNED'),
  inventory_status text NOT NULL DEFAULT 'SELLABLE' CHECK (inventory_status IN ('SELLABLE','HOLD','DAMAGED','IN_TRANSIT')),
  qty_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (qty_base >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT stock_balances_key_uq UNIQUE (tenant_guid,legal_entity_guid,warehouse_guid,sku_guid,ownership,inventory_status),
  CONSTRAINT stock_balances_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);
CREATE INDEX stock_balances_lookup_idx ON inventory.stock_balances (tenant_guid,legal_entity_guid,warehouse_guid,sku_guid);

-- Posted ledger is append-only: correction uses a new movement, never UPDATE/DELETE.
CREATE TABLE inventory.stock_movements (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  warehouse_guid uuid NOT NULL,
  sku_guid uuid NOT NULL,
  ownership text NOT NULL CHECK (ownership = 'OWNED'),
  inventory_status text NOT NULL CHECK (inventory_status IN ('SELLABLE','HOLD','DAMAGED','IN_TRANSIT')),
  source_type text NOT NULL,
  source_guid uuid NOT NULL,
  source_line_guid uuid NOT NULL,
  business_operation_guid uuid NOT NULL,
  movement_leg text NOT NULL,
  qty_delta_base numeric(20,6) NOT NULL CHECK (qty_delta_base <> 0),
  value_delta_base numeric(20,6) NOT NULL,
  unit_cost_snapshot_base numeric(24,10) NOT NULL CHECK (unit_cost_snapshot_base >= 0),
  occurred_at timestamptz NOT NULL,
  recorded_at timestamptz NOT NULL DEFAULT statement_timestamp(),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  CONSTRAINT stock_movements_source_leg_uq UNIQUE
    (tenant_guid,source_type,source_guid,source_line_guid,movement_leg),
  CONSTRAINT stock_movements_qty_value_sign_chk CHECK
    ((qty_delta_base > 0 AND value_delta_base >= 0) OR
     (qty_delta_base < 0 AND value_delta_base <= 0))
);
CREATE INDEX stock_movements_ledger_idx ON inventory.stock_movements
  (tenant_guid,legal_entity_guid,warehouse_guid,sku_guid,occurred_at DESC,id DESC);
