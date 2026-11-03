package migration

import (
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func repositoryDatabase(t *testing.T) string {
	t.Helper()
	root, err := filepath.Abs("../../../../../database")
	if err != nil {
		t.Fatal(err)
	}
	return root
}
func TestManifestAndBaselineOrder(t *testing.T) {
	total := 0
	for _, owner := range []string{"platform", "commercial", "operations", "finance"} {
		plan, err := Load(repositoryDatabase(t), owner)
		if err != nil {
			t.Fatal(err)
		}
		total += len(plan.Files)
		if owner == "finance" && !reflect.DeepEqual(plan.Schemas, []string{"finance_runtime", "accounting", "finance"}) {
			t.Fatalf("unsafe finance order: %v", plan.Schemas)
		}
	}
	if total != 21 {
		t.Fatalf("expected 11 baseline + 10 hardening migrations; got %d", total)
	}
}
func TestDependencyValidation(t *testing.T) {
	for _, schemas := range [][]Schema{
		{{Name: "a", DependsOn: []string{"b"}}, {Name: "b", DependsOn: []string{"a"}}},
		{{Name: "a", DependsOn: []string{"missing"}}},
		{{Name: "a"}, {Name: "a"}},
		{{Name: "../escape"}},
	} {
		if _, err := orderedSchemas(schemas); err == nil {
			t.Fatalf("accepted invalid graph: %v", schemas)
		}
	}
}
func copyDatabase(t *testing.T) string {
	t.Helper()
	dst := t.TempDir()
	if err := os.CopyFS(dst, os.DirFS(repositoryDatabase(t))); err != nil {
		t.Fatal(err)
	}
	return dst
}
func TestMigrationFilesFailClosed(t *testing.T) {
	t.Run("unregistered_schema", func(t *testing.T) {
		root := copyDatabase(t)
		if err := os.Mkdir(filepath.Join(root, "migrations", "unregistered"), 0700); err != nil {
			t.Fatal(err)
		}
		if _, err := Load(root, "platform"); err == nil {
			t.Fatal("unregistered schema accepted")
		}
	})
	for _, tc := range []struct{ name, file string }{
		{"duplicate", "000001_duplicate.up.sql"}, {"gap", "000004_gap.up.sql"}, {"bad_name", "new.sql"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			root := copyDatabase(t)
			if err := os.WriteFile(filepath.Join(root, "migrations/master", tc.file), []byte("SELECT 1;"), 0600); err != nil {
				t.Fatal(err)
			}
			if _, err := Load(root, "platform"); err == nil {
				t.Fatal("invalid file accepted")
			}
		})
	}
	t.Run("symlink", func(t *testing.T) {
		root := copyDatabase(t)
		if err := os.Symlink("000001_sku_uom.up.sql", filepath.Join(root, "migrations/master/000003_link.up.sql")); err != nil {
			t.Fatal(err)
		}
		if _, err := Load(root, "platform"); err == nil {
			t.Fatal("symlink accepted")
		}
	})
}
func TestSQLTransactionOwnership(t *testing.T) {
	for _, sql := range []string{
		"COMMIT;", "SELECT 1; /* outer /* inner */ comment */ END;", "rollback;", "START TRANSACTION;", "PREPARE TRANSACTION 'x';", "SET ROLE other;", "SET LOCAL ROLE other;", "SET SESSION AUTHORIZATION other;", "SET standard_conforming_strings=off;", "SELECT 'unterminated", "/* unterminated", "-- empty",
	} {
		if err := validateSQL(sql); err == nil {
			t.Fatalf("accepted unsafe SQL: %q", sql)
		}
	}
	for _, sql := range []string{
		"CREATE FUNCTION a.f() RETURNS void LANGUAGE plpgsql AS $$ BEGIN RAISE NOTICE 'COMMIT;'; END $$;",
		"DO $body$ BEGIN NULL; END $body$; SELECT 1;",
		`SELECT E'quote\'; COMMIT;'; SELECT 1;`,
		"SELECT '; COMMIT;'; -- COMMIT;\n SELECT \"COMMIT\" FROM a.b;",
	} {
		if err := validateSQL(sql); err != nil {
			t.Fatalf("valid SQL rejected: %v", err)
		}
	}
	if err := validateSQL(`SELECT E'escaped\'text'; COMMIT;`); err == nil || !strings.Contains(err.Error(), "transaction") {
		t.Fatal("transaction escape accepted")
	}
}
