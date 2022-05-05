# Usage: rbenv uninstall <version>
# Summary: Uninstall a specific Ruby version


param($cmd)


function uninstall_rubyinstaller($version) {

    $version = auto_fix_version_for_installed $version

    Write-Host "Deleting $version..."
    Remove-Item -Recurse -Force "$env:RBENV_ROOT\$version"
    success "version $version was uninstalled."

}


if (!$cmd) {
    rbenv help uninstall
} else {
    uninstall_rubyinstaller($cmd)
}

