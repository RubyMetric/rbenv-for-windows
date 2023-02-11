# Usage: rbenv local [<version>]
# Summary: Set or show the local application-specific Ruby version

param($cmd)


# Read the .ruby-version file
function set_local_version($version) {

    $local_version_file = "$PWD\.ruby-version"

    $version = auto_fix_version_for_installed $version

<#
    To make every Ruby project portable from Windows to *nix, we try to be compatible with `rbenv`

    So, we will remove the version '3.2.0-1' suffix '-1'
#>

    $version, $suffix = $version.split("-")
    Set-Content $local_version_file $version -NoNewline
}


if (!$cmd) {
    $version = get_local_version
    if ($version -eq $null) {
        Write-Host "rbenv: no local version configured for this directory"
    } else {
        $version
    }
} else {
    set_local_version $cmd
}
