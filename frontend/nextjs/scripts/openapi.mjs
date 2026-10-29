import { execFileSync } from "node:child_process";
import {
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  mkdirSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const root = resolve(import.meta.dirname, "../../..");
const contracts = join(root, "contracts/openapi");
const output = join(root, "frontend/nextjs/src/generated/openapi");
const check = process.argv.includes("--check");
const target = check ? mkdtempSync(join(tmpdir(), "erp-openapi-")) : output;
mkdirSync(target, { recursive: true });
try {
  const domains = readdirSync(contracts, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
  if (check) {
    const present = readdirSync(output)
      .filter((name) => name.endsWith(".ts"))
      .sort();
    const expected = domains.map((domain) => `${domain}.ts`);
    if (JSON.stringify(present) !== JSON.stringify(expected))
      throw new Error("generated OpenAPI file inventory drift");
  }
  for (const domain of domains) {
    execFileSync(
      resolve(import.meta.dirname, "../node_modules/.bin/openapi-typescript"),
      [join(contracts, domain, "v1.yaml"), "-o", join(target, `${domain}.ts`)],
      { stdio: "pipe" },
    );
    if (check) {
      const actual = readFileSync(join(output, `${domain}.ts`), "utf8");
      const expected = readFileSync(join(target, `${domain}.ts`), "utf8");
      if (actual !== expected)
        throw new Error(`generated OpenAPI drift: ${domain}`);
    }
  }
  console.log(
    `${check ? "Checked" : "Generated"} ${domains.length} OpenAPI type files`,
  );
} finally {
  if (check) rmSync(target, { recursive: true, force: true });
}
