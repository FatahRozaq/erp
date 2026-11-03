-- B-02.1 additive hardening. Rollback uses forward-fix; preserve all rows.
REVOKE ALL ON SCHEMA finance FROM PUBLIC;
GRANT USAGE ON SCHEMA finance TO erp_finance_runtime;
REVOKE ALL ON ALL TABLES IN SCHEMA finance FROM PUBLIC, erp_finance_runtime;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA finance FROM PUBLIC, erp_finance_runtime;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA finance TO erp_finance_runtime;
GRANT SELECT, INSERT ON finance.posting_intents TO erp_finance_runtime;
GRANT SELECT, INSERT ON finance.billing_source_portions TO erp_finance_runtime;
GRANT SELECT, INSERT ON finance.credit_memos TO erp_finance_runtime;
GRANT SELECT, INSERT ON finance.credit_memo_lines TO erp_finance_runtime;
GRANT UPDATE ON finance.posting_intents TO erp_finance_runtime;
CREATE TRIGGER posting_intents_metadata_trg BEFORE INSERT OR UPDATE ON finance.posting_intents
  FOR EACH ROW EXECUTE FUNCTION finance_runtime.enforce_metadata_v1();
GRANT UPDATE ON finance.billing_source_portions TO erp_finance_runtime;
CREATE TRIGGER billing_source_portions_metadata_trg BEFORE INSERT OR UPDATE ON finance.billing_source_portions
  FOR EACH ROW EXECUTE FUNCTION finance_runtime.enforce_metadata_v1();
GRANT UPDATE ON finance.credit_memos TO erp_finance_runtime;
CREATE TRIGGER credit_memos_metadata_trg BEFORE INSERT OR UPDATE ON finance.credit_memos
  FOR EACH ROW EXECUTE FUNCTION finance_runtime.enforce_metadata_v1();
