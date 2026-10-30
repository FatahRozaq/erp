import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const manifest = JSON.parse(
  readFileSync(new URL("../vendor-manifest.json", import.meta.url)),
);
test("shadcn-admin source is selected but not yet integrated", () => {
  assert.equal(manifest.status, "selected-not-integrated");
  assert.equal(manifest.product, "satnaing/shadcn-admin");
  assert.equal(manifest.license, "MIT");
  assert.deepEqual(manifest.imported_files, []);
});
