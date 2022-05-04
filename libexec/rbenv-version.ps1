# Usage: rbenv version
# Summary: Show the current Ruby version and its origin

function print_global_version {
    if (! $env:RBENV_VERSION_GLOBAL) {

    } else {
        Write-Host $env:RBENV_VERSION_GLOBAL
    }
}

get_current_version
