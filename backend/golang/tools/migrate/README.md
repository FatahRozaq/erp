# ERP migration deploy tool

Independent Go 1.25.10 module. This executable is an operational tool; APIs and workers do not import it or run migrations on startup. SQL, schema ownership and dependency order live in `backend/database/plan.json` and `backend/database/migrations/<schema>/`.

From repository root:

```sh
(cd backend/golang/tools/migrate && go build -o /tmp/erp-migrate ./cmd/migrate)
# Supply the selected owner's deploy connection via ERP_MIGRATION_DSN.
/tmp/erp-migrate -owner platform -action status
/tmp/erp-migrate -owner platform -action apply -timeout 2m
```

`status` checks the complete applied history and lists pending files without writing database objects. `apply` runs all schemas for one owner in dependency order. Both validate the database, PostgreSQL major version and deploy/runtime roles. They acquire all schema locks for the owner on a dedicated connection. `-dir` defaults to `backend/database`; use an explicit path when outside the repository root. Exit 0 means the requested action succeeded; 1 means plan/database/migration failure; 2 means invalid arguments or missing connection configuration. JSON logs exclude DSNs, SQL text, query parameters, and PostgreSQL error messages/details; failures include SQLSTATE where available.

Only contiguous six-digit `*.up.sql` versions starting at 000001 are applied. Optional `*.down.sql` files are never executed. Transaction control and session identity/parser changes are rejected. This runner supports transactional migrations only; online operations such as `CREATE INDEX CONCURRENTLY` require a separately designed deployment path. Do not put them in these files.

Run local unit/manifest checks with `go test ./...`. To run PostgreSQL integration tests, first provision the disposable cluster as described in the [migration runbook](../../../../docs/operations/database-migrations.md), then set `ERP_MIGRATION_TEST_DSN` to its **administrator** connection. Tests create uniquely named `erp_b021_*` databases and remove only those databases during cleanup. PostgreSQL 18 `pg_dump` and `pg_restore` clients must be on PATH. The bootstrap creates synthetic `erp_local_only` passwords for test deploy/runtime accounts. Integration tests explicitly skip if the test DSN is absent; that skip is not migration proof.

```sh
ERP_MIGRATION_TEST_DSN='postgres://erp_local:erp_local_only@127.0.0.1:15432/erp_local?sslmode=disable' \
  go test -v -count=1 -timeout=3m ./...
go vet ./...
```

See [ADR-0007](../../../../docs/adr/0007-migration-runner.md) for consistency, privilege and recovery decisions. Function business workflows, JetStream and backup scheduling are separate slices.
