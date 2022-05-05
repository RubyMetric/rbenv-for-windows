# Usage: rbenv version
# Summary: Show the current Ruby version and its origin

function print_current_version_with_setmsg {
    $cur_ver, $setmsg = get_current_version_with_setmsg

    Write-Host "$cur_ver $setmsg"
}


print_current_version_with_setmsg
