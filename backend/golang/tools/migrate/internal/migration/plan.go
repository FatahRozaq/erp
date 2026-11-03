package migration

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

type Manifest struct {
	Version int              `json:"version"`
	Owners  map[string]Owner `json:"owners"`
}
type Owner struct {
	Database    string   `json:"database"`
	DeployRole  string   `json:"deploy_role"`
	RuntimeRole string   `json:"runtime_role"`
	Schemas     []Schema `json:"schemas"`
}
type Schema struct {
	Name      string   `json:"name"`
	DependsOn []string `json:"depends_on"`
}
type File struct {
	Schema   string
	Version  int64
	Name     string
	Checksum string
	SQL      string
}
type Plan struct {
	Owner   Owner
	Schemas []string // dependency order
	Files   []File
}

var identifier = regexp.MustCompile(`^[a-z][a-z0-9_]{0,62}$`)
var migrationName = regexp.MustCompile(`^([0-9]{6})_[a-z][a-z0-9_]*\.up\.sql$`)

// Load validates the complete manifest before reading immutable SQL into memory.
func Load(root, ownerName string) (Plan, error) {
	var p Plan
	data, err := os.ReadFile(filepath.Join(root, "plan.json"))
	if err != nil {
		return p, fmt.Errorf("read migration manifest: %w", err)
	}
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	var manifest Manifest
	if err := decoder.Decode(&manifest); err != nil {
		return p, fmt.Errorf("invalid migration manifest: %w", err)
	}
	if decoder.Decode(new(any)) != io.EOF {
		return p, fmt.Errorf("trailing manifest data")
	}
	if manifest.Version != 1 || len(manifest.Owners) == 0 {
		return p, fmt.Errorf("unsupported or empty manifest")
	}
	seen := map[string]bool{}
	for name, owner := range manifest.Owners {
		if !identifier.MatchString(name) || !identifier.MatchString(owner.Database) || !identifier.MatchString(owner.DeployRole) || !identifier.MatchString(owner.RuntimeRole) || owner.DeployRole == owner.RuntimeRole {
			return p, fmt.Errorf("invalid owner configuration")
		}
		if _, err := orderedSchemas(owner.Schemas); err != nil {
			return p, err
		}
		for _, schema := range owner.Schemas {
			if seen[schema.Name] {
				return p, fmt.Errorf("schema %s has multiple owners", schema.Name)
			}
			seen[schema.Name] = true
		}
	}
	directories, err := os.ReadDir(filepath.Join(root, "migrations"))
	if err != nil {
		return p, fmt.Errorf("read migration directories: %w", err)
	}
	for _, directory := range directories {
		if !directory.IsDir() || !seen[directory.Name()] {
			return p, fmt.Errorf("unregistered migration directory: %s", directory.Name())
		}
	}
	owner, ok := manifest.Owners[ownerName]
	if !ok {
		return p, fmt.Errorf("unknown owner %q", ownerName)
	}
	p.Owner = owner
	p.Schemas, _ = orderedSchemas(owner.Schemas)
	for _, schema := range p.Schemas {
		directory := filepath.Join(root, "migrations", schema)
		info, err := os.Lstat(directory)
		if err != nil || !info.IsDir() {
			return p, fmt.Errorf("schema directory unavailable: %s", schema)
		}
		entries, err := os.ReadDir(directory)
		if err != nil {
			return p, fmt.Errorf("read schema %s: %w", schema, err)
		}
		var version int64
		for _, entry := range entries { // ReadDir sorts filenames.
			if strings.HasSuffix(entry.Name(), ".down.sql") {
				continue
			}
			match := migrationName.FindStringSubmatch(entry.Name())
			if match == nil || !entry.Type().IsRegular() {
				return p, fmt.Errorf("invalid migration file in %s: %s", schema, entry.Name())
			}
			n, _ := strconv.ParseInt(match[1], 10, 64)
			if n != version+1 {
				return p, fmt.Errorf("non-contiguous or duplicate migration version in %s: %d", schema, n)
			}
			version = n
			data, err := os.ReadFile(filepath.Join(directory, entry.Name()))
			if err != nil {
				return p, err
			}
			if err := validateSQL(string(data)); err != nil {
				return p, fmt.Errorf("%s/%s: %w", schema, entry.Name(), err)
			}
			hash := sha256.Sum256(data)
			p.Files = append(p.Files, File{schema, n, entry.Name(), hex.EncodeToString(hash[:]), string(data)})
		}
		if version == 0 {
			return p, fmt.Errorf("empty migration schema: %s", schema)
		}
	}
	return p, nil
}

func orderedSchemas(schemas []Schema) ([]string, error) {
	if len(schemas) == 0 {
		return nil, fmt.Errorf("owner has no schemas")
	}
	byName := map[string]Schema{}
	for _, s := range schemas {
		if !identifier.MatchString(s.Name) || s.Name == "erp_migration" || s.Name == "public" {
			return nil, fmt.Errorf("invalid schema name")
		}
		if _, found := byName[s.Name]; found {
			return nil, fmt.Errorf("duplicate schema %s", s.Name)
		}
		byName[s.Name] = s
	}
	state := map[string]int{}
	var result []string
	var visit func(string) error
	visit = func(name string) error {
		s, ok := byName[name]
		if !ok {
			return fmt.Errorf("unknown dependency %s", name)
		}
		if state[name] == 1 {
			return fmt.Errorf("schema dependency cycle at %s", name)
		}
		if state[name] == 2 {
			return nil
		}
		state[name] = 1
		deps := append([]string(nil), s.DependsOn...)
		sort.Strings(deps)
		for _, dep := range deps {
			if err := visit(dep); err != nil {
				return err
			}
		}
		state[name] = 2
		result = append(result, name)
		return nil
	}
	names := make([]string, 0, len(byName))
	for name := range byName {
		names = append(names, name)
	}
	sort.Strings(names)
	for _, name := range names {
		if err := visit(name); err != nil {
			return nil, err
		}
	}
	return result, nil
}
