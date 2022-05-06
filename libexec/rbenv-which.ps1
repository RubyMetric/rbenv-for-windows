# Usage: rbenv which [<executable>]
# Summary: Display the full path to an executable

param($cmd)


# This is called by 'rbenv which xxx'
function get_executable_location ($cmd) {
    $version, $_ = get_current_version_with_setmsg
    get_executable_location_by_version $cmd $version
}


if (!$cmd) {
    rbenv help which
} else {
    get_executable_location $cmd
}
