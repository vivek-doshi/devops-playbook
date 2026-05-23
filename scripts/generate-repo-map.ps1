#!/usr/bin/env pwsh
param(
  [string]$RootPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$OutputPath = ".ai/context/repo_map.md",
  [string]$IgnoreFile = ".ai/context/repo_map.ignore",
  [string[]]$IgnoreFolders = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Normalize-RelPath {
  param([string]$Path)

  $normalized = $Path.Replace([char]92, [char]47).Trim()
  if ($normalized.StartsWith("./")) {
    $normalized = $normalized.Substring(2)
  }
  return $normalized.TrimEnd("/")
}

function Load-IgnoreFolders {
  param(
    [string]$Root,
    [string]$IgnoreConfig,
    [string[]]$InlineIgnores
  )

  $combined = New-Object System.Collections.Generic.List[string]
  $combined.Add(".git")

  $ignoreConfigPath = Join-Path $Root $IgnoreConfig
  if (Test-Path -LiteralPath $ignoreConfigPath) {
    foreach ($line in Get-Content -LiteralPath $ignoreConfigPath) {
      $trimmed = $line.Trim()
      if ([string]::IsNullOrWhiteSpace($trimmed)) {
        continue
      }
      if ($trimmed.StartsWith("#")) {
        continue
      }
      $combined.Add($trimmed)
    }
  }

  foreach ($item in $InlineIgnores) {
    if (-not [string]::IsNullOrWhiteSpace($item)) {
      $combined.Add($item)
    }
  }

  $normalized = $combined |
    ForEach-Object { Normalize-RelPath -Path $_ } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Sort-Object -Unique

  return $normalized
}

function Should-Ignore {
  param(
    [string]$RelativePath,
    [string[]]$Ignores
  )

  $candidate = Normalize-RelPath -Path $RelativePath
  foreach ($ignore in $Ignores) {
    if ($candidate -eq $ignore -or $candidate.StartsWith("$ignore/")) {
      return $true
    }
  }
  return $false
}

function Build-TreeLines {
  param(
    [string]$CurrentPath,
    [string]$Prefix,
    [string]$Root,
    [string[]]$Ignores
  )

  $items = Get-ChildItem -LiteralPath $CurrentPath -Force
  $items = @($items |
    Where-Object {
      $relative = $_.FullName.Substring($Root.Length).TrimStart([char[]]@([char]92, [char]47))
      $relative = Normalize-RelPath -Path $relative
      -not (Should-Ignore -RelativePath $relative -Ignores $Ignores)
    } |
    Sort-Object -Property @{ Expression = { -not $_.PSIsContainer } }, Name)

  $tee = [string][char]0x251C
  $elbow = [string][char]0x2514
  $horizontal = ([string][char]0x2500) * 2
  $vertical = [string][char]0x2502

  $lines = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $items.Count; $i++) {
    $item = $items[$i]
    $isLast = $i -eq ($items.Count - 1)
    $connector = if ($isLast) { "$elbow$horizontal" } else { "$tee$horizontal" }
    $lines.Add("$Prefix$connector $($item.Name)")

    if ($item.PSIsContainer) {
      $childPrefix = if ($isLast) { "$Prefix    " } else { "$Prefix$vertical   " }
      $childLines = Build-TreeLines -CurrentPath $item.FullName -Prefix $childPrefix -Root $Root -Ignores $Ignores
      foreach ($line in $childLines) {
        $lines.Add($line)
      }
    }
  }

  return $lines
}

$rootFullPath = (Resolve-Path -LiteralPath $RootPath).Path
Push-Location -LiteralPath $rootFullPath
try {
  $ignoreEntries = Load-IgnoreFolders -Root $rootFullPath -IgnoreConfig $IgnoreFile -InlineIgnores $IgnoreFolders
  $treeLines = Build-TreeLines -CurrentPath $rootFullPath -Prefix "" -Root $rootFullPath -Ignores $ignoreEntries

  $outputFullPath = Join-Path $rootFullPath $OutputPath
  $outputDir = Split-Path -Path $outputFullPath -Parent
  if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
  }

  $generated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $rootDisplay = $rootFullPath.Replace([char]92, [char]47).ToLowerInvariant()
  $exclusions = ($ignoreEntries | ForEach-Object { "$_/" }) -join ", "

  $content = New-Object System.Collections.Generic.List[string]
  $content.Add("# Repository Map")
  $content.Add("")
  $content.Add("Generated from current workspace structure.")
  $content.Add("")
  $content.Add("- Root: $rootDisplay")
  $content.Add("- Generated: $generated")
  $content.Add("- Exclusions: $exclusions")
  $content.Add("")
  $content.Add('```text')
  $content.Add('.')
  foreach ($line in $treeLines) {
    $content.Add($line)
  }
  $content.Add('```')

  Set-Content -LiteralPath $outputFullPath -Value $content -Encoding UTF8
  Write-Host "Updated $OutputPath"
}
finally {
  Pop-Location
}
