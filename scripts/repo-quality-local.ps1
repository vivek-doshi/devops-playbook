$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Run the repository quality gate locally with checks that mirror CI.

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $RepoRoot

function Write-Step {
  param([string]$Name)
  Write-Host ""
  Write-Host "==> $Name"
}

function Require-Command {
  param([string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Missing required command: $Name"
  }
}

function Get-NodeCmd {
  param([string]$BaseName)
  $cmd = Get-Command "$BaseName.cmd" -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $cmd = Get-Command $BaseName -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  throw "Missing required command: $BaseName"
}

Write-Step "Checking prerequisites"
Require-Command 'python'
Require-Command 'helm'
Require-Command 'terraform'
Require-Command 'yamllint'
Require-Command 'kubeconform'
Require-Command 'conftest'
$NpxCmd = Get-NodeCmd -BaseName 'npx'
$NpmCmd = Get-NodeCmd -BaseName 'npm'

Write-Step "Markdown links"
& $NpxCmd -y lychee --config .lychee.toml docs/**/*.md README.md GETTING_STARTED.md

Write-Step "Actionlint"
Require-Command 'actionlint'
actionlint -color

Write-Step "Yamllint"
yamllint -c .yamllint.yml .

Write-Step "Kubeconform"
$kubeFiles = Get-ChildItem -Path (Join-Path $RepoRoot 'cd/kubernetes') -Recurse -File -Include *.yml,*.yaml |
  Where-Object { $_.Name -notmatch 'kustomization\.ya?ml$|_test\.ya?ml$' }
if ($kubeFiles.Count -gt 0) {
  kubeconform --strict --kubernetes-version 1.29.0 --ignore-missing-schemas --summary --output pretty @($kubeFiles.FullName)
} else {
  Write-Host 'No Kubernetes manifests found under cd/kubernetes/.'
}

Write-Step "Helm lint + template"
$chartDirs = Get-ChildItem -Path (Join-Path $RepoRoot 'cd/helm') -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName 'Chart.yaml') }
if ($chartDirs.Count -eq 0) {
  Write-Host 'No Helm charts found under cd/helm/.'
} else {
  foreach ($chart in $chartDirs) {
    helm lint $chart.FullName --strict
    helm template $chart.Name $chart.FullName | kubeconform --strict --kubernetes-version 1.29.0 --ignore-missing-schemas --summary --output pretty -
  }
}

Write-Step "Terraform init/fmt/validate"
$modules = @('aws-eks', 'azure-aks', 'gcp-gke', 'aws-lambda', 'aws-ecs', 'azure-app-service')
foreach ($module in $modules) {
  Push-Location (Join-Path $RepoRoot "terraform/$module")
  terraform init -backend=false
  terraform fmt -check -recursive
  terraform validate
  Pop-Location
}

Write-Step "Conftest"
conftest test cd/kubernetes/_base/ --policy policy/conftest/kubernetes --output table
helm template webapp cd/helm/webapp/ | conftest test - --policy policy/conftest/kubernetes --output table

Write-Step "Catalog validate"
python -m pip install --quiet pyyaml
python catalog/scripts/validate-catalog.py --strict --skip-url-check

Write-Step "Website build"
if (Test-Path (Join-Path $RepoRoot 'website')) {
  & $NpmCmd --prefix website ci
  & $NpmCmd --prefix website run build
} else {
  Write-Warning 'website/ not found, skipping website build.'
}

Write-Host ""
Write-Host "Repo quality gate checks passed locally."
