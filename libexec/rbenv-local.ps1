# Usage: rbenv local [<version>]
# Summary: Set or show the local application-specific Ruby version

param($cmd)


# Read the .ruby-version file
function set_local_version($version) {
    # See doc\PowerShell-problems.md for the encoding rationale.
    & "$env:RBENV_ROOT\rbenv\libexec\rbenv-exec.exe" write-local-version $version
    if ($LASTEXITCODE -ne 0) {
        abort 'rbenv: unable to set local version' $LASTEXITCODE
    }
}


if (!$cmd) {
    $version = get_local_version
    if ($version -eq $null) {
        Write-Host "rbenv: no local version configured for this directory"
    } else {
        $version
    }
} else {
    set_local_version $cmd
}
