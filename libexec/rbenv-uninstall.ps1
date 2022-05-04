# Usage: rbenv uninstall <version>
# Summary: Uninstall a specific Ruby version


param($cmd)


function uninstall_rubyinstaller($version) {

    if (-not $(get_all_installed_versions) -contains $version) {
        warn "version $version wasn't installed."
    } else {
        Write-Host "Deleting..."
        Remove-Item -Recurse -Force "$env:RBENV_ROOT\$version"
        success "version $version was uninstalled."
    }
}


if (!$cmd) {
    rbenv help uninstall
} else {
    uninstall_rubyinstaller($cmd)
}

