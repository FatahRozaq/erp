package migration

import (
	"fmt"
	"regexp"
	"strings"
)

var dollarTag = regexp.MustCompile(`^\$(?:[A-Za-z_][A-Za-z0-9_]*)?\$`)

// validateSQL keeps transaction ownership in the runner. It skips quoted bodies,
// identifiers and nested comments, so PL/pgSQL BEGIN/END remain valid.
// Files are trusted, reviewed deployment code, not user-supplied SQL.
func validateSQL(sql string) error {
	var words []string
	statements := 0
	check := func() error {
		if len(words) == 0 {
			return nil
		}
		statements++
		switch words[0] {
		case "BEGIN", "START", "COMMIT", "END", "ROLLBACK", "ABORT", "SAVEPOINT", "RELEASE", "PREPARE":
			return fmt.Errorf("explicit transaction control is forbidden")
		}
		if words[0] == "SET" {
			for _, word := range words[1:] {
				if word == "ROLE" || word == "AUTHORIZATION" || word == "STANDARD_CONFORMING_STRINGS" {
					return fmt.Errorf("session identity/parser changes are forbidden")
				}
			}
		}
		words = nil
		return nil
	}
	for i := 0; i < len(sql); {
		switch {
		case strings.HasPrefix(sql[i:], "--"):
			end := strings.IndexByte(sql[i:], '\n')
			if end < 0 {
				i = len(sql)
			} else {
				i += end + 1
			}
		case strings.HasPrefix(sql[i:], "/*"):
			i += 2
			depth := 1
			for i < len(sql) && depth > 0 {
				if strings.HasPrefix(sql[i:], "/*") {
					depth++
					i += 2
				} else if strings.HasPrefix(sql[i:], "*/") {
					depth--
					i += 2
				} else {
					i++
				}
			}
			if depth != 0 {
				return fmt.Errorf("unterminated SQL comment")
			}
		case sql[i] == '\'' || sql[i] == '"':
			quote := sql[i]
			escape := quote == '\'' && i > 0 && (sql[i-1] == 'E' || sql[i-1] == 'e')
			i++
			closed := false
			for i < len(sql) {
				if escape && sql[i] == '\\' {
					i += 2
					continue
				}
				if sql[i] == quote {
					if i+1 < len(sql) && sql[i+1] == quote {
						i += 2
						continue
					}
					i++
					closed = true
					break
				}
				i++
			}
			if !closed {
				return fmt.Errorf("unterminated SQL quote")
			}
		case sql[i] == '$' && dollarTag.FindString(sql[i:]) != "":
			tag := dollarTag.FindString(sql[i:])
			i += len(tag)
			end := strings.Index(sql[i:], tag)
			if end < 0 {
				return fmt.Errorf("unterminated SQL body")
			}
			i += end + len(tag)
		case sql[i] == ';':
			if err := check(); err != nil {
				return err
			}
			i++
		case (sql[i] >= 'a' && sql[i] <= 'z') || (sql[i] >= 'A' && sql[i] <= 'Z') || sql[i] == '_':
			start := i
			for i < len(sql) && ((sql[i] >= 'a' && sql[i] <= 'z') || (sql[i] >= 'A' && sql[i] <= 'Z') || (sql[i] >= '0' && sql[i] <= '9') || sql[i] == '_') {
				i++
			}
			if len(words) < 4 {
				words = append(words, strings.ToUpper(sql[start:i]))
			}
		default:
			i++
		}
	}
	if err := check(); err != nil {
		return err
	}
	if statements == 0 {
		return fmt.Errorf("empty SQL migration")
	}
	return nil
}
