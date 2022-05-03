# Usage: rbenv version
# Summary: Show the current Ruby version and its origin

function print_global_version {
    if (! $env:RBENV_VERSION_GLOBAL) {
        $system_ruby = $(Get-Command ruby)
        if ($system_ruby) {
            Write-Host "system(v$($system_ruby.Version)  $($system_ruby.Source))"
        } else {
            Write-Host "rbenv: No Ruby installed on your system"
            Write-Host "       Try use rbenv install <version>"
        }
    } else {
        Write-Host $env:RBENV_VERSION_GLOBAL
    }
}

get_current_version
