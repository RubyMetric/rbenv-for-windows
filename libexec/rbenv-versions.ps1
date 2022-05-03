# Usage: rbenv versions
# Summary: List installed Ruby versions

function list_installed_and_current_versions {
    $versions = get_all_installed_versions
    $version  = "$(get_current_version)"

    foreach ($ver in $versions) {
        if ($ver -eq $version) {
            Write-Host "* $ver"
        } else {
            Write-Host "  $ver"
        }
    }
}

list_installed_and_current_versions
