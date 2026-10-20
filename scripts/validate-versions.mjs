import { readFileSync } from "node:fs";

const versions = Object.fromEntries(
  readFileSync("versions.yaml", "utf8")
    .split(/\r?\n/)
    .map((line) => line.match(/^([a-z_]+):\s*"?([^"#\s]+)"?/))
    .filter(Boolean)
    .map((match) => [match[1], match[2]]),
);

const required = [
  ["local-dev/kind/kind-config.yaml", `kindest/node:v${versions.kubernetes}.0`],
  ["terraform/aws-eks/variables.tf", `default     = "${versions.kubernetes}"`],
  ["terraform/azure-aks/variables.tf", `default     = "${versions.kubernetes}"`],
  [".github/workflows/repo-quality.yml", `--kubernetes-version ${versions.kubernetes}.0`],
  [".github/workflows/repo-quality.yml", `KUBECONFORM_VERSION: ${versions.kubeconform ?? "0.6.7"}`],
];

const failures = required.filter(([file, expected]) => !readFileSync(file, "utf8").includes(expected));
if (failures.length) {
  for (const [file, expected] of failures) console.error(`${file}: expected ${expected}`);
  process.exit(1);
}
console.log("Version contract passed.");
