-- B-02.1 additive hardening. Rollback uses forward-fix; preserve all rows.
REVOKE ALL ON SCHEMA master FROM PUBLIC;
GRANT USAGE ON SCHEMA master TO erp_platform_runtime;
REVOKE ALL ON ALL TABLES IN SCHEMA master FROM PUBLIC, erp_platform_runtime;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA master FROM PUBLIC, erp_platform_runtime;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA master TO erp_platform_runtime;
GRANT SELECT, INSERT ON master.uoms TO erp_platform_runtime;
GRANT SELECT, INSERT ON master.skus TO erp_platform_runtime;
GRANT UPDATE ON master.uoms TO erp_platform_runtime;
CREATE TRIGGER uoms_metadata_trg BEFORE INSERT OR UPDATE ON master.uoms
  FOR EACH ROW EXECUTE FUNCTION platform_runtime.enforce_metadata_v1();
GRANT UPDATE ON master.skus TO erp_platform_runtime;
CREATE TRIGGER skus_metadata_trg BEFORE INSERT OR UPDATE ON master.skus
  FOR EACH ROW EXECUTE FUNCTION platform_runtime.enforce_metadata_v1();
