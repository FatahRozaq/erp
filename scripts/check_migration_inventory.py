#!/usr/bin/env python3
"""B-01 inventory check; application and grants are B-02."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
files = sorted((root / "backend/golang/services").glob("*/migrations/**/*.up.sql"))
assert len(files) == 11, f"expected 11 baseline migrations; found {len(files)}"
assert all(path.stat().st_size for path in files), "empty migration"
print(f"Preserved {len(files)} versioned SQL migrations")
