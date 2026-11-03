package migration

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

const tenant = "10000000-0000-4000-8000-000000000001"
const actor = "20000000-0000-4000-8000-000000000001"
const entity = "30000000-0000-4000-8000-000000000001"

var quiet = slog.New(slog.NewJSONHandler(io.Discard, nil))

type databaseFixture struct {
	Plan                   Plan
	Admin, Deploy, Runtime *pgx.Conn
	AdminConfig            *pgx.ConnConfig
	DSN, RuntimeDSN        string
}

func fixture(t *testing.T, owner string) databaseFixture {
	t.Helper()
	dsn := os.Getenv("ERP_MIGRATION_TEST_DSN")
	if dsn == "" {
		t.Skip("ERP_MIGRATION_TEST_DSN absent; PostgreSQL integration not run")
	}
	cfg, err := pgx.ParseConfig(dsn)
	if err != nil {
		t.Fatal("invalid test database config")
	}
	admin, err := pgx.ConnectConfig(context.Background(), cfg)
	if err != nil {
		t.Fatal("connect test administrator failed")
	}
	t.Cleanup(func() { _ = admin.Close(context.Background()) })
	plan, err := Load(repositoryDatabase(t), owner)
	if err != nil {
		t.Fatal(err)
	}
	var nonce [8]byte
	if _, err := rand.Read(nonce[:]); err != nil {
		t.Fatal(err)
	}
	database := "erp_b021_" + hex.EncodeToString(nonce[:])
	qdb := pgx.Identifier{database}.Sanitize()
	mustExec(t, admin, "CREATE DATABASE "+qdb)
	t.Cleanup(func() {
		_, err := admin.Exec(context.Background(), "DROP DATABASE "+qdb+" WITH (FORCE)")
		if err != nil {
			t.Errorf("cleanup disposable database: %v", err)
		}
	})
	mustExec(t, admin, "REVOKE ALL ON DATABASE "+qdb+" FROM PUBLIC")
	mustExec(t, admin, "GRANT CONNECT, CREATE ON DATABASE "+qdb+" TO "+pgx.Identifier{plan.Owner.DeployRole}.Sanitize())
	mustExec(t, admin, "GRANT CONNECT ON DATABASE "+qdb+" TO "+pgx.Identifier{plan.Owner.RuntimeRole}.Sanitize())
	adminCfg := cfg.Copy()
	adminCfg.Database = database
	dbAdmin := connect(t, adminCfg)
	mustExec(t, dbAdmin, "REVOKE ALL ON SCHEMA public FROM PUBLIC")
	deployCfg := adminCfg.Copy()
	deployCfg.User = plan.Owner.DeployRole
	deployCfg.Password = "erp_local_only"
	runtimeCfg := adminCfg.Copy()
	runtimeCfg.User = plan.Owner.RuntimeRole
	runtimeCfg.Password = "erp_local_only"
	plan.Owner.Database = database
	return databaseFixture{plan, dbAdmin, connect(t, deployCfg), connect(t, runtimeCfg), adminCfg, connectionString(deployCfg), connectionString(runtimeCfg)}
}

// ConnString() retains the parsed original DSN; construct a fresh config string
// from fields after replacing database/role. Synthetic test credentials only.
func connectionString(c *pgx.ConnConfig) string {
	return fmt.Sprintf("host=%s port=%d dbname=%s user=%s password=%s sslmode=disable", c.Host, c.Port, c.Database, c.User, c.Password)
}
func connect(t *testing.T, cfg *pgx.ConnConfig) *pgx.Conn {
	t.Helper()
	conn, err := pgx.ConnectConfig(context.Background(), cfg)
	if err != nil {
		t.Fatal("connect test role failed")
	}
	t.Cleanup(func() { _ = conn.Close(context.Background()) })
	return conn
}
func mustExec(t *testing.T, conn *pgx.Conn, sql string, args ...any) {
	t.Helper()
	if _, err := conn.Exec(context.Background(), sql, args...); err != nil {
		t.Fatalf("fixture SQL failed: %v", err)
	}
}
func integer(t *testing.T, conn *pgx.Conn, sql string, args ...any) int {
	t.Helper()
	var n int
	if err := conn.QueryRow(context.Background(), sql, args...).Scan(&n); err != nil {
		t.Fatal(err)
	}
	return n
}
func expectCode(t *testing.T, conn *pgx.Conn, sql, code string, args ...any) {
	t.Helper()
	_, err := conn.Exec(context.Background(), sql, args...)
	var pgerr *pgconn.PgError
	if !errors.As(err, &pgerr) || pgerr.Code != code {
		t.Fatalf("expected SQLSTATE %s, got %v", code, err)
	}
}
func apply(t *testing.T, f databaseFixture, plan Plan) Result {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	result, err := Run(ctx, f.DSN, plan, true, quiet)
	if err != nil {
		t.Fatal(err)
	}
	return result
}
func auditSQL(schema string, legacy bool) string {
	columns := "tenant_guid,target_type,action,actor_guid,actor_type,outcome,occurred_at,created_by"
	values := fmt.Sprintf("'%s','fixture','TEST','%s','SERVICE','SUCCESS',now(),'%s'", tenant, actor, actor)
	if !legacy {
		columns += ",module,source"
		values += ",'fixture','integration-test'"
	}
	return "INSERT INTO " + schema + ".audit_events (" + columns + ") VALUES (" + values + ")"
}
func insertUom(t *testing.T, conn *pgx.Conn, code string) {
	t.Helper()
	mustExec(t, conn, "INSERT INTO master.uoms (tenant_guid,code,name,status,created_by,updated_by) VALUES ($1,$2,'Unit','ACTIVE',$3,$3)", tenant, code, actor)
}

func TestPostgresFreshOwnersAndPrivileges(t *testing.T) {
	for _, owner := range []string{"platform", "commercial", "operations", "finance"} {
		t.Run(owner, func(t *testing.T) {
			f := fixture(t, owner)
			result, err := Run(context.Background(), f.DSN, f.Plan, false, quiet)
			if err != nil || result.Pending != len(f.Plan.Files) {
				t.Fatalf("fresh status: %v %+v", err, result)
			}
			if integer(t, f.Admin, "SELECT count(*) FROM pg_namespace WHERE nspname='erp_migration'") != 0 {
				t.Fatal("status mutated database")
			}
			result = apply(t, f, f.Plan)
			if result.Applied != len(f.Plan.Files) {
				t.Fatalf("applied %+v", result)
			}
			if result = apply(t, f, f.Plan); result.Applied != 0 {
				t.Fatal("rerun not idempotent")
			}
			if integer(t, f.Deploy, "SELECT count(*) FROM erp_migration.history") != len(f.Plan.Files) {
				t.Fatal("ledger incomplete")
			}
			for _, file := range f.Plan.Files {
				var checksum, by string
				if err := f.Deploy.QueryRow(context.Background(), "SELECT checksum,applied_by FROM erp_migration.history WHERE schema_name=$1 AND version=$2", file.Schema, file.Version).Scan(&checksum, &by); err != nil {
					t.Fatal(err)
				}
				if checksum != file.Checksum || by != f.Plan.Owner.DeployRole {
					t.Fatal("wrong ledger checksum/actor")
				}
			}
			for _, sql := range []string{"CREATE SCHEMA forbidden", "CREATE TABLE public.forbidden (id int)", "CREATE TEMP TABLE forbidden (id int)", "SELECT * FROM erp_migration.history", "SET ROLE " + f.Plan.Owner.DeployRole} {
				expectCode(t, f.Runtime, sql, "42501")
			}
			if _, err := Run(context.Background(), f.RuntimeDSN, f.Plan, true, quiet); err == nil {
				t.Fatal("runtime ran migrations")
			}
			// Another owner's runtime cannot connect, even when it shares the cluster.
			other := f.AdminConfig.Copy()
			other.User = "erp_platform_runtime"
			if owner == "platform" {
				other.User = "erp_finance_runtime"
			}
			other.Password = "erp_local_only"
			foreign, err := pgx.ConnectConfig(context.Background(), other)
			if err == nil {
				_ = foreign.Close(context.Background())
				t.Fatal("cross-owner connection allowed")
			}
			schema := owner + "_runtime"
			expectCode(t, f.Runtime, "CREATE TABLE "+schema+".forbidden (id int)", "42501")
			expectCode(t, f.Runtime, "ALTER TABLE "+schema+".audit_events ADD COLUMN forbidden int", "42501")
			mustExec(t, f.Runtime, auditSQL(schema, false))
			expectCode(t, f.Runtime, "UPDATE "+schema+".audit_events SET action='TAMPER'", "42501")
			expectCode(t, f.Runtime, "DELETE FROM "+schema+".audit_events", "42501")
			expectCode(t, f.Runtime, "TRUNCATE "+schema+".audit_events", "42501")
			expectCode(t, f.Runtime, "UPDATE "+schema+".outbox_events SET payload='{}'::jsonb", "42501")
			if integer(t, f.Admin, `SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace, LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a WHERE n.nspname=ANY($1) AND a.grantee=0 AND a.privilege_type='EXECUTE'`, f.Plan.Schemas) != 0 {
				t.Fatal("PUBLIC function execute remains")
			}
			if integer(t, f.Admin, `SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname=ANY($1) AND (p.prosecdef OR p.provolatile <> 'v' OR NOT ('search_path=pg_catalog, pg_temp'=ANY(p.proconfig)))`, f.Plan.Schemas) != 0 {
				t.Fatal("unsafe function attributes")
			}
			// Every existing mutable business table has an enabled metadata trigger.
			if integer(t, f.Admin, `SELECT count(*) FROM information_schema.columns c WHERE c.table_schema=ANY($1) AND c.column_name='updated_at' AND NOT EXISTS (SELECT 1 FROM pg_trigger t JOIN pg_class r ON r.oid=t.tgrelid JOIN pg_namespace n ON n.oid=r.relnamespace WHERE n.nspname=c.table_schema AND r.relname=c.table_name AND t.tgname=r.relname||'_metadata_trg' AND t.tgenabled='O')`, f.Plan.Schemas) != 0 {
				t.Fatal("mutable table missing metadata trigger")
			}
			if owner == "finance" {
				if integer(t, f.Deploy, `SELECT count(*) FROM erp_migration.history f JOIN erp_migration.history a ON a.schema_name='accounting' AND a.version=1 WHERE f.schema_name='finance' AND f.version=1 AND f.applied_at>a.applied_at`) != 1 {
					t.Fatal("finance ran before accounting")
				}
				for _, table := range []string{"accounting.journals", "accounting.journal_lines", "finance.credit_memo_lines"} {
					expectCode(t, f.Runtime, "DELETE FROM "+table, "42501")
				}
			}
			if owner == "operations" {
				expectCode(t, f.Runtime, "UPDATE inventory.stock_movements SET created_at=now()", "42501")
			}
		})
	}
}

func TestPostgresMetadataAndAtomicAudit(t *testing.T) {
	f := fixture(t, "platform")
	apply(t, f, f.Plan)
	insertUom(t, f.Runtime, "EA")
	for _, mutation := range []string{"version=version", "guid=uuidv7(),version=version+1", "tenant_guid=uuidv7(),version=version+1", "created_by=uuidv7(),version=version+1", "created_at=created_at-interval '1 day',version=version+1", "deleted_at=now(),deleted_by=uuidv7(),version=version+1"} {
		expectCode(t, f.Runtime, "UPDATE master.uoms SET "+mutation+" WHERE code='EA'", "23514")
	}
	mustExec(t, f.Runtime, "UPDATE master.uoms SET name='Each',version=version+1,updated_by=$1,updated_at='2000-01-01' WHERE code='EA'", actor)
	if integer(t, f.Runtime, "SELECT count(*) FROM master.uoms WHERE code='EA' AND version=2 AND updated_at>=created_at AND id>0 AND guid IS NOT NULL") != 1 {
		t.Fatal("metadata not maintained")
	}
	mustExec(t, f.Runtime, "UPDATE master.uoms SET deleted_at=now(),deleted_by=$1,updated_by=$1,version=version+1 WHERE code='EA'", actor)
	if integer(t, f.Runtime, "SELECT count(*) FROM master.uoms WHERE deleted_by=updated_by AND version=3") != 1 {
		t.Fatal("soft deletion metadata invalid")
	}
	expectCode(t, f.Runtime, "DELETE FROM master.uoms", "42501")
	// A duplicate audit GUID aborts the same transaction as a mutable write.
	mustExec(t, f.Runtime, auditSQL("platform_runtime", false))
	tx, err := f.Runtime.Begin(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	defer rollback(tx)
	if _, err = tx.Exec(context.Background(), "INSERT INTO master.uoms (tenant_guid,code,name,status,created_by,updated_by) VALUES ($1,'ROLLBACK','Unit','ACTIVE',$2,$2)", tenant, actor); err != nil {
		t.Fatal(err)
	}
	_, err = tx.Exec(context.Background(), `INSERT INTO platform_runtime.audit_events (guid,tenant_guid,target_type,action,actor_guid,actor_type,outcome,occurred_at,created_by,module,source) SELECT guid,tenant_guid,target_type,action,actor_guid,actor_type,outcome,occurred_at,created_by,module,source FROM platform_runtime.audit_events LIMIT 1`)
	if errorCode(err) != "23505" {
		t.Fatalf("expected duplicate audit failure: %v", err)
	}
	if err = tx.Commit(context.Background()); err == nil {
		t.Fatal("audit failure committed mutation")
	}
	if integer(t, f.Runtime, "SELECT count(*) FROM master.uoms WHERE code='ROLLBACK'") != 0 {
		t.Fatal("partial audit transaction persisted")
	}
}

func TestPostgresUpgradeAndRestoreAllOwners(t *testing.T) {
	for _, owner := range []string{"platform", "commercial", "operations", "finance"} {
		t.Run(owner, func(t *testing.T) {
			f := fixture(t, owner)
			baseline := f.Plan
			baseline.Files = nil
			for _, file := range f.Plan.Files {
				if file.Version == 1 || (file.Schema == "inventory" && file.Version == 2) {
					baseline.Files = append(baseline.Files, file)
				}
			}
			apply(t, f, baseline)
			mustExec(t, f.Deploy, auditSQL(owner+"_runtime", true))
			if owner == "platform" {
				insertUom(t, f.Deploy, "OLD")
				mustExec(t, f.Deploy, "UPDATE master.uoms SET version=7 WHERE code='OLD'")
			}
			result := apply(t, f, f.Plan)
			if result.Applied != len(f.Plan.Files)-len(baseline.Files) {
				t.Fatal("upgrade count invalid")
			}
			if integer(t, f.Deploy, "SELECT count(*) FROM "+owner+"_runtime.audit_events WHERE source='legacy-baseline' AND module='legacy'") != 1 {
				t.Fatal("legacy audit not preserved")
			}
			if owner == "platform" {
				if integer(t, f.Runtime, "SELECT count(*) FROM master.uoms WHERE code='OLD' AND version=7") != 1 {
					t.Fatal("upgrade changed existing row")
				}
				mustExec(t, f.Runtime, "UPDATE master.uoms SET version=8,updated_by=$1 WHERE code='OLD'", actor)
			}
			// Restore a real custom-format pg_dump into a new isolated database. Roles and
			// ACLs are restored too; rerunning must verify the preserved ledger and no-op.
			dump := filepath.Join(t.TempDir(), "checkpoint.dump")
			postgresCommand(t, f.AdminConfig, "pg_dump", "--format=custom", "--file", dump)
			restored := fixture(t, owner)
			postgresCommand(t, restored.AdminConfig, "pg_restore", "--exit-on-error", "--dbname", restored.Plan.Owner.Database, dump)
			if result = apply(t, restored, restored.Plan); result.Applied != 0 {
				t.Fatal("restored migrations reapplied")
			}
			if integer(t, restored.Runtime, "SELECT count(*) FROM "+owner+"_runtime.audit_events WHERE source='legacy-baseline'") != 1 {
				t.Fatal("restore lost audit")
			}
			expectCode(t, restored.Runtime, "DELETE FROM "+owner+"_runtime.audit_events", "42501")
			if owner == "platform" && integer(t, restored.Runtime, "SELECT count(*) FROM master.uoms WHERE code='OLD' AND version=8") != 1 {
				t.Fatal("restore lost mutable metadata")
			}
		})
	}
}
func postgresCommand(t *testing.T, cfg *pgx.ConnConfig, tool string, args ...string) {
	t.Helper()
	cmd := exec.Command(tool, args...)
	cmd.Env = append(os.Environ(), "PGHOST="+cfg.Host, "PGPORT="+strconv.Itoa(int(cfg.Port)), "PGUSER="+cfg.User, "PGPASSWORD="+cfg.Password, "PGDATABASE="+cfg.Database, "PGSSLMODE=disable")
	if output, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("%s checkpoint command failed: %v: %s", tool, err, output)
	}
}
func appendFixture(plan Plan, sql string) Plan {
	files := append([]File(nil), plan.Files...)
	hash := sha256.Sum256([]byte(sql))
	plan.Files = append(files, File{"master", 3, "000003_fixture.up.sql", hex.EncodeToString(hash[:]), sql})
	return plan
}

func TestPostgresFailureRecoveryAndChecksums(t *testing.T) {
	f := fixture(t, "platform")
	apply(t, f, f.Plan)
	// A later-schema checksum mismatch must fail before applying earlier pending SQL.
	bad := f.Plan
	bad.Files = append([]File(nil), f.Plan.Files...)
	bad.Files[len(bad.Files)-1].Checksum = strings.Repeat("0", 64)
	newSQL := "CREATE TABLE platform_runtime.preflight_probe (id int);"
	hash := sha256.Sum256([]byte(newSQL))
	bad.Files = append([]File{{"platform_runtime", 3, "000003_probe.up.sql", hex.EncodeToString(hash[:]), newSQL}}, bad.Files...)
	if _, err := Run(context.Background(), f.DSN, bad, true, quiet); err == nil {
		t.Fatal("changed checksum accepted")
	}
	if integer(t, f.Admin, "SELECT count(*) FROM pg_tables WHERE schemaname='platform_runtime' AND tablename='preflight_probe'") != 0 {
		t.Fatal("preflight failure partially applied pending SQL")
	}
	renamed := f.Plan
	renamed.Files = append([]File(nil), f.Plan.Files...)
	renamed.Files[0].Name = "000001_renamed.up.sql"
	if _, err := Run(context.Background(), f.DSN, renamed, true, quiet); err == nil {
		t.Fatal("renamed applied migration accepted")
	}
	missing := f.Plan
	missing.Files = missing.Files[:len(missing.Files)-1]
	if _, err := Run(context.Background(), f.DSN, missing, true, quiet); err == nil {
		t.Fatal("missing applied migration accepted")
	}
	broken := appendFixture(f.Plan, "CREATE TABLE master.partial (id int); DO $$ BEGIN RAISE EXCEPTION 'sensitive-fixture'; END $$;")
	var output bytes.Buffer
	if _, err := Run(context.Background(), f.DSN, broken, true, slog.New(slog.NewJSONHandler(&output, nil))); err == nil || strings.Contains(err.Error(), "sensitive-fixture") {
		t.Fatalf("unsafe/missing failure: %v", err)
	}
	if strings.Contains(output.String(), "sensitive-fixture") || !strings.Contains(output.String(), "P0001") {
		t.Fatal("unsafe or unobservable failure log")
	}
	if integer(t, f.Admin, "SELECT count(*) FROM pg_tables WHERE schemaname='master' AND tablename='partial'") != 0 || integer(t, f.Deploy, "SELECT count(*) FROM erp_migration.history WHERE version=3") != 0 {
		t.Fatal("failed file partially persisted")
	}
	fixed := appendFixture(f.Plan, "CREATE TABLE master.partial (id int);")
	if result := apply(t, f, fixed); result.Applied != 1 {
		t.Fatal("failed migration cannot be retried")
	}
	if result := apply(t, f, fixed); result.Applied != 0 {
		t.Fatal("recovered file replayed")
	}
}

func TestPostgresCancellationAndConcurrentRunners(t *testing.T) {
	f := fixture(t, "platform")
	apply(t, f, f.Plan)
	pending := appendFixture(f.Plan, "CREATE TABLE master.interrupted (id int); SELECT pg_sleep(0.5);")
	ctx, cancel := context.WithTimeout(context.Background(), 150*time.Millisecond)
	_, err := Run(ctx, f.DSN, pending, true, quiet)
	cancel()
	if err == nil {
		t.Fatal("deadline did not abort migration")
	}
	if integer(t, f.Admin, "SELECT count(*) FROM pg_tables WHERE schemaname='master' AND tablename='interrupted'") != 0 {
		t.Fatal("canceled file committed")
	}
	var wg sync.WaitGroup
	results := make(chan Result, 2)
	failures := make(chan error, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			result, err := Run(ctx, f.DSN, pending, true, quiet)
			results <- result
			failures <- err
		}()
	}
	wg.Wait()
	close(results)
	close(failures)
	for err := range failures {
		if err != nil {
			t.Fatal(err)
		}
	}
	count := 0
	for result := range results {
		count += result.Applied
	}
	if count != 1 {
		t.Fatalf("competing runners applied %d times", count)
	}
	// A held schema lock gives a bounded failure without changing ledger.
	mustExec(t, f.Deploy, "SELECT pg_advisory_lock($1)", lockKey("master"))
	ctx, cancel = context.WithTimeout(context.Background(), 150*time.Millisecond)
	_, err = Run(ctx, f.DSN, pending, true, quiet)
	cancel()
	mustExec(t, f.Deploy, "SELECT pg_advisory_unlock($1)", lockKey("master"))
	if err == nil {
		t.Fatal("schema lock bypassed")
	}
	if result := apply(t, f, pending); result.Applied != 0 {
		t.Fatal("lock recovery reapplied migrations")
	}
}

func TestPostgresUnmanagedSchemaRefused(t *testing.T) {
	f := fixture(t, "platform")
	mustExec(t, f.Deploy, "CREATE SCHEMA master")
	if _, err := Run(context.Background(), f.DSN, f.Plan, true, quiet); err == nil {
		t.Fatal("unmanaged schema adopted")
	}
	if integer(t, f.Admin, "SELECT count(*) FROM pg_namespace WHERE nspname='erp_migration'") != 0 {
		t.Fatal("failed preflight changed database")
	}
}

func TestPostgresFiscalPeriodFunction(t *testing.T) {
	f := fixture(t, "finance")
	apply(t, f, f.Plan)
	insert := fmt.Sprintf("INSERT INTO accounting.fiscal_periods (tenant_guid,legal_entity_guid,period_start,period_end,status,created_by,updated_by) VALUES ('%s','%s',$1::date,$2::date,'OPEN','%s','%s')", tenant, entity, actor, actor)
	expectCode(t, f.Runtime, insert, "25000", "2026-01-01", "2026-01-31")
	tx, err := f.Runtime.BeginTx(context.Background(), pgx.TxOptions{IsoLevel: pgx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = tx.Exec(context.Background(), insert, "2026-01-01", "2026-01-31"); err != nil {
		t.Fatal(err)
	}
	if err = tx.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
	tx, err = f.Runtime.BeginTx(context.Background(), pgx.TxOptions{IsoLevel: pgx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	_, err = tx.Exec(context.Background(), insert, "2026-01-15", "2026-02-01")
	rollback(tx)
	if errorCode(err) != "23514" {
		t.Fatalf("overlap allowed: %v", err)
	}
	// Two SERIALIZABLE transactions inspect the same empty range before commit.
	cfg, _ := pgx.ParseConfig(f.RuntimeDSN)
	other := connect(t, cfg)
	a, err := f.Runtime.BeginTx(context.Background(), pgx.TxOptions{IsoLevel: pgx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer rollback(a)
	b, err := other.BeginTx(context.Background(), pgx.TxOptions{IsoLevel: pgx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer rollback(b)
	if _, err = a.Exec(context.Background(), insert, "2026-03-01", "2026-03-31"); err != nil {
		t.Fatal(err)
	}
	if _, err = b.Exec(context.Background(), insert, "2026-03-15", "2026-04-01"); err != nil {
		t.Fatal(err)
	}
	if err = a.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
	if err = b.Commit(context.Background()); errorCode(err) != "40001" {
		t.Fatalf("expected serialization rejection: %v", err)
	}
	if integer(t, f.Runtime, "SELECT count(*) FROM accounting.fiscal_periods WHERE period_start >= '2026-03-01'") != 1 {
		t.Fatal("concurrent overlapping periods committed")
	}
}

func TestPostgresRoleMembershipAndDefaultPrivileges(t *testing.T) {
	f := fixture(t, "platform")
	role := pgx.Identifier{f.Plan.Owner.RuntimeRole}.Sanitize()
	mustExec(t, f.Admin, "GRANT pg_read_all_data TO "+role)
	_, err := Run(context.Background(), f.DSN, f.Plan, true, quiet)
	mustExec(t, f.Admin, "REVOKE pg_read_all_data FROM "+role)
	if err == nil {
		t.Fatal("runtime with inherited cluster privileges accepted")
	}
	apply(t, f, f.Plan)
	mustExec(t, f.Deploy, "CREATE FUNCTION master.future_fixture() RETURNS int LANGUAGE sql AS 'SELECT 1'")
	if integer(t, f.Admin, `SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace, LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a WHERE n.nspname='master' AND p.proname='future_fixture' AND a.grantee=0 AND a.privilege_type='EXECUTE'`) != 0 {
		t.Fatal("future function inherited PUBLIC execute")
	}
	expectCode(t, f.Runtime, "SELECT master.future_fixture()", "42501")
}
