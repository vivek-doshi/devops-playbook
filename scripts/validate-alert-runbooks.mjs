import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

const root = "observability/prometheus";
const files = [];
function walk(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) walk(path);
    else if (/\.ya?ml$/.test(entry.name)) files.push(path);
  }
}
walk(root);

const prefix = "https://github.com/vivek-doshi/cicd-reference/blob/main/";
const failures = [];
for (const file of files) {
  for (const [index, line] of readFileSync(file, "utf8").split(/\r?\n/).entries()) {
    const match = line.match(/^\s*runbook_url:\s*["']?([^\s"']+)/);
    if (!match) continue;
    const url = match[1];
    if (!url.startsWith(prefix) || !existsSync(url.slice(prefix.length))) {
      failures.push(`${file}:${index + 1}: invalid or placeholder runbook_url ${url}`);
    }
  }
}
if (failures.length) {
  console.error(failures.join("\n"));
  process.exit(1);
}
console.log(`Validated ${files.length} Prometheus assets and their runbook links.`);
