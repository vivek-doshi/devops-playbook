$ErrorActionPreference = 'Stop'

param(
  [string]$Bump = 'PATCH',
  [string]$Message = 'Release'
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

$latest = (git tag --sort=-version:refname | Select-Object -First 1)
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

if ([string]::IsNullOrWhiteSpace($latest)) {
  $latest = 'v0.0.0'
}

$version = $latest.TrimStart('v')
$parts = $version.Split('.')

if ($parts.Count -ne 3) {
  Write-Error "Latest tag '$latest' is not a valid SemVer tag (expected vMAJOR.MINOR.PATCH)."
  exit 1
}

try {
  $major = [int]$parts[0]
  $minor = [int]$parts[1]
  $patch = [int]$parts[2]
}
catch {
  Write-Error "Latest tag '$latest' is not a valid numeric SemVer tag."
  exit 1
}

switch ($Bump.ToUpperInvariant()) {
  'MAJOR' {
    $major += 1
    $minor = 0
    $patch = 0
  }
  'MINOR' {
    $minor += 1
    $patch = 0
  }
  'PATCH' {
    $patch += 1
  }
  default {
    Write-Host "Usage: .\scripts\tag-release.ps1 [MAJOR|MINOR|PATCH] [optional-message]"
    exit 1
  }
}

$newTag = "v$major.$minor.$patch"
Write-Host "Tagging: $latest -> $newTag"

Invoke-Native {
  git tag -a $newTag -m "$Message $newTag"
}

Invoke-Native {
  git push origin $newTag
}

Write-Host "Tagged and pushed $newTag"