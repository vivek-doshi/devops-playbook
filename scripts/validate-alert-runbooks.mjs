import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

const roots = ["observability/prometheus", "observability/loki", "finops/prometheus"];
const prefix = "https://github.com/vivek-doshi/cicd-reference/blob/main/";
const files = [];
function walk(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) walk(path);
    else if (/\.ya?ml$/.test(entry.name)) files.push(path);
  }
}
roots.forEach(walk);
const failures = [];
for (const file of files) {
  const text = readFileSync(file, "utf8");
  const alerts = [...text.matchAll(/^\s*-\s+alert:\s*([^\s#]+)/gm)];
  for (const [index, alert] of alerts.entries()) {
    const body = text.slice(alert.index, alerts[index + 1]?.index);
    const url = body.match(/^\s*runbook_url:\s*["']?([^\s"']+)/m)?.[1];
    if (!url) failures.push(`${file}: alert ${alert[1]} has no runbook_url`);
    else if (!url.startsWith(prefix) || !existsSync(url.slice(prefix.length).split("#")[0])) failures.push(`${file}: alert ${alert[1]} has an invalid or placeholder runbook_url ${url}`);
  }
}
if (failures.length) { console.error(failures.join("\n")); process.exit(1); }
console.log(`Validated runbooks for alerts in ${files.length} observability and FinOps assets.`);
