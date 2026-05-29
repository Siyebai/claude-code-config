# Session Start hook - DeepSeek 1M cache cleaner
Remove-Item "$env:USERPROFILE\.claude\paste-cache\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\.claude\shell-snapshots\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\.claude\telemetry\*" -Force -Recurse -ErrorAction SilentlyContinue
Write-Output "[startup] DS1M - Clean"
