-- B-02.1 additive hardening. Rollback uses forward-fix; preserve all rows.
REVOKE ALL ON SCHEMA sales FROM PUBLIC;
GRANT USAGE ON SCHEMA sales TO erp_commercial_runtime;
REVOKE ALL ON ALL TABLES IN SCHEMA sales FROM PUBLIC, erp_commercial_runtime;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA sales FROM PUBLIC, erp_commercial_runtime;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA sales TO erp_commercial_runtime;
GRANT SELECT, INSERT ON sales.sales_returns TO erp_commercial_runtime;
GRANT SELECT, INSERT ON sales.sales_return_lines TO erp_commercial_runtime;
GRANT UPDATE ON sales.sales_returns TO erp_commercial_runtime;
CREATE TRIGGER sales_returns_metadata_trg BEFORE INSERT OR UPDATE ON sales.sales_returns
  FOR EACH ROW EXECUTE FUNCTION commercial_runtime.enforce_metadata_v1();
GRANT UPDATE ON sales.sales_return_lines TO erp_commercial_runtime;
CREATE TRIGGER sales_return_lines_metadata_trg BEFORE INSERT OR UPDATE ON sales.sales_return_lines
  FOR EACH ROW EXECUTE FUNCTION commercial_runtime.enforce_metadata_v1();
