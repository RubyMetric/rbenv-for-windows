# Usage: rbenv current
# Summary: Show configured global, local, shell and system Ruby versions
# Category: extension
# Help: Show the active version and configured versions, including the nearest
#       local version file.
#       Shell takes precedence over local, which takes precedence over global.
#       The command can also be abbreviated as rbenv cur.

if ($args.Count -gt 0) {
    abort 'Usage: rbenv current'
}

$global_version = '(not set)'
if (Test-Path -LiteralPath $GLOBAL_VERSION_FILE -PathType Leaf -ErrorAction Stop) {
    $value = Get-Content -LiteralPath $GLOBAL_VERSION_FILE -Raw -ErrorAction Stop
    if (-not [string]::IsNullOrWhiteSpace($value)) {
        $global_version = $value.TrimEnd("`r", "`n")
    }
}

$local_version = '(not set)'
$directory = Get-Item -LiteralPath (Get-Location).Path -Force -ErrorAction Stop
while ($directory.Parent) {
    $version_file = Join-Path $directory.FullName '.ruby-version'
    if (Test-Path -LiteralPath $version_file -PathType Leaf -ErrorAction Stop) {
        $value = Get-Content -LiteralPath $version_file -TotalCount 1 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($value)) {
            $local_version = "(empty: $version_file)"
        } else {
            $local_version = "$value ($version_file)"
        }
        break
    }
    $directory = $directory.Parent
}

$shell_version = if ($env:RBENV_VERSION) { $env:RBENV_VERSION } else { '(not set)' }
$system_version, $system_path = get_system_ruby_version_and_path
$system = if ($system_version) { "$system_version ($system_path)" } else { '(not detected)' }

$active = '(not set)'
if ($shell_version -ne '(not set)' -or $local_version -ne '(not set)' -or $global_version -ne '(not set)') {
    $current_version, $source = get_current_version_with_setmsg_from_fake_ruby
    if ($LASTEXITCODE -ne 0 -or -not $current_version) {
        abort 'rbenv: unable to determine the active Ruby version'
    }
    $active = "$current_version $source".TrimEnd()
}

[PSCustomObject]@{
    Active = $active
    Global = $global_version
    Local  = $local_version
    Shell  = $shell_version
    System = $system
} | Format-List
