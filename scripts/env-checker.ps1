$ErrorActionPreference = 'Stop'

param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$RequiredVars
)

if (-not $RequiredVars -or $RequiredVars.Count -eq 0) {
  Write-Host "Usage: .\scripts\env-checker.ps1 VAR1 VAR2 ..."
  exit 1
}

$missing = @()
foreach ($varName in $RequiredVars) {
  $value = [Environment]::GetEnvironmentVariable($varName)
  if ([string]::IsNullOrEmpty($value)) {
    $missing += $varName
  }
}

if ($missing.Count -gt 0) {
  Write-Host "Missing required environment variables:"
  foreach ($varName in $missing) {
    Write-Host "  - $varName"
  }
  exit 1
}

Write-Host "All required environment variables are set."
