# Usage: rbenv global [<version>]
# Summary: Set or show the global Ruby version

param($cmd)


function get_global_version {
    invoke_rbenv_exec get-global-version
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}


function set_global_version($version) {
    invoke_rbenv_exec set-global-version $version
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}


if (!$cmd) {
    get_global_version
} else {
    set_global_version $cmd
}
