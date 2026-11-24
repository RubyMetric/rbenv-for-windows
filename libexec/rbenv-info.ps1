# Usage: rbenv info
# Summary: Show rbenv, PowerShell and Ruby environment information
# Category: extension
# Help: Show rbenv, binary and PowerShell versions, then run ridk version.

if ($args.Count -gt 0) {
    abort 'Usage: rbenv info'
}

$binary_version_file = Join-Path $env:RBENV_ROOT 'rbenv-ETag.txt'
$binary_version = if (Test-Path -LiteralPath $binary_version_file -PathType Leaf -ErrorAction Stop) {
    $value = Get-Content -LiteralPath $binary_version_file -TotalCount 1 -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($value)) { 'unavailable (empty rbenv-ETag.txt)' } else { $value }
} else {
    'unavailable (rbenv-ETag.txt not found)'
}

"rbenv version: $RBENV_OWN_VERSION"
"rbenv binary version: $binary_version"
"PowerShell version: $($PSVersionTable.PSVersion)"

& "$PSScriptRoot\..\bin\ridk.ps1" version
if (-not $?) {
    if ($LASTEXITCODE -eq 0) { exit 1 }
    exit $LASTEXITCODE
}
