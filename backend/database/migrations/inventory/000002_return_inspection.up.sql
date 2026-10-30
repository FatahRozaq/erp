CREATE TABLE inventory.return_inspections (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  sales_return_guid uuid NOT NULL,
  warehouse_guid uuid NOT NULL,
  business_operation_guid uuid NOT NULL,
  status text NOT NULL CHECK (status IN ('DRAFT','POSTED','VOIDED')),
  posted_at timestamptz,
  posted_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT return_inspections_scope_id_uq UNIQUE (tenant_guid,legal_entity_guid,id),
  CONSTRAINT return_inspections_scope_source_uq UNIQUE (tenant_guid,legal_entity_guid,id,sales_return_guid),
  CONSTRAINT return_inspections_operation_uq UNIQUE (tenant_guid,business_operation_guid),
  CONSTRAINT return_inspections_posted_pair_chk CHECK ((posted_at IS NULL) = (posted_by IS NULL)),
  CONSTRAINT return_inspections_posted_state_chk CHECK (status <> 'POSTED' OR posted_at IS NOT NULL),
  CONSTRAINT return_inspections_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);

-- Operations owns the cumulative inspection guard. The approved quantity is an
-- immutable snapshot from the Sales approval event, not a cross-service FK.
CREATE TABLE inventory.return_inspection_limits (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  sales_return_guid uuid NOT NULL,
  sales_return_line_guid uuid NOT NULL,
  source_portion_guid uuid NOT NULL,
  approved_qty_base numeric(20,6) NOT NULL CHECK (approved_qty_base > 0),
  received_qty_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (received_qty_base >= 0),
  accepted_qty_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (accepted_qty_base >= 0),
  rejected_qty_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (rejected_qty_base >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT return_inspection_limits_scope_id_uq UNIQUE (tenant_guid,legal_entity_guid,id),
  CONSTRAINT return_inspection_limits_scope_line_uq UNIQUE (tenant_guid,legal_entity_guid,id,sales_return_guid,sales_return_line_guid),
  CONSTRAINT return_inspection_limits_source_uq UNIQUE (tenant_guid,legal_entity_guid,sales_return_line_guid),
  CONSTRAINT return_inspection_limits_qty_chk CHECK
    (accepted_qty_base + rejected_qty_base = received_qty_base AND received_qty_base <= approved_qty_base),
  CONSTRAINT return_inspection_limits_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);

CREATE TABLE inventory.return_inspection_lines (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  return_inspection_id bigint NOT NULL,
  return_inspection_limit_id bigint NOT NULL,
  sales_return_guid uuid NOT NULL,
  sales_return_line_guid uuid NOT NULL,
  accepted_qty_base numeric(20,6) NOT NULL CHECK (accepted_qty_base >= 0),
  rejected_qty_base numeric(20,6) NOT NULL CHECK (rejected_qty_base >= 0),
  disposition text NOT NULL CHECK (disposition IN ('SELLABLE','HOLD','DAMAGED')),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT return_inspection_lines_header_fk FOREIGN KEY (tenant_guid,legal_entity_guid,return_inspection_id,sales_return_guid)
    REFERENCES inventory.return_inspections (tenant_guid,legal_entity_guid,id,sales_return_guid),
  CONSTRAINT return_inspection_lines_limit_fk FOREIGN KEY (tenant_guid,legal_entity_guid,return_inspection_limit_id,sales_return_guid,sales_return_line_guid)
    REFERENCES inventory.return_inspection_limits (tenant_guid,legal_entity_guid,id,sales_return_guid,sales_return_line_guid),
  CONSTRAINT return_inspection_lines_source_uq UNIQUE (return_inspection_id,sales_return_line_guid),
  CONSTRAINT return_inspection_lines_nonzero_chk CHECK (accepted_qty_base + rejected_qty_base > 0),
  CONSTRAINT return_inspection_lines_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);
