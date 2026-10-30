#!/usr/bin/env python3
"""Protect the 11 pre-B-01 SQL migrations while allowing additive B-02 work."""
import hashlib
from pathlib import Path

root = Path(__file__).resolve().parents[1]
manifest = root / "scripts/baseline-migration-sha256.txt"
expected = {}
for line in manifest.read_text().splitlines():
    digest, name = line.split(None, 1)
    assert name not in expected, f"duplicate manifest entry: {name}"
    expected[name] = digest
assert len(expected) == 11, f"expected 11 baseline migrations; found {len(expected)}"
for name, digest in expected.items():
    path = root / name
    assert path.is_file(), f"baseline migration missing: {name}"
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    assert actual == digest, f"baseline migration changed: {name}"
all_migrations = list((root / "backend/golang/services").glob("*/migrations/**/*.up.sql"))
assert len(all_migrations) >= len(expected), "migration inventory shrank"
print(f"Preserved {len(expected)} baseline SQL migrations; {len(all_migrations)} total")
