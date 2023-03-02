# Usage: rbenv versions
# Summary: List installed Ruby versions

function list_installed_and_current_versions {
    $versions = get_all_installed_versions

    if ($versions.Count -eq 0) {
        Write-Host "rbenv: No Ruby installed on your system"
        Write-Host "       Try use rbenv install <version>"
        exit
    }

    $cur_ver, $setmsg = get_current_version_with_setmsg_from_fake_ruby

    foreach ($ver in $versions) {
        if ($ver -eq $cur_ver) {
            Write-Host "* $ver $setmsg"
        } elseif ($ver -eq "system") {
            $s_rb_ver, $s_rb_path  = get_system_ruby_version_and_path
            Write-Host "  system  ($s_rb_ver $s_rb_path)"
        } elseif ($ver -eq "head") {
            $ct = (Get-Item "$env:RBENV_ROOT\head").CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
            Write-Host "  head    (Installed on $ct)"
        } else {
            Write-Host "  $ver"
        }
    }
}

list_installed_and_current_versions
