# Usage: rbenv shell [<version>]
# Summary: Sets a shell-specific Ruby version
# Help: rbenv shell <version>
# rbenv shell -
# rbenv shell --unset
#
# Sets a shell-specific Ruby version by setting the `RBENV_VERSION' environment variable in your shell. This version overrides local application-specific versions and the global version.
#
# With `-` or `--unset`, the `RBENV_VERSION` environment variable gets unset, restoring the environment to the state before the first `rbenv shell` call.


# Note,
# rbenv shell -
# is equal to
# rbenv shell --set
#


param($cmd)


function set_this_shell_version($version) {

    $version = auto_fix_version_for_installed $version

    if ($env:RBENV_VERSION) { # If already set
        unset_this_shell_version
        set_this_shell_version($version)
    } else {
        $env:RBENV_VERSION = $version
        $env:PATH = (get_bin_path_for_version($version)) + ";" + $env:PATH
    }
}


function unset_this_shell_version {
    if ($env:RBENV_VERSION) {

        # regexp not works because of back slash in path not valid
        # $env:PATH = $env:PATH -replace "$path"

        $arr = $env:PATH.split(';')
        $slicing = - ($arr.Count - 1)
        $env:PATH = $arr[$slicing..-1] -join ';'
        $env:RBENV_VERSION = $null

    } else {
        # noop
    }
}


if (!$cmd) {
    rbenv help shell
} elseif ($cmd -eq "--unset" -or $cmd -eq '-') {
    unset_this_shell_version
} else {
    set_this_shell_version($cmd)
}
