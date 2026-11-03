-- B-02.1 additive hardening. Rollback uses forward-fix; preserve all rows.
REVOKE ALL ON SCHEMA purchase FROM PUBLIC;
GRANT USAGE ON SCHEMA purchase TO erp_commercial_runtime;
REVOKE ALL ON ALL TABLES IN SCHEMA purchase FROM PUBLIC, erp_commercial_runtime;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA purchase FROM PUBLIC, erp_commercial_runtime;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA purchase TO erp_commercial_runtime;
GRANT SELECT, INSERT ON purchase.purchase_orders TO erp_commercial_runtime;
GRANT SELECT, INSERT ON purchase.purchase_order_lines TO erp_commercial_runtime;
GRANT UPDATE ON purchase.purchase_orders TO erp_commercial_runtime;
CREATE TRIGGER purchase_orders_metadata_trg BEFORE INSERT OR UPDATE ON purchase.purchase_orders
  FOR EACH ROW EXECUTE FUNCTION commercial_runtime.enforce_metadata_v1();
GRANT UPDATE ON purchase.purchase_order_lines TO erp_commercial_runtime;
CREATE TRIGGER purchase_order_lines_metadata_trg BEFORE INSERT OR UPDATE ON purchase.purchase_order_lines
  FOR EACH ROW EXECUTE FUNCTION commercial_runtime.enforce_metadata_v1();
