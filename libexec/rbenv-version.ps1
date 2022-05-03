# Usage: rbenv version
# Summary: Show the current Ruby version and its origin

function print_global_version {
  Write-Host $env:RBENV_VERSION_GLOBAL
}

print_global_version
