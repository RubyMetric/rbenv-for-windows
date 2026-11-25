# Usage: rbenv local [<version>]
# Summary: Set or show the local application-specific Ruby version

param($cmd)


function get_local_version {
    invoke_rbenv_exec get-local-version
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}


function set_local_version($version) {
    # See doc\PowerShell-problems.md for the encoding rationale.
    invoke_rbenv_exec set-local-version $version
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}


if (!$cmd) {
    get_local_version
} else {
    set_local_version $cmd
}
