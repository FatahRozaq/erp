-- B-02.1 additive hardening. Rollback uses forward-fix; preserve all rows.
REVOKE ALL ON SCHEMA accounting FROM PUBLIC;
GRANT USAGE ON SCHEMA accounting TO erp_finance_runtime;
REVOKE ALL ON ALL TABLES IN SCHEMA accounting FROM PUBLIC, erp_finance_runtime;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA accounting FROM PUBLIC, erp_finance_runtime;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA accounting TO erp_finance_runtime;
GRANT SELECT, INSERT ON accounting.accounts TO erp_finance_runtime;
GRANT SELECT, INSERT ON accounting.fiscal_periods TO erp_finance_runtime;
GRANT SELECT, INSERT ON accounting.journals TO erp_finance_runtime;
GRANT SELECT, INSERT ON accounting.journal_lines TO erp_finance_runtime;
GRANT UPDATE ON accounting.accounts TO erp_finance_runtime;
CREATE TRIGGER accounts_metadata_trg BEFORE INSERT OR UPDATE ON accounting.accounts
  FOR EACH ROW EXECUTE FUNCTION finance_runtime.enforce_metadata_v1();
GRANT UPDATE ON accounting.fiscal_periods TO erp_finance_runtime;
CREATE TRIGGER fiscal_periods_metadata_trg BEFORE INSERT OR UPDATE ON accounting.fiscal_periods
  FOR EACH ROW EXECUTE FUNCTION finance_runtime.enforce_metadata_v1();
ALTER FUNCTION accounting.reject_overlapping_fiscal_period() SECURITY INVOKER;
ALTER FUNCTION accounting.reject_overlapping_fiscal_period() SET search_path = pg_catalog, pg_temp;
REVOKE ALL ON FUNCTION accounting.reject_overlapping_fiscal_period() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION accounting.reject_overlapping_fiscal_period() TO erp_finance_runtime;
COMMENT ON FUNCTION accounting.reject_overlapping_fiscal_period() IS
  'Legacy baseline signature retained. Requires SERIALIZABLE (25000); rejects overlapping active periods (23514).';
