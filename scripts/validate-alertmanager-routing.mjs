import { readFileSync } from "node:fs";

const files = ["observability/prometheus/values.yaml", "finops/prometheus/alertmanager-budget-config.yaml", "finops/prometheus/alertmanager-anomaly-config.yaml"];
const failures = [];
for (const file of files) {
  const text = readFileSync(file, "utf8");
  const receivers = new Set([...text.matchAll(/^\s*-\s+name:\s*["']?([^\s"']+)/gm)].map((m) => m[1]));
  const routes = [...text.matchAll(/^\s*receiver:\s*["']?([^\s"']+)/gm)].map((m) => m[1]);
  for (const receiver of routes) if (!receivers.has(receiver)) failures.push(`${file}: route references missing receiver ${receiver}`);
}
if (failures.length) { console.error(failures.join("\n")); process.exit(1); }
console.log("Alertmanager route/receiver contract passed.");
