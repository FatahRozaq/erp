CREATE SCHEMA IF NOT EXISTS commercial_runtime;

CREATE TABLE commercial_runtime.business_operations (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid,
  business_operation_guid uuid NOT NULL,
  action text NOT NULL,
  source_guid uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  CONSTRAINT business_operations_key_uq UNIQUE (tenant_guid,business_operation_guid)
);

CREATE TABLE commercial_runtime.idempotency_records (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  principal_guid uuid NOT NULL,
  method text NOT NULL,
  route_action text NOT NULL,
  idempotency_key text NOT NULL,
  request_sha256 text NOT NULL CHECK (request_sha256 ~ '^[a-f0-9]{64}$'),
  business_operation_guid uuid NOT NULL,
  status text NOT NULL CHECK (status IN ('IN_PROGRESS','COMPLETED','FAILED')),
  response_status integer,
  response_body jsonb,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT idempotency_records_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);
CREATE UNIQUE INDEX idempotency_records_active_key_uq ON commercial_runtime.idempotency_records (tenant_guid,principal_guid,method,route_action,idempotency_key) WHERE deleted_at IS NULL;
CREATE INDEX idempotency_records_expiry_idx ON commercial_runtime.idempotency_records (expires_at);

CREATE TABLE commercial_runtime.outbox_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid,
  aggregate_guid uuid NOT NULL,
  aggregate_version bigint NOT NULL CHECK (aggregate_version > 0),
  event_type text NOT NULL,
  schema_version integer NOT NULL CHECK (schema_version > 0),
  business_operation_guid uuid NOT NULL,
  payload jsonb NOT NULL,
  occurred_at timestamptz NOT NULL,
  recorded_at timestamptz NOT NULL DEFAULT statement_timestamp(),
  delivery_status text NOT NULL DEFAULT 'PENDING' CHECK (delivery_status IN ('PENDING','PUBLISHED','FAILED')),
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  next_attempt_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT outbox_events_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL)),
  CONSTRAINT outbox_events_aggregate_version_uq UNIQUE (tenant_guid,aggregate_guid,aggregate_version,event_type)
);
CREATE INDEX outbox_events_due_idx ON commercial_runtime.outbox_events (delivery_status,next_attempt_at,id) WHERE delivery_status <> 'PUBLISHED';

CREATE TABLE commercial_runtime.inbox_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  consumer_name text NOT NULL,
  event_guid uuid NOT NULL,
  aggregate_guid uuid NOT NULL,
  aggregate_version bigint NOT NULL CHECK (aggregate_version > 0),
  processed_at timestamptz NOT NULL DEFAULT statement_timestamp(),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  CONSTRAINT inbox_events_dedup_uq UNIQUE (consumer_name,event_guid)
);
CREATE INDEX inbox_events_aggregate_idx ON commercial_runtime.inbox_events (tenant_guid,consumer_name,aggregate_guid,aggregate_version DESC);

CREATE TABLE commercial_runtime.audit_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid,
  target_type text NOT NULL,
  target_guid uuid,
  action text NOT NULL,
  actor_guid uuid,
  actor_type text NOT NULL CHECK (actor_type IN ('USER','SERVICE','SYSTEM','ANONYMOUS')),
  outcome text NOT NULL CHECK (outcome IN ('SUCCESS','DENIED','FAILED')),
  reason text,
  request_id text,
  correlation_id uuid,
  trace_id text,
  before_redacted jsonb,
  after_redacted jsonb,
  occurred_at timestamptz NOT NULL,
  recorded_at timestamptz NOT NULL DEFAULT statement_timestamp(),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  CONSTRAINT audit_events_actor_chk CHECK (actor_type = 'ANONYMOUS' OR actor_guid IS NOT NULL)
);
CREATE INDEX audit_events_target_idx ON commercial_runtime.audit_events (tenant_guid,target_type,target_guid,recorded_at DESC);
