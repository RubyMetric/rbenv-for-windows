########################################
# The code between the fence is just for
# shim to directly use.

# redefine the $GLOBAL_VERSION_FILE
$GLOBAL_VERSION_FILE = "$env:RBENV_ROOT\global.txt"

# We must source it again
. $PSScriptRoot\..\lib\core.ps1
########################################


function get_system_ruby_version_and_path {
    $version, $path = $env:RBENV_SYSTEM_RUBY -split '<=>'
    return $version, $path
}


# Auto fix version number to get close to installed versions
#
# commands using this:
# 1. rbenv-global
# 2. rbenv-local
# 3. rbenv-shell
# 4. rbenv-uninstall
#
function auto_fix_version_for_installed($ver) {
    $versions = get_all_installed_versions

    if ($versions -contains $ver) {
        return $ver
    } else {
        foreach ($i in $versions)  {
            $i = [string] $i
            $ver = [string] $ver
            $idx = $i.IndexOf($ver)
            if ($idx -eq 0) { return $i }
        }
    }
    warn "rbenv: version $ver not installed"
    exit
}


# Auto fix version number to get close to all remote versions
# i.e. versions list
#
# commands using this:
# 1. rbenv-install
function auto_fix_version_for_remote($ver) {
    $versions = get_all_remote_versions

    if ($versions -contains $ver) {
        return $ver
    } else {
        foreach ($i in $versions)  {
            $i = [string] $i
            $ver = [string] $ver
            $idx = $i.IndexOf($ver)
            if ($idx -eq 0) { return $i }
        }
    }

    warn "rbenv: version $ver not found"
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
    $versions = (Get-ChildItem ($env:RBENV_ROOT)) | Where-Object {
                    $_.Name -match $(version_match_regexp) -or $_.Name -eq 'head'
                }

    # foreach ($ver in $versions) { $ver.Name }

    $versions = $versions | Sort-Object -Descending | ForEach-Object {
        $_.Name
    }

    if ($env:RBENV_SYSTEM_RUBY) {
        if ($versions.Count -eq 0) { $versions = @() }
        if ($versions.Count -eq 1) { $versions = @() + $versions }
        $versions = $versions + "system"
    }
    $versions
}


function get_current_version_with_setmsg_from_fake_ruby () {

    $msg = & $env:RBENV_ROOT\rbenv\bin\ruby.exe -v

    $ruby_slogan, $rest = $msg -Split ' '
    $version, $setmsg = $rest
    return $version, ($setmsg -Join ' ')
}


# return the bin path for specific version
function get_bin_path_for_version($version) {
    if ($version -eq 'system') {
        $_, $where = get_system_ruby_version_and_path
    } else {
        $where = "$env:RBENV_ROOT\$version"
    }
    $where += "\bin"
    $where
}



# For:
#   1. 'rbenv whence' directly use
#   2. get_gem_bin_location_by_version()
function list_who_has ($name) {

    $versions = get_all_installed_versions

    $whos = @()

    foreach ($ver in $versions) {
        if ($ver -eq 'system') {
            $_, $where = get_system_ruby_version_and_path
            $where = "$where\bin"
        } else {
            $where = "$env:RBENV_ROOT\$ver\bin"
        }


        $bat_file = "$where\$cmd" + '.bat'
        $cmd_file = "$where\$cmd" + '.cmd'

        # '.bat' first, because from 2023, basically all gems are in '.bat'
        if     (Test-Path $bat_file) { $whos += $bat_file }
        elseif (Test-Path $cmd_file) { $whos += $cmd_file }
        else { continue }
    }

    if ($whos.Count -gt 0) {
        return $whos
    } else {
        return $null
    }
}


# This is called by
#   1. 'get_gem_bin_location_by_version'
#   2. 'shim_get_gem_name'
#
function gem_not_found($gem) {
    Write-Host "rbenv: command '$cmd' not found"

    $whos = list_who_has $cmd

    if ($whos) {
        Write-Host "`nBut it exists in these Ruby versions:`n"
        $whos_rows = $whos -join "`n"
        Write-Host $whos_rows
    }
}



# Here, $cmd is a Gem's executable name
function get_gem_bin_location_by_version ($cmd, $version) {

    $where = get_bin_path_for_version $version

    # Not use TrimEnd!!
    $cmd = $cmd -replace '.bat$', ''
    $cmd = $cmd -replace '.cmd$', ''

    $bat_file = "$where\$cmd" + '.bat'
    $cmd_file = "$where\$cmd" + '.cmd'

    # '.bat' first, because from 2023, basically all gems are in '.bat'
    if     (Test-Path $bat_file) { return $bat_file }
    elseif (Test-Path $cmd_file) { return $cmd_file }
    else {
        gem_not_found
        exit -1
    }
}


# This is called by
# 1. 'get_executable_location'
# 2. 'ruby' and 'rubyw' callers in rbenv/bin/
#
function get_ruby_exe_location_by_version ($exe, $version) {
    if (-not $exe.EndsWith('.exe')) {
        $exe = $exe + '.exe'
    }
    $where = get_bin_path_for_version $version

    "$where\$exe"
}

# This is called by 'ridk' caller in rbenv/bin/
#
function get_ridk_location_by_version ($version) {
    $where = get_bin_path_for_version $version

    if (Test-Path "$where\ridk.ps1") {
        "$where\ridk.ps1"
    } else {
        "$where\ridk.cmd"
    }
}


# Function:
#   used by command 'rbenv which'
#
# Time:
#   73~85ms
#
# Arguments:
#   $cmd is a executable name
function get_executable_location ($cmd) {
    $version, $_ = get_current_version_with_setmsg_from_fake_ruby

    if ($cmd -eq 'ruby' -or $cmd -eq 'rubyw') {
        get_ruby_exe_location_by_version $cmd $version
    } else {
        get_gem_bin_location_by_version  $cmd $version
    }
}


# Function:
#   used for shim script to find the correct version of gem executable
#
#     'correct_ver_dir\gem_name.cmd' arguments or
#     'correct_ver_dir\gem_name.bat' arguments
#
# Time:
#   65~70ms
#
# Arguments:
#   $cmd is $PSCommandPath
#
function shim_get_gem_executable_location ($cmd_path) {
    if ($cmd_path.Contains(':')) {
        # $PSCommandPath must have a : to represent drive
        # E.g.
        # C:Ruby-on-Windows\shims\cr.ps1
        $f = fname $cmd_path # Now 'cr.ps1'
        $cmd = strip_ext $f  # Now 'cr'
    }

    $version, $_ = get_current_version_with_setmsg_from_fake_ruby

    # This condition is only met when global version is not set
    # Enforce users to set global version
    if ($version -eq $null) {
        return
    }

    # Still need to call this function to do some work (e.g. find available bins)
    $gem = get_gem_bin_location_by_version $cmd $version
    return $gem
}
