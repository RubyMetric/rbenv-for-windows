# Usage: rbenv global [<version>]
# Summary: Set or show the global Ruby version

param($cmd)


function set_global_version($version) {
    $shimsdir = "$env:RBENV_ROOT\shims"

    if (-Not $(get_all_installed_versions) -contains $version ) {
        Write-Error "rbenv: version $version not installed"
        exit 1
    }

    if (Test-Path $shimsdir) {
        # remove read-only attribute on link
        # attrib $shimsdir -R /L

        # remove the junction
        Remove-Item $shimsdir -Recurse -Force -ErrorAction Stop
    }

    New-Item -Path $shimsdir -ItemType Junction -Value "$env:RBENV_ROOT\$version" | Out-Null
    $version | Out-File $GLOBAL_VERSION_FILE
}


if (! $cmd) {
  get_global_version
} else {
  set_global_version($cmd)
}
