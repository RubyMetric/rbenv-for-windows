# Usage: rbenv current [--debug]
# Summary: Show configured global, local, shell and system Ruby versions
# Category: extension
# Help: Show the active version and configured versions, including the nearest
#       local version file. --debug also shows the JSON returned by rbenv-exec.
#       Shell takes precedence over local, which takes precedence over global.
#       The command can also be abbreviated as rbenv cur.

if ($args.Count -gt 1 -or ($args.Count -eq 1 -and $args[0] -cne '--debug')) {
    abort 'Usage: rbenv current [--debug]'
}
$debug_json = $args.Count -eq 1

$json = invoke_rbenv_exec current
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$json = $json -join "`n"
$versions = $json | ConvertFrom-Json -ErrorAction Stop
if ($null -eq $versions -or
    $versions.active.version -isnot [string] -or
    $versions.active.source -isnot [string] -or
    $versions.global -isnot [string] -or
    $versions.local.version -isnot [string] -or
    $versions.local.path -isnot [string] -or
    $versions.shell -isnot [string] -or
    $versions.system.version -isnot [string] -or
    $versions.system.path -isnot [string]) {
    abort 'rbenv: invalid current versions JSON from rbenv-exec'
}
if ($debug_json) {
    $json
}

$active = if ($versions.active.version) {
    "$($versions.active.version) $($versions.active.source)".TrimEnd()
} else {
    '(not set)'
}
$global_version = if ($versions.global) {
    $versions.global
} else {
    '(not set)'
}
$local_version = if (-not $versions.local.path) {
    '(not set)'
} elseif ([string]::IsNullOrWhiteSpace($versions.local.version)) {
    "(empty: $($versions.local.path))"
} else {
    "$($versions.local.version) ($($versions.local.path))"
}
$shell_version = if ($versions.shell) {
    $versions.shell
} else {
    '(not set)'
}
$system = if ($versions.system.version) {
    "$($versions.system.version) ($($versions.system.path))"
} else {
    '(not detected)'
}

[PSCustomObject]@{
    Active = $active
    Global = $global_version
    Local  = $local_version
    Shell  = $shell_version
    System = $system
} | Format-List
