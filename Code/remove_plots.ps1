$file = "Mallbooks.m"
$lines = Get-Content $file
$modified = $false

for ($i=0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match "^\s*%") {
        continue
    }
    if ($line -match "^\s*(figure|plot|saveas|title|xlabel|ylabel|legend|hold on|hold off|xlim|ylim|scatter|area|fill|set|grid|line|yyaxis|xticks|yticks)\b" -or
        $line -match "^\s*\w+\s*=\s*(plot|figure|scatter)\b") {
        $lines[$i] = "%" + $line
        $modified = $true
    }
}

if ($modified) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines((Convert-Path $file), $lines, $utf8NoBom)
    Write-Host "Modified $file"
} else {
    Write-Host "No changes"
}
