# Usage: rbenv versions
# Summary: List installed Ruby versions

function list_installed_versions {
    $versions = get_all_installed_versions
    foreach ($ver in $versions) {
        Write-Host $ver
    }
}

list_installed_versions
