# Usage: rbenv global [<version>]
# Summary: Set or show the global Ruby version

param($cmd)


function set_global_version($version) {

    $version = auto_fix_version_for_installed $version

    $shimsdir = "$env:RBENV_ROOT\shims"

    if (Test-Path $shimsdir) {
        # remove read-only attribute on link
        # attrib $shimsdir -R /L

        # remove the junction
        Remove-Item $shimsdir -Recurse -Force -ErrorAction Stop
    }

    if ($version -eq 'system') {
        New-Item -Path $shimsdir -ItemType Junction -Value "$($SYSTEM_RUBY['Path'])\bin" | Out-Null
    } else {
        New-Item -Path $shimsdir -ItemType Junction -Value "$env:RBENV_ROOT\$version" | Out-Null
    }

    $version | Out-File $GLOBAL_VERSION_FILE
}


if (! $cmd) {
  get_global_version
} else {
  set_global_version $cmd
}
