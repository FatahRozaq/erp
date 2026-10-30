#!/usr/bin/env python3
"""Validate canonical OpenAPI documents and event examples without credentials."""
import json
from pathlib import Path

import yaml
from jsonschema import Draft202012Validator
from openapi_spec_validator import validate_spec

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    specs = sorted((ROOT / "contracts/openapi").rglob("*.yaml"))
    schemas = sorted((ROOT / "contracts/events").rglob("v*.json"))
    examples = sorted((ROOT / "contracts/events/examples").glob("*.json"))
    assert len(specs) >= 16, f"expected at least 16 OpenAPI specs; found {len(specs)}"
    assert len(schemas) == len(examples) and len(schemas) >= 43, "event schemas/examples differ or baseline shrank"
    for spec in specs:
        validate_spec(yaml.safe_load(spec.read_text()))
    by_title = {}
    for path in schemas:
        schema = json.loads(path.read_text())
        Draft202012Validator.check_schema(schema)
        title = schema.get("title")
        assert title and title not in by_title, f"duplicate/missing event title: {path}"
        by_title[title] = schema
    for path in examples:
        payload = json.loads(path.read_text())
        # Event type is the canonical key in the envelope and schema title.
        event_type = payload.get("type")
        assert event_type in by_title, f"no schema for {path}: {event_type}"
        Draft202012Validator(by_title[event_type]).validate(payload)
    print(f"Validated {len(specs)} OpenAPI specs, {len(schemas)} event schemas, {len(examples)} examples")


if __name__ == "__main__":
    main()
