# Session End hook - DeepSeek 1M session trimmer
$d = "$env:USERPROFILE\.claude\backups"
if (!(Test-Path $d)) { mkdir $d -Force | Out-Null }
Get-ChildItem "$env:USERPROFILE\.claude\projects\C--Users----" -Recurse -Filter *.jsonl -ErrorAction SilentlyContinue |
  Where-Object { $_.Length -gt 500KB } | ForEach-Object {
    $bak = $d + "\" + $_.BaseName + "-" + (Get-Date -Format yyyyMMdd) + ".bak"
    if (!(Test-Path $bak)) { Copy-Item $_.FullName $bak -Force }
    $c = Get-Content $_.FullName
    if ($c.Count -gt 60) {
      ($c | Select-Object -First 3) + ($c | Select-Object -Last 50) | Set-Content $_.FullName
      Write-Output ("[end] Trimmed: " + $_.Name)
    }
  }
Write-Output "[end] DS1M - Done"
