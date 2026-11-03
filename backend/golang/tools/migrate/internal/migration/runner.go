package migration

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"fmt"
	"log/slog"
	"sort"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type Result struct{ Applied, Pending int }
type historyKey struct {
	Schema  string
	Version int64
}
type historyRow struct{ Name, Checksum string }

// Run owns a dedicated connection; closing it releases every session lock even
// after cancellation. Runtime services never import or invoke this tool.
func Run(ctx context.Context, dsn string, plan Plan, apply bool, logger *slog.Logger) (Result, error) {
	var result Result
	config, err := pgx.ParseConfig(dsn)
	if err != nil {
		return result, fmt.Errorf("invalid migration connection configuration")
	}
	config.RuntimeParams["application_name"] = "erp-migrate"
	config.RuntimeParams["search_path"] = "pg_catalog"
	config.RuntimeParams["standard_conforming_strings"] = "on"
	conn, err := pgx.ConnectConfig(ctx, config)
	if err != nil {
		return result, safeError("connect", err)
	}
	defer func() {
		closeCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = conn.Close(closeCtx)
	}()
	if err = checkRole(ctx, conn, plan.Owner); err != nil {
		return result, err
	}
	locks := append([]string(nil), plan.Schemas...)
	sort.Strings(locks)
	for _, schema := range locks {
		if err = lock(ctx, conn, schema); err != nil {
			return result, err
		}
	}
	var exists bool
	if err = conn.QueryRow(ctx, "SELECT to_regclass('erp_migration.history') IS NOT NULL").Scan(&exists); err != nil {
		return result, safeError("inspect ledger", err)
	}
	history := map[historyKey]historyRow{}
	if exists {
		rows, err := conn.Query(ctx, "SELECT schema_name, version, name, checksum FROM erp_migration.history ORDER BY schema_name, version")
		if err != nil {
			return result, safeError("read ledger", err)
		}
		for rows.Next() {
			var k historyKey
			var v historyRow
			if err = rows.Scan(&k.Schema, &k.Version, &v.Name, &v.Checksum); err != nil {
				rows.Close()
				return result, safeError("read ledger row", err)
			}
			history[k] = v
		}
		err = rows.Err()
		rows.Close()
		if err != nil {
			return result, safeError("read ledger", err)
		}
	}
	if err = verifyHistory(plan, history); err != nil {
		return result, err
	}
	// Never silently adopt tables created outside this ledger. The one legacy
	// finance schema creation is explained by accounting/1's committed checksum.
	for _, schema := range plan.Schemas {
		if _, ok := history[historyKey{schema, 1}]; ok {
			continue
		}
		var schemaExists bool
		if err = conn.QueryRow(ctx, "SELECT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname=$1)", schema).Scan(&schemaExists); err != nil {
			return result, safeError("inspect schema", err)
		}
		_, legacyFinance := history[historyKey{"accounting", 1}]
		if schemaExists && !(schema == "finance" && legacyFinance) {
			return result, fmt.Errorf("unmanaged schema %s: explicit reconciliation required", schema)
		}
	}
	if apply && !exists {
		if err = initialize(ctx, conn); err != nil {
			return result, err
		}
	}
	for _, file := range plan.Files {
		if _, ok := history[historyKey{file.Schema, file.Version}]; ok {
			continue
		}
		result.Pending++
		if !apply {
			logger.Info("migration_pending", "schema", file.Schema, "version", file.Version, "checksum", file.Checksum)
			continue
		}
		started := time.Now()
		logger.Info("migration_started", "schema", file.Schema, "version", file.Version, "checksum", file.Checksum)
		if err = applyFile(ctx, conn, file); err != nil {
			logger.Error("migration_failed", "schema", file.Schema, "version", file.Version, "error_code", errorCode(err), "duration_ms", time.Since(started).Milliseconds())
			return result, fmt.Errorf("%s/%s: %w", file.Schema, file.Name, safeError("apply", err))
		}
		result.Applied++
		result.Pending--
		logger.Info("migration_applied", "schema", file.Schema, "version", file.Version, "duration_ms", time.Since(started).Milliseconds())
	}
	return result, nil
}

func checkRole(ctx context.Context, conn *pgx.Conn, owner Owner) error {
	var database, user, session string
	var version int
	err := conn.QueryRow(ctx, "SELECT current_database(),current_user,session_user,current_setting('server_version_num')::int").Scan(&database, &user, &session, &version)
	if err != nil {
		return safeError("inspect connection", err)
	}
	if database != owner.Database || user != owner.DeployRole || session != owner.DeployRole {
		return fmt.Errorf("database/session role does not match selected owner deploy role")
	}
	if version < 180000 || version >= 190000 {
		return fmt.Errorf("PostgreSQL 18 is required")
	}
	for _, role := range []string{owner.DeployRole, owner.RuntimeRole} {
		var unsafe bool
		err = conn.QueryRow(ctx, "SELECT rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls OR EXISTS (SELECT 1 FROM pg_auth_members WHERE member=r.oid) FROM pg_roles r WHERE rolname=$1", role).Scan(&unsafe)
		if err != nil {
			return safeError("inspect required role", err)
		}
		if unsafe {
			return fmt.Errorf("privileged role is forbidden: %s", role)
		}
	}
	var inherits, create, temp bool
	err = conn.QueryRow(ctx, "SELECT pg_has_role($1,$2,'MEMBER'),has_database_privilege($1,current_database(),'CREATE'),has_database_privilege($1,current_database(),'TEMP')", owner.RuntimeRole, owner.DeployRole).Scan(&inherits, &create, &temp)
	if err != nil {
		return safeError("inspect runtime privileges", err)
	}
	if inherits || create || temp {
		return fmt.Errorf("runtime role has deployment or temporary DDL privileges")
	}
	return nil
}

func lockKey(schema string) int64 {
	hash := sha256.Sum256([]byte("erp:migration:v1:" + schema))
	return int64(binary.BigEndian.Uint64(hash[:8]))
}
func lock(ctx context.Context, conn *pgx.Conn, schema string) error {
	ticker := time.NewTicker(50 * time.Millisecond)
	defer ticker.Stop()
	for {
		var acquired bool
		if err := conn.QueryRow(ctx, "SELECT pg_try_advisory_lock($1)", lockKey(schema)).Scan(&acquired); err != nil {
			return safeError("acquire schema lock", err)
		}
		if acquired {
			return nil
		}
		select {
		case <-ctx.Done():
			return fmt.Errorf("schema lock timeout/cancellation: %s", schema)
		case <-ticker.C:
		}
	}
}

func verifyHistory(plan Plan, history map[historyKey]historyRow) error {
	files := map[historyKey]File{}
	for _, f := range plan.Files {
		files[historyKey{f.Schema, f.Version}] = f
	}
	for key, row := range history {
		file, ok := files[key]
		if !ok || file.Checksum != row.Checksum || file.Name != row.Name {
			return fmt.Errorf("history mismatch for %s/%d: missing, renamed or modified migration", key.Schema, key.Version)
		}
		if key.Version > 1 {
			if _, ok := history[historyKey{key.Schema, key.Version - 1}]; !ok {
				return fmt.Errorf("ledger version gap for %s/%d", key.Schema, key.Version)
			}
		}
	}
	return nil
}

const ledgerSQL = `
CREATE SCHEMA erp_migration;
REVOKE ALL ON SCHEMA erp_migration FROM PUBLIC;
CREATE TABLE erp_migration.history (
 schema_name text NOT NULL,
 version bigint NOT NULL CHECK (version > 0),
 name text NOT NULL,
 checksum text NOT NULL CHECK (checksum ~ '^[a-f0-9]{64}$'),
 applied_at timestamptz NOT NULL DEFAULT statement_timestamp(),
 applied_by name NOT NULL DEFAULT current_user,
 duration_ms bigint NOT NULL CHECK (duration_ms >= 0),
 PRIMARY KEY (schema_name, version)
);
REVOKE ALL ON erp_migration.history FROM PUBLIC;
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
`

func initialize(ctx context.Context, conn *pgx.Conn) error {
	tx, err := conn.Begin(ctx)
	if err != nil {
		return safeError("begin ledger", err)
	}
	defer rollback(tx)
	if _, err = tx.Exec(ctx, ledgerSQL); err != nil {
		return safeError("initialize ledger", err)
	}
	if err = tx.Commit(ctx); err != nil {
		return safeError("commit ledger", err)
	}
	return nil
}
func applyFile(ctx context.Context, conn *pgx.Conn, file File) error {
	tx, err := conn.Begin(ctx)
	if err != nil {
		return err
	}
	defer rollback(tx)
	started := time.Now()
	if _, err = tx.Exec(ctx, file.SQL); err != nil {
		return err
	}
	if _, err = tx.Exec(ctx, "INSERT INTO erp_migration.history (schema_name,version,name,checksum,duration_ms) VALUES ($1,$2,$3,$4,$5)", file.Schema, file.Version, file.Name, file.Checksum, time.Since(started).Milliseconds()); err != nil {
		return err
	}
	return tx.Commit(ctx)
}
func rollback(tx pgx.Tx) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = tx.Rollback(ctx)
}
func errorCode(err error) string {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		return pgErr.Code
	}
	if errors.Is(err, context.DeadlineExceeded) {
		return "TIMEOUT"
	}
	if errors.Is(err, context.Canceled) {
		return "CANCELED"
	}
	return "CONNECTION_OR_INTERNAL"
}

// Do not propagate PostgreSQL DETAIL/MESSAGE, SQL, DSN or parameters to logs.
func safeError(stage string, err error) error {
	return fmt.Errorf("%s failed (%s)", stage, errorCode(err))
}
