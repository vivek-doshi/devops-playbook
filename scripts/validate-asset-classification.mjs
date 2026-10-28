import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";

const files = execFileSync("git", ["ls-files", "cd", "terraform", "observability", "policy", "secops", "ci", "ci-security"], { encoding: "utf8" }).split(/\r?\n/).filter((path) => /\.(md|tf|ya?ml)$/.test(path));
const failures = [];
for (const file of files) {
  const text = readFileSync(file, "utf8");
  if (/MATURITY:\s*Stable/i.test(text)) failures.push(`${file}: Stable is not valid for a reference template`);
  if (/MATURITY:\s*Template/i.test(text) && !/SUPPORT:\s*template/i.test(text)) failures.push(`${file}: template maturity requires SUPPORT: template`);
}
if (failures.length) { console.error(failures.join("\n")); process.exit(1); }
console.log("Asset classification contract passed.");
