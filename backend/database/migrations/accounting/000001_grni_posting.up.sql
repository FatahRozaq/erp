CREATE SCHEMA IF NOT EXISTS finance;
CREATE SCHEMA IF NOT EXISTS accounting;

CREATE TABLE accounting.accounts (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  code text NOT NULL,
  name text NOT NULL,
  account_type text NOT NULL CHECK (account_type IN ('ASSET','LIABILITY','EQUITY','REVENUE','EXPENSE')),
  status text NOT NULL CHECK (status IN ('ACTIVE','INACTIVE')),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT accounts_scope_id_uq UNIQUE (tenant_guid,legal_entity_guid,id),
  CONSTRAINT accounts_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);
CREATE UNIQUE INDEX accounts_active_code_uq ON accounting.accounts (tenant_guid,legal_entity_guid,code) WHERE deleted_at IS NULL;

CREATE TABLE accounting.fiscal_periods (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  period_start date NOT NULL,
  period_end date NOT NULL,
  status text NOT NULL CHECK (status IN ('OPEN','CLOSED')),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT fiscal_periods_scope_id_uq UNIQUE (tenant_guid,legal_entity_guid,id),
  CONSTRAINT fiscal_periods_range_chk CHECK (period_end >= period_start),
  CONSTRAINT fiscal_periods_key_uq UNIQUE (tenant_guid,legal_entity_guid,period_start,period_end),
  CONSTRAINT fiscal_periods_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);
-- Portable overlap guard: period mutations require SERIALIZABLE so concurrent
-- inserts with the same range cannot both commit after the predicate check.
CREATE FUNCTION accounting.reject_overlapping_fiscal_period() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'fiscal period mutation requires SERIALIZABLE'
      USING ERRCODE = '25000';
  END IF;
  IF NEW.deleted_at IS NULL AND EXISTS (
    SELECT 1 FROM accounting.fiscal_periods p
    WHERE p.tenant_guid = NEW.tenant_guid
      AND p.legal_entity_guid = NEW.legal_entity_guid
      AND p.id IS DISTINCT FROM NEW.id
      AND p.deleted_at IS NULL
      AND daterange(p.period_start,p.period_end,'[]') &&
          daterange(NEW.period_start,NEW.period_end,'[]')
  ) THEN
    RAISE EXCEPTION 'fiscal periods overlap' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER fiscal_periods_no_overlap_trg
  BEFORE INSERT OR UPDATE OF period_start,period_end,deleted_at
  ON accounting.fiscal_periods
  FOR EACH ROW EXECUTE FUNCTION accounting.reject_overlapping_fiscal_period();

CREATE TABLE finance.posting_intents (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  source_type text NOT NULL,
  source_guid uuid NOT NULL,
  source_event_guid uuid NOT NULL,
  business_operation_guid uuid NOT NULL,
  status text NOT NULL CHECK (status IN ('PENDING','POSTED','FAILED')),
  last_error_code text,
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NOT NULL,
  deleted_at timestamptz,
  deleted_by uuid,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  CONSTRAINT posting_intents_source_uq UNIQUE (tenant_guid,legal_entity_guid,source_type,source_guid),
  CONSTRAINT posting_intents_event_uq UNIQUE (source_event_guid),
  CONSTRAINT posting_intents_scope_id_uq UNIQUE (tenant_guid,legal_entity_guid,id),
  CONSTRAINT posting_intents_deleted_pair_chk CHECK ((deleted_at IS NULL) = (deleted_by IS NULL))
);
CREATE INDEX posting_intents_pending_idx ON finance.posting_intents (tenant_guid,legal_entity_guid,status,created_at) WHERE status <> 'POSTED';

CREATE TABLE accounting.journals (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  period_id bigint NOT NULL,
  posting_intent_guid uuid NOT NULL,
  source_type text NOT NULL,
  source_guid uuid NOT NULL,
  business_date date NOT NULL,
  posted_at timestamptz NOT NULL,
  posted_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  CONSTRAINT journals_period_fk FOREIGN KEY (tenant_guid,legal_entity_guid,period_id)
    REFERENCES accounting.fiscal_periods (tenant_guid,legal_entity_guid,id),
  CONSTRAINT journals_scope_id_uq UNIQUE (tenant_guid,legal_entity_guid,id),
  CONSTRAINT journals_source_uq UNIQUE (tenant_guid,legal_entity_guid,source_type,source_guid),
  CONSTRAINT journals_intent_uq UNIQUE (posting_intent_guid)
);
CREATE INDEX journals_period_idx ON accounting.journals (tenant_guid,legal_entity_guid,period_id,business_date,id);

CREATE TABLE accounting.journal_lines (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  guid uuid NOT NULL DEFAULT uuidv7() UNIQUE,
  tenant_guid uuid NOT NULL,
  legal_entity_guid uuid NOT NULL,
  journal_id bigint NOT NULL,
  account_id bigint NOT NULL,
  line_no integer NOT NULL CHECK (line_no > 0),
  debit_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (debit_base >= 0),
  credit_base numeric(20,6) NOT NULL DEFAULT 0 CHECK (credit_base >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  CONSTRAINT journal_lines_journal_fk FOREIGN KEY (tenant_guid,legal_entity_guid,journal_id)
    REFERENCES accounting.journals (tenant_guid,legal_entity_guid,id),
  CONSTRAINT journal_lines_account_fk FOREIGN KEY (tenant_guid,legal_entity_guid,account_id)
    REFERENCES accounting.accounts (tenant_guid,legal_entity_guid,id),
  CONSTRAINT journal_lines_no_zero_or_both_chk CHECK ((debit_base > 0 AND credit_base = 0) OR (credit_base > 0 AND debit_base = 0)),
  CONSTRAINT journal_lines_order_uq UNIQUE (journal_id,line_no)
);
-- Application posting transaction verifies SUM(debit_base)=SUM(credit_base) before commit.
