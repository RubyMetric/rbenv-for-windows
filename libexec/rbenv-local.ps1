# Usage: rbenv local [<version>]
# Summary: Set or show the local application-specific Ruby version

param($cmd)


# Read the .ruby-version file
function set_local_version($version) {

    $local_version_file = "$PWD\.ruby-version"

    $version = auto_fix_version_for_installed $version

    Set-Content $local_version_file $version
}


if (!$cmd) {
    $version = get_local_version
    if ($version -eq $NULL) {
        Write-Host "rbenv: no local version configured for this directory"
    }
} else {
    set_local_version($cmd)
}
