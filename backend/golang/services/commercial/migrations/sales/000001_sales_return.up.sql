CREATE SCHEMA IF NOT EXISTS sales;

CREATE TABLE sales.sales_returns (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  delivery_guid uuid NOT NULL,
  business_operation_guid uuid NOT NULL,
  reason_code text NOT NULL,
  status text NOT NULL CHECK (status IN ('DRAFT','SUBMITTED','APPROVED','INSPECTED','POSTING_PENDING','POSTED','CLOSED','REJECTED','EXCEPTION')),
  credit_memo_guid uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT sales_returns_scope_id_uq UNIQUE (tenant_guid,legal_entity_guid,id),
  CONSTRAINT sales_returns_operation_uq UNIQUE (tenant_guid,business_operation_guid),
  CONSTRAINT sales_returns_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);
CREATE INDEX sales_returns_list_idx ON sales.sales_returns (tenant_guid,legal_entity_guid,status,created_at DESC,id DESC) WHERE deleted_at IS NULL;

CREATE TABLE sales.sales_return_lines (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  sales_return_id bigint NOT NULL,
  line_no integer NOT NULL CHECK (line_no > 0),
  delivery_line_guid uuid NOT NULL,
  source_portion_guid uuid NOT NULL,
  requested_qty_base numeric(20,6) NOT NULL CHECK (requested_qty_base > 0),
  approved_qty_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (approved_qty_base >= 0),
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
  CONSTRAINT sales_return_lines_header_fk FOREIGN KEY (tenant_guid,legal_entity_guid,sales_return_id)
    REFERENCES sales.sales_returns (tenant_guid,legal_entity_guid,id),
  CONSTRAINT sales_return_lines_line_uq UNIQUE (sales_return_id,line_no),
  CONSTRAINT sales_return_lines_source_uq UNIQUE (sales_return_id,source_portion_guid),
  CONSTRAINT sales_return_lines_qty_chk CHECK
    (approved_qty_base <= requested_qty_base AND received_qty_base <= approved_qty_base
      AND accepted_qty_base + rejected_qty_base = received_qty_base),
  CONSTRAINT sales_return_lines_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);
