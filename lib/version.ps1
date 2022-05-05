$GLOBAL_VERSION_FILE = "$env:RBENV_ROOT\global.txt"
# $LOCAL_VERSION_FILE  = $NULL
$env:RBENV_VERSION = $NULL


# Try to get system Ruby first
#
# This code works because
#   1. 'rbenv.ps1' sources this file at the top before
#       adding default modifications to path.
#   2. system Ruby installed by GUI RubyInstaller will
#       add path to very top, it's be searched first
#
$system_ruby = $(Get-Command ruby)

# This occurs when system Ruby is just installed
# before path starts to work
# Lead to false positive
if ($system_ruby.Source  -like "$env:RBENV_ROOT*") {
    $system_ruby = $null
}



####################
#    Functions
####################

# Auto fix version number to get close to installed versions
#
# commands using this:
# rbenv-global
# rbenv-local
# rbenv-shell
# rbenv-uninstall
function auto_fix_version_for_installed($ver) {
    $versions = get_all_installed_versions

    if ($versions -contains $ver) {
        return $ver
    } else {
        foreach ($i in $versions)  {
            $idx = $i.IndexOf($ver)
            if ($idx -eq 0) { return $i }
        }
    }
    Write-Host -f darkyellow "rbenv: version $ver not installed"
    exit
}


# Auto fix version number to get close to all remote versions
# i.e. versions list
#
# commands using this:
# rbenv-install
#
function auto_fix_version_for_remote($ver) {
    $versions = get_all_remote_versions

    if ($versions -contains $ver) {
        return $ver
    } else {
        foreach ($i in $versions)  {
            $idx = $i.IndexOf($ver)
            if ($idx -eq 0) { return $i }
        }
    }

    Write-Host -f darkyellow "rbenv: version $ver not found"
    exit
}


# Read versions list
function get_all_remote_versions {
    $versions = Get-Content $PSScriptRoot\..\share\versions.txt
    $versions = $versions -split "`n"
    $versions
}


# Read all dir names in the RBENV_ROOT
function get_all_installed_versions {

    # System.IO.DirectoryInfo
    $versions = (Get-ChildItem ($env:RBENV_ROOT)) `
                # + (Get-ChildItem "$rbenvdir\shims") `
                | Where-Object { $_.name -match '\d{1,}\.\d{1,}\.\d{1,}-\d{1,}.*?$' }

    # foreach ($ver in $versions) { $ver.Name }

    $versions = $versions | Sort-Object -Descending | ForEach-Object {
        $_.Name
    }

    if ($system_ruby) {
        $versions = [Collections.ArrayList] $versions
        $versions.Insert(0, "system  (v$($system_ruby.Version)  $($system_ruby.Source))")
    }

    $versions
}


# Read the global.txt file
function get_global_version() {
    Get-Content $GLOBAL_VERSION_FILE
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
    $env:RBENV_VERSION
}


function get_current_version_with_setmsg {
    # Check rbenv shell
    if ($cur_ver = get_this_shell_version) {

        $setmsg = "(set by `$env:RBENV_VERSION environment variable)"
        return $cur_ver, $setmsg

    # Check rbenv local
    } elseif ($cur_ver = get_local_version) {
        if (get_all_installed_versions -contains $cur_ver) {
            $setmsg = "(set by $PWD\.ruby-version)"
            return $cur_ver, $setmsg
        } else {
            Write-Error "rbenv: version $cur_ver is not installed"
        }

    # Check rbenv global
    } elseif ($cur_ver = get_global_version) {
        if (!$cur_ver) {
            Write-Error -f darkyellow "rbenv: No Ruby installed on your system"
            Write-Error -f darkyellow "       Try use rbenv install <version>"
        } else {
            $setmsg = "(set by $env:RBENV_ROOT\global.txt)"
            return $cur_ver, $setmsg
        }
    }
}
