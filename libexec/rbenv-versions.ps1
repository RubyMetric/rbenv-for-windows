# Usage: rbenv versions
# Summary: List installed Ruby versions

function all_installed_versions {
    (Get-ChildItem ($env:RBENV_ROOT)) `
        # + (Get-ChildItem "$rbenvdir\shims") `
        | Where-Object { $_.name -match '\d{1,2}\.\d{1,3}\.\d{1,4}.*?$' }
}

function list_installed_versions {
    $all_installed_versions = all_installed_versions
    foreach ($ver in $all_installed_versions) {
        Write-Host $ver.Name
    }
}

list_installed_versions
