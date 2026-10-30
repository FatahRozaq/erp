CREATE SCHEMA IF NOT EXISTS master;

CREATE TABLE master.uoms (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  code text NOT NULL,
  name text NOT NULL,
  status text NOT NULL CHECK (status IN ('ACTIVE','INACTIVE')),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT uoms_scope_id_uq UNIQUE (tenant_guid,id),
  CONSTRAINT uoms_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);
CREATE UNIQUE INDEX uoms_active_code_uq ON master.uoms (tenant_guid,code) WHERE deleted_at IS NULL;

CREATE TABLE master.skus (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  code text NOT NULL,
  name text NOT NULL,
  base_uom_id bigint NOT NULL,
  valuation_class text NOT NULL DEFAULT 'MOVING_AVERAGE' CHECK (valuation_class = 'MOVING_AVERAGE'),
  status text NOT NULL CHECK (status IN ('DRAFT','PUBLISHED','INACTIVE')),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT skus_scope_id_uq UNIQUE (tenant_guid,id),
  CONSTRAINT skus_uom_fk FOREIGN KEY (tenant_guid,base_uom_id) REFERENCES master.uoms (tenant_guid,id),
  CONSTRAINT skus_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);
CREATE UNIQUE INDEX skus_active_code_uq ON master.skus (tenant_guid,code) WHERE deleted_at IS NULL;
CREATE INDEX skus_list_idx ON master.skus (tenant_guid,status,code,id) WHERE deleted_at IS NULL;
