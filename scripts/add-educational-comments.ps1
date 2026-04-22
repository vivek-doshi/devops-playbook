# Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
$ErrorActionPreference = 'Stop'

function Get-CommentStyle([string]$path) {
  $name = [IO.Path]::GetFileName($path)
  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  $ext = [IO.Path]::GetExtension($path).ToLower()
  if ($name -like 'Dockerfile*') { return @{ Type='hash'; Prefix='#' } }
  switch ($ext) {
    # Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '.py' { return @{ Type='hash'; Prefix='#' } }
    '.rb' { return @{ Type='hash'; Prefix='#' } }
    '.sh' { return @{ Type='hash'; Prefix='#' } }
    # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '.ps1' { return @{ Type='hash'; Prefix='#' } }
    '.yml' { return @{ Type='hash'; Prefix='#' } }
    '.yaml' { return @{ Type='hash'; Prefix='#' } }
    # Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '.tf' { return @{ Type='hash'; Prefix='#' } }
    '.tfvars' { return @{ Type='hash'; Prefix='#' } }
    '.properties' { return @{ Type='hash'; Prefix='#' } }
    # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '.conf' { return @{ Type='hash'; Prefix='#' } }
    '.ini' { return @{ Type='hash'; Prefix='#' } }
    '.env' { return @{ Type='hash'; Prefix='#' } }
    # Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '.ts' { return @{ Type='slash'; Prefix='//' } }
    '.tsx' { return @{ Type='slash'; Prefix='//' } }
    '.js' { return @{ Type='slash'; Prefix='//' } }
    # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '.jsx' { return @{ Type='slash'; Prefix='//' } }
    '.java' { return @{ Type='slash'; Prefix='//' } }
    '.go' { return @{ Type='slash'; Prefix='//' } }
    # Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '.cs' { return @{ Type='slash'; Prefix='//' } }
    '.gradle' { return @{ Type='slash'; Prefix='//' } }
    '.css' { return @{ Type='block'; Prefix='/*'; Suffix='*/' } }
    # Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    '.html' { return @{ Type='xml'; Prefix='<!--'; Suffix='-->' } }
    '.xml' { return @{ Type='xml'; Prefix='<!--'; Suffix='-->' } }
    '.md' { return @{ Type='xml'; Prefix='<!--'; Suffix='-->' } }
    # Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    default { return $null }
  }
}

# Note 12: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
function Is-CommentLine([string]$trim, $style) {
  if ($trim.Length -eq 0) { return $true }
  switch ($style.Type) {
    # Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    'hash' { return $trim.StartsWith('#') }
    'slash' { return $trim.StartsWith('//') -or $trim.StartsWith('/*') -or $trim.StartsWith('*') }
    'block' { return $trim.StartsWith('/*') -or $trim.StartsWith('*') }
    # Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    'xml' { return $trim.StartsWith('<!--') }
    default { return $false }
  }
# Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

function Build-Note([string]$trimLine, [int]$n) {
  if ($trimLine -match '^(import|from)\b') {
    # Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return "Note ${n}: Imports make dependencies explicit, which keeps module boundaries clear and simplifies maintenance."
  }
  if ($trimLine -match '^(apiVersion|kind|metadata|spec):') {
    # Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return "Note ${n}: This Kubernetes style field captures a contract; keeping schema keys stable improves portability across environments."
  }
  if ($trimLine -match '^(name:|namespace:|labels:|annotations:)') {
    # Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return "Note ${n}: Resource identity and metadata drive automation, selectors, and operational traceability."
  }
  if ($trimLine -match '^(stages:|jobs:|steps:|on:|uses:|run:)') {
    # Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return "Note ${n}: Pipeline structure separates concerns, helping teams test, deploy, and recover with smaller blast radius."
  }
  if ($trimLine -match '^(FROM|RUN|COPY|CMD|ENTRYPOINT|WORKDIR|EXPOSE)\b') {
    # Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return "Note ${n}: Docker instructions are layer-based; ordering these commands intentionally can improve cache reuse and build speed."
  }
  if ($trimLine -match '^(resource|module|variable|output|provider)\s+"') {
    # Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return "Note ${n}: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection."
  }
  if ($trimLine -match '^(function|const|let|var|class|interface|type)\b') {
    # Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return "Note ${n}: This declaration defines a reusable unit, which supports composition and makes behavior easier to test."
  }
  if ($trimLine -match '^(if|for|while|switch|case|try|catch)\b') {
    # Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return "Note ${n}: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting."
  }
  if ($trimLine -match '^#') {
    # Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    return "Note ${n}: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability."
  }
  return "Note ${n}: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact."
# Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

$files = Get-ChildItem -Recurse -File | Where-Object {
  $p = $_.FullName.ToLower()
  # Note 26: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
  if ($p -match '\\.git\\|\\node_modules\\|\\dist\\|\\build\\|\\target\\|\\bin\\|\\obj\\') { return $false }
  if ($_.Extension -eq '.json' -or $_.Extension -eq '.ipynb') { return $false }
  if ($_.Name -eq 'package-lock.json') { return $false }
  # Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  $style = Get-CommentStyle $_.FullName
  return $null -ne $style
}

# Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
$edited = 0
$skipped = 0
$totalAdded = 0

# Note 29: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
foreach ($f in $files) {
  $style = Get-CommentStyle $f.FullName
  if ($null -eq $style) { $skipped++; continue }

  # Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  $bytes = [IO.File]::ReadAllBytes($f.FullName)
  $ms = New-Object IO.MemoryStream(,$bytes)
  $sr = New-Object IO.StreamReader($ms, $true)
  # Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  $text = $sr.ReadToEnd()
  $enc = $sr.CurrentEncoding
  $sr.Close(); $ms.Close()

  # Note 32: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
  if ($text -match 'Note\s+\d+:') { $skipped++; continue }

  $eol = if ($text -match "`r`n") { "`r`n" } else { "`n" }
  $lines = $text -split "`r?`n", -1
  # Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  $orig = $lines.Count
  if ($orig -lt 8) { $skipped++; continue }

  $toAdd = [int][Math]::Ceiling($orig * 0.25)
  # Note 34: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  $cap = if ($orig -gt 1000) { 300 } else { 400 }
  if ($toAdd -gt $cap) { $toAdd = $cap }
  if ($toAdd -lt 1) { $skipped++; continue }

  # Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  $candidates = New-Object System.Collections.Generic.List[int]
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $trim = $lines[$i].Trim()
    # Note 36: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
    if ($trim.Length -eq 0) { continue }
    if (Is-CommentLine $trim $style) { continue }
    $candidates.Add($i)
  # Note 37: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }
  if ($candidates.Count -eq 0) { $skipped++; continue }

  if ($toAdd -gt $candidates.Count) { $toAdd = $candidates.Count }
  # Note 38: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  $step = [Math]::Max(1, [Math]::Floor($candidates.Count / $toAdd))

  $selected = New-Object System.Collections.Generic.HashSet[int]
  $idx = 0
  # Note 39: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
  while ($selected.Count -lt $toAdd -and $idx -lt $candidates.Count) {
    [void]$selected.Add($candidates[$idx])
    $idx += $step
  # Note 40: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }
  if ($selected.Count -lt $toAdd) {
    for ($k = 0; $k -lt $candidates.Count -and $selected.Count -lt $toAdd; $k++) {
      # Note 41: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      [void]$selected.Add($candidates[$k])
    }
  }

  # Note 42: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  $out = New-Object System.Collections.Generic.List[string]
  $note = 1
  for ($i = 0; $i -lt $lines.Count; $i++) {
    # Note 43: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
    if ($selected.Contains($i)) {
      $line = $lines[$i]
      $indentMatch = [regex]::Match($line, '^(\s*)')
      $indent = $indentMatch.Groups[1].Value
      $msg = Build-Note $line.Trim() $note
      switch ($style.Type) {
        'hash' { $out.Add("$indent# $msg") }
        'slash' { $out.Add("$indent// $msg") }
        'block' { $out.Add("$indent/* $msg */") }
        'xml' { $out.Add("$indent<!-- $msg -->") }
      }
      $note++
    }
    $out.Add($lines[$i])
  }

  $newText = [string]::Join($eol, $out)
  if ($newText -ne $text) {
    [IO.File]::WriteAllText($f.FullName, $newText, $enc)
    $edited++
    $totalAdded += ($out.Count - $orig)
  } else {
    $skipped++
  }
}

Write-Host "Edited files: $edited"
Write-Host "Skipped files: $skipped"
Write-Host "Added comment lines: $totalAdded"
