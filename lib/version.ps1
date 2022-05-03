$GLOBAL_VERSION_FILE = "$env:RBENV_ROOT\global.txt"
# $LOCAL_VERSION_FILE  = $NULL
$THIS_SHELL_VERSION = $NULL


# Read all dir names in the RBENV_ROOT
function get_all_installed_versions {
    # System.IO.DirectoryInfo
    $versions = (Get-ChildItem ($env:RBENV_ROOT)) `
                # + (Get-ChildItem "$rbenvdir\shims") `
                | Where-Object { $_.name -match '\d{1,}\.\d{1,}\.\d{1,}-\d{1,}.*?$' }

    # foreach ($ver in $versions) { $ver.Name }

    $versions = $versions | ForEach-Object {
        $_.Name
    }
    $versions
}


# Read the global.txt file
function get_global_version() {
    Get-Content $GLOBAL_VERSION_FILE | Out-Host
}


# Read the .ruby-version file
function get_local_version {
    $local_version_file = "$PWD\.ruby-version"
    if (Test-Path $local_version_file) {
        return Get-Content $local_version_file
    } else {
        return $NULL
    }
}


# Read the global variable
function get_this_shell_version {
    $THIS_SHELL_VERSION
}


function get_current_version {
    # Check rbenv shell
    if ($cur_ver = get_this_shell_version) {
        return $cur_ver

    # Check rbenv local
    } elseif ($cur_ver = get_local_version) {
        if (get_all_installed_versions -contains $cur_ver) {
            return $cur_ver
        } else {
            Write-Error "rbenv: version $cur_ver is not installed"
        }

    # Check rbenv global
    } elseif ($cur_ver = get_global_version) {
        if (!$cur_ver) {
            Write-Error "rbenv: No Ruby installed on your system"
            Write-Error "       Try use rbenv install <version>"
        } else {
            return $cur_ver
        }
    }
}
