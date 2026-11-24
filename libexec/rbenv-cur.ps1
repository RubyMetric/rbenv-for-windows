# Usage: rbenv cur
# Summary: Alias for rbenv current
# Category: extension
# Help: See rbenv help current.

& "$PSScriptRoot\rbenv-current.ps1" @args
if (-not $?) {
    if ($LASTEXITCODE -eq 0) { exit 1 }
    exit $LASTEXITCODE
}
