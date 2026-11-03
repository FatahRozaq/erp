-- B-02.1 additive hardening. Rollback uses forward-fix; preserve all rows.
REVOKE ALL ON SCHEMA inventory FROM PUBLIC;
GRANT USAGE ON SCHEMA inventory TO erp_operations_runtime;
REVOKE ALL ON ALL TABLES IN SCHEMA inventory FROM PUBLIC, erp_operations_runtime;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA inventory FROM PUBLIC, erp_operations_runtime;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA inventory TO erp_operations_runtime;
GRANT SELECT, INSERT ON inventory.receipt_limits TO erp_operations_runtime;
GRANT SELECT, INSERT ON inventory.goods_receipts TO erp_operations_runtime;
GRANT SELECT, INSERT ON inventory.goods_receipt_lines TO erp_operations_runtime;
GRANT SELECT, INSERT ON inventory.cost_pools TO erp_operations_runtime;
GRANT SELECT, INSERT ON inventory.stock_balances TO erp_operations_runtime;
GRANT SELECT, INSERT ON inventory.return_inspections TO erp_operations_runtime;
GRANT SELECT, INSERT ON inventory.return_inspection_limits TO erp_operations_runtime;
GRANT SELECT, INSERT ON inventory.return_inspection_lines TO erp_operations_runtime;
GRANT SELECT, INSERT ON inventory.stock_movements TO erp_operations_runtime;
GRANT UPDATE ON inventory.receipt_limits TO erp_operations_runtime;
CREATE TRIGGER receipt_limits_metadata_trg BEFORE INSERT OR UPDATE ON inventory.receipt_limits
  FOR EACH ROW EXECUTE FUNCTION operations_runtime.enforce_metadata_v1();
GRANT UPDATE ON inventory.goods_receipts TO erp_operations_runtime;
CREATE TRIGGER goods_receipts_metadata_trg BEFORE INSERT OR UPDATE ON inventory.goods_receipts
  FOR EACH ROW EXECUTE FUNCTION operations_runtime.enforce_metadata_v1();
GRANT UPDATE ON inventory.goods_receipt_lines TO erp_operations_runtime;
CREATE TRIGGER goods_receipt_lines_metadata_trg BEFORE INSERT OR UPDATE ON inventory.goods_receipt_lines
  FOR EACH ROW EXECUTE FUNCTION operations_runtime.enforce_metadata_v1();
GRANT UPDATE ON inventory.cost_pools TO erp_operations_runtime;
CREATE TRIGGER cost_pools_metadata_trg BEFORE INSERT OR UPDATE ON inventory.cost_pools
  FOR EACH ROW EXECUTE FUNCTION operations_runtime.enforce_metadata_v1();
GRANT UPDATE ON inventory.stock_balances TO erp_operations_runtime;
CREATE TRIGGER stock_balances_metadata_trg BEFORE INSERT OR UPDATE ON inventory.stock_balances
  FOR EACH ROW EXECUTE FUNCTION operations_runtime.enforce_metadata_v1();
GRANT UPDATE ON inventory.return_inspections TO erp_operations_runtime;
CREATE TRIGGER return_inspections_metadata_trg BEFORE INSERT OR UPDATE ON inventory.return_inspections
  FOR EACH ROW EXECUTE FUNCTION operations_runtime.enforce_metadata_v1();
GRANT UPDATE ON inventory.return_inspection_limits TO erp_operations_runtime;
CREATE TRIGGER return_inspection_limits_metadata_trg BEFORE INSERT OR UPDATE ON inventory.return_inspection_limits
  FOR EACH ROW EXECUTE FUNCTION operations_runtime.enforce_metadata_v1();
GRANT UPDATE ON inventory.return_inspection_lines TO erp_operations_runtime;
CREATE TRIGGER return_inspection_lines_metadata_trg BEFORE INSERT OR UPDATE ON inventory.return_inspection_lines
  FOR EACH ROW EXECUTE FUNCTION operations_runtime.enforce_metadata_v1();
