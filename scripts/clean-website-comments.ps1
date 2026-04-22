$pattern = '^\s*(//|/\*|<!--)\s*Note \d+:'
$folder = "$PSScriptRoot\..\website"
$files = Get-ChildItem -Path $folder -Recurse -File | Where-Object { $_.FullName -notmatch '\\node_modules\\|\\dist\\' }
$totalRemoved = 0
foreach ($f in $files) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName)
    $filtered = $lines | Where-Object { $_ -notmatch $pattern }
    if ($filtered.Count -ne $lines.Count) {
        $removed = $lines.Count - $filtered.Count
        [System.IO.File]::WriteAllLines($f.FullName, $filtered)
        $totalRemoved += $removed
        Write-Host "Cleaned $removed lines: $($f.Name)"
    }
}
Write-Host "Total lines removed: $totalRemoved"
