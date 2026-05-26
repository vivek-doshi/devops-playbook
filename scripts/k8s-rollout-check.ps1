$ErrorActionPreference = 'Stop'

param(
  [string]$Namespace,
  [string]$Deployment,
  [int]$Timeout = 120
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

if ([string]::IsNullOrWhiteSpace($Namespace) -or [string]::IsNullOrWhiteSpace($Deployment)) {
  Write-Host "Usage: .\scripts\k8s-rollout-check.ps1 <namespace> <deployment-name> [timeout-seconds]"
  exit 1
}

Write-Host "Waiting for rollout: $Deployment in namespace $Namespace (timeout: ${Timeout}s)"

Invoke-Native {
  kubectl rollout status "deployment/$Deployment" --namespace $Namespace --timeout "${Timeout}s"
}

Write-Host "Rollout complete: $Deployment"

Invoke-Native {
  kubectl get pods -n $Namespace -l "app=$Deployment"
}