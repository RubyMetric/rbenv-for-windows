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
    # <2023-05-05> Although I've fixed the bug of bundler process to successfully trigger
    # the post-install hook in the share/rubygems_plugins.rb
    # And then, `rbenv rehash` after a `rbenv global` is no longer needed.
    #
    # But I think it now can be a second safeguard to ensure all gems' executables are there
    # in the shims dir. So I keep this statement.
    command_exec rehash version $version
}


if (!$cmd) {
    get_global_version
} else {
    set_global_version $cmd
}
