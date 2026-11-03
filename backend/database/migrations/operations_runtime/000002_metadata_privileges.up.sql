-- B-02.1 additive hardening. Rollback uses forward-fix; preserve all rows.
REVOKE ALL ON SCHEMA operations_runtime FROM PUBLIC;
GRANT USAGE ON SCHEMA operations_runtime TO erp_operations_runtime;
REVOKE ALL ON ALL TABLES IN SCHEMA operations_runtime FROM PUBLIC, erp_operations_runtime;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA operations_runtime FROM PUBLIC, erp_operations_runtime;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA operations_runtime TO erp_operations_runtime;
CREATE FUNCTION operations_runtime.enforce_metadata_v1() RETURNS trigger
LANGUAGE plpgsql VOLATILE SECURITY INVOKER
SET search_path = pg_catalog, pg_temp AS $body$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.version <> 1 OR NEW.updated_by IS DISTINCT FROM NEW.created_by
       OR NEW.deleted_at IS NOT NULL OR NEW.deleted_by IS NOT NULL THEN
      RAISE EXCEPTION 'invalid initial metadata' USING ERRCODE = '23514';
    END IF;
    NEW.created_at := statement_timestamp();
    NEW.updated_at := NEW.created_at;
  ELSE
    IF NEW.id IS DISTINCT FROM OLD.id OR NEW.guid IS DISTINCT FROM OLD.guid
       OR NEW.tenant_guid IS DISTINCT FROM OLD.tenant_guid
       OR (to_jsonb(NEW)->'legal_entity_guid') IS DISTINCT FROM (to_jsonb(OLD)->'legal_entity_guid')
       OR NEW.created_at IS DISTINCT FROM OLD.created_at
       OR NEW.created_by IS DISTINCT FROM OLD.created_by THEN
      RAISE EXCEPTION 'immutable metadata changed' USING ERRCODE = '23514';
    END IF;
    IF NEW.version IS DISTINCT FROM OLD.version + 1 OR NEW.updated_by IS NULL THEN
      RAISE EXCEPTION 'mutation requires next version and actor' USING ERRCODE = '23514';
    END IF;
    IF NEW.deleted_at IS DISTINCT FROM OLD.deleted_at AND NEW.deleted_at IS NOT NULL
       AND NEW.deleted_by IS DISTINCT FROM NEW.updated_by THEN
      RAISE EXCEPTION 'deletion actor must match mutation actor' USING ERRCODE = '23514';
    END IF;
    NEW.updated_at := statement_timestamp();
  END IF;
  RETURN NEW;
END
$body$;
COMMENT ON FUNCTION operations_runtime.enforce_metadata_v1() IS
  'Owner-local mutable row metadata; SQLSTATE 23514; no writes or external calls. Service must use scoped CAS and verified actors.';
REVOKE ALL ON FUNCTION operations_runtime.enforce_metadata_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION operations_runtime.enforce_metadata_v1() TO erp_operations_runtime;

-- Provenance for rows written under the old audit contract; future callers must supply module/source.
ALTER TABLE operations_runtime.audit_events
  ADD COLUMN scope_guids jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN module text NOT NULL DEFAULT 'legacy',
  ADD COLUMN source text NOT NULL DEFAULT 'legacy-baseline',
  ADD COLUMN delegator_guid uuid,
  ADD COLUMN policy_version text,
  ADD COLUMN ip_address inet,
  ADD COLUMN device_id text,
  ADD COLUMN user_agent text;
ALTER TABLE operations_runtime.audit_events ALTER COLUMN module DROP DEFAULT, ALTER COLUMN source DROP DEFAULT;
GRANT SELECT, INSERT ON operations_runtime.business_operations, operations_runtime.inbox_events, operations_runtime.audit_events TO erp_operations_runtime;
GRANT SELECT, INSERT ON operations_runtime.idempotency_records, operations_runtime.outbox_events TO erp_operations_runtime;
GRANT UPDATE (status, response_status, response_body, expires_at, updated_at, updated_by, deleted_at, deleted_by, version)
  ON operations_runtime.idempotency_records TO erp_operations_runtime;
GRANT UPDATE (delivery_status, attempt_count, next_attempt_at, updated_at, updated_by, version)
  ON operations_runtime.outbox_events TO erp_operations_runtime;
CREATE TRIGGER idempotency_records_metadata_trg BEFORE INSERT OR UPDATE ON operations_runtime.idempotency_records
  FOR EACH ROW EXECUTE FUNCTION operations_runtime.enforce_metadata_v1();
CREATE TRIGGER outbox_events_metadata_trg BEFORE INSERT OR UPDATE ON operations_runtime.outbox_events
  FOR EACH ROW EXECUTE FUNCTION operations_runtime.enforce_metadata_v1();
