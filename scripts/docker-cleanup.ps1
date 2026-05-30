$ErrorActionPreference = 'Stop'

param(
  [switch]$DryRun
)

function Invoke-Native {
  param(
    [Parameter(Mandatory = $true)]
    [scriptblock]$Command
  )

  & $Command
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

if ($DryRun) {
  Write-Host "=== DRY RUN - nothing will be deleted ==="
  Invoke-Native { docker system df }
  exit 0
}

Write-Host "Removing stopped containers..."
Invoke-Native { docker container prune -f }

Write-Host "Removing unused images..."
Invoke-Native { docker image prune -f }

Write-Host "Removing unused volumes..."
Invoke-Native { docker volume prune -f }

Write-Host "Removing unused networks..."
Invoke-Native { docker network prune -f }

Write-Host "=== Space freed ==="
Invoke-Native { docker system df }