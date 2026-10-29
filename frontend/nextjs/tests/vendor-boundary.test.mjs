import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const manifest = JSON.parse(
  readFileSync(new URL("../vendor-manifest.json", import.meta.url)),
);
test("unlicensed Metronic source is absent", () => {
  assert.equal(manifest.status, "not-acquired");
  assert.deepEqual(manifest.imported_files, []);
});
