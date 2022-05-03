# Usage: rbenv global [<version>]
# Summary: Set or show the global Ruby version

param($cmd)

function get_global_version() {
    Get-Content $GLOBAL_VERSION_FILE | Out-Host
}


function set_global_version($version) {
    $shimsdir = "$env:RBENV_ROOT\shims"

    if (Test-Path $shimsdir) {
        # remove read-only attribute on link
        # attrib $shimsdir -R /L

        # remove the junction
        Remove-Item $shimsdir -Recurse -Force -ErrorAction Stop
    }

    New-Item -Path $shimsdir -ItemType Junction -Value $version | Out-Null
    $version | Out-File $GLOBAL_VERSION_FILE
}


if (! $cmd) {
  get_global_version
} else {
  set_global_version($cmd)
}
