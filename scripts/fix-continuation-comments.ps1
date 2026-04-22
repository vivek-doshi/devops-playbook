$ErrorActionPreference = 'Stop'

$files = Get-ChildItem -Recurse -File | Where-Object {
  $p = $_.FullName.ToLower()
  if ($p -match '\\.git\\') { return $false }
  if ($p -match '\\node_modules\\') { return $false }
  if ($p -match '\\dist\\') { return $false }
  return $_.Name -like 'Dockerfile*' -or $_.Extension -eq '.sh'
}

Write-Host "Scanning $($files.Count) file(s)..."

$totalRemoved = 0
$editedFiles = 0

foreach ($f in $files) {
  $bytes = [IO.File]::ReadAllBytes($f.FullName)
  $ms = New-Object IO.MemoryStream(,$bytes)
  $sr = New-Object IO.StreamReader($ms, $true)
  $text = $sr.ReadToEnd()
  $enc = $sr.CurrentEncoding
  $sr.Close()
  $ms.Close()

  $eol = if ($text -match "`r`n") { "`r`n" } else { "`n" }
  $lines = $text -split "`r?`n", -1
  $out = New-Object System.Collections.Generic.List[string]
  $removed = 0

  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($out.Count -gt 0) {
      $trimPrev = $out[$out.Count - 1].TrimEnd()
      $trimCurr = $lines[$i].Trim()
      if ($trimPrev.EndsWith('\') -and $trimCurr.StartsWith('#')) {
        $removed++
        continue
      }
    }
    $out.Add($lines[$i])
  }

  if ($removed -gt 0) {
    $newText = [string]::Join($eol, $out)
    [IO.File]::WriteAllText($f.FullName, $newText, $enc)
    $editedFiles++
    $totalRemoved += $removed
    $rel = $f.FullName.Replace("$PWD\", '')
    Write-Host "  $rel -- removed $removed comment(s)"
  }
}

Write-Host ""
Write-Host "Files edited : $editedFiles"
Write-Host "Lines removed: $totalRemoved"
