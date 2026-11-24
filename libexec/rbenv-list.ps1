# Usage: rbenv list [-i|--installed|-l|--local|-r|--remote]
# Summary: List installed (-l) or available (-r) Ruby versions
# Category: extension
# Help: List installed Ruby versions and their locations.
#       Use -i, --installed, -l or --local to explicitly list installed versions.
#       Use -r or --remote to list available versions and mark installed ones.
#       Each option accepts either one or two leading hyphens.
#       The command can also be abbreviated as rbenv ls.

$ErrorActionPreference = 'Stop'

# -i and --installed follow mise to make the command familiar to mise users.
if ($args.Count -gt 1 -or ($args.Count -eq 1 -and $args[0] -notmatch '^--?(i|installed|l|local|r|remote)$')) {
    throw "Usage: rbenv list [-i|--installed|-l|--local|-r|--remote]"
}

$installed = @(get_all_installed_versions)
$system_version, $system_path = get_system_ruby_version_and_path

if ($args.Count -eq 1 -and $args[0] -match '^--?(r|remote)$') {
    get_all_remote_versions | ForEach-Object {
        $is_installed = $installed -contains $_ -or ($system_version -and $system_version -eq $_)
        [PSCustomObject]@{
            Version = $_
            Installed = if ($is_installed) { [string][char]0x2713 } else { '' }
        }
    } | Format-Table -AutoSize
} elseif ($installed.Count -eq 0) {
    Write-Host "rbenv: No Ruby installed on your system"
    Write-Host "       Try use rbenv install <version>"
} else {
    $installed | ForEach-Object {
        $location = if ($_ -eq 'system') { $system_path } else { Join-Path $env:RBENV_ROOT $_ }
        [PSCustomObject]@{
            Version = if ($_ -eq 'system') { "system ($system_version)" } else { $_ }
            Location = $location
        }
    } | Format-Table -AutoSize
}
