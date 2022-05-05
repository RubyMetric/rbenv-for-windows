# Usage: rbenv shell [<version>]
# Summary: Sets a shell-specific Ruby version
# Help: rbenv shell <version>
# rbenv shell --unset
#
# Sets a shell-specific Ruby version by setting the `RBENV_VERSION' environment variable in your shell. This version overrides local application-specific versions and the global version.
#
# With `--unset`, the `RBENV_VERSION` environment variable gets unset, restoring the environment to the state before the first `rbenv shell` call.


# Sorry, don't have time to support
# rbenv shell -

param($cmd)


function set_this_shell_version($version) {

    # if already set
    if ($env:RBENV_VERSION) {
        unset_this_shell_version
        set_this_shell_version($version)
    } else {
        $env:RBENV_VERSION = $version
        $env:PATH = "$env:RBENV_ROOT\$version\bin;" + $env:PATH
    }
}


function unset_this_shell_version {
    if ($env:RBENV_VERSION) {

        # regexp not works because of back slash in path not valid
        # $env:PATH = $env:PATH -replace "$path"

        $arr = $env:PATH.split(';')
        $slicing = - ($arr.Count - 1)
        $env:PATH = $arr[$slicing..-1] -join ';'
        $env:RBENV_VERSION = $NULL

    } else {
        # noop
    }
}


if (!$cmd) {
    rbenv help shell
} elseif ($cmd -eq "--unset") {
    unset_this_shell_version
} else {
    set_this_shell_version($cmd)
}
