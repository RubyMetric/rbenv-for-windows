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
        $versions = [Collections.ArrayList] $versions
        $versions.Insert(0, "system")
    }

    $versions
}


# Read the global.txt file
function get_global_version() {
    $version = Get-Content $GLOBAL_VERSION_FILE
    if (!$version) {warn "rbenv: No global version has been set, use rbenv global <version>"}
    else {$version}
}


# Read the .ruby-version file
# Guess why I don't want it to find the Git root directory?
# Because it's too slow: causing another 28ms to delay
# I really don't want it
function get_local_version {
    $local_version_file = "$PWD\.ruby-version"
    if (Test-Path $local_version_file) {
        $version = Get-Content $local_version_file
        # Complete '3.1.3' with the suffix '-1'
        $version = auto_fix_version_for_installed($version)
        return $version
    } else {
        return $null
    }
}


# Read the global variable
function get_this_shell_version {
    $env:RBENV_VERSION
}


# (current_version  set_by_xxx)
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
            warn "rbenv: version $cur_ver is not installed"
        }

    # Check rbenv global
    } elseif ($cur_ver = get_global_version) {
        if (!$cur_ver) {
            warn "rbenv: No version has been set, try 'rbenv global <version>'"
            # We must terminate rbenv to enforce users to set global version
            return $null, $null
        } else {
            $setmsg = "(set by $env:RBENV_ROOT\global.txt)"
            return $cur_ver, $setmsg
        }
    }
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
        $who = "$where\$name"
        if (Test-Path $who) { $whos += $who }
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

    $cmd_file = "$where\$cmd" + '.cmd'
    $bat_file = "$where\$cmd" + '.bat'

    if     (Test-Path $cmd_file) { return $cmd_file }
    elseif (Test-Path $bat_file) { return $bat_file }
    else {
        gem_not_found
        exit -1
    }
}


# This is called by 'get_executable_location'
#
# Now, only two exe files should be called by this
# 'ruby.exe' and 'rubyw.exe'
function get_ruby_exe_location_by_version ($exe, $version) {
    if (-not $exe.EndsWith('.exe')) {
        $exe = $exe + '.exe'
    }
    $where = get_bin_path_for_version $version

    "$where\$exe"
}


# used by
# command 'rbenv which' (13~18ms)
#    $cmd is a executable name
function get_executable_location ($cmd) {
    $version, $_ = get_current_version_with_setmsg

    if ($_.Contains(".ruby-version")) {
        $current_global = get_global_version
        if (-Not ($version -eq $current_global)) {
            warn "rbenv: As a compromise, we change to global version for '.ruby-version'"
            rbenv global $version
        }
    }

    if ($cmd -eq 'ruby' -or $cmd -eq 'rubyw') {
        get_ruby_exe_location_by_version $cmd $version
    } else {
        get_gem_bin_location_by_version  $cmd $version
    }
}


# Function:
#   This is for shim to use.
#
#   (1) If we call ruby
#   We will run:    'correct_ver_dir\ruby.exe' arguments
#
#   (2) If we call gem bin command
#   We will run:    'correct_ver_dir\gem_name.cmd' or 'correct_ver_dir\gem_name.bat' arguments
#
# Time:
#   This function is only (6~8ms) to run
#
# Arguments:
#   $cmd is a $PSCommandPath
#
function shim_get_execution ($cmd_path) {
    if ($cmd_path.Contains(':')) {
        # $PSCommandPath must have a : to represent drive
        # E.g.
        # C:Ruby-on-Windows\shims\bin\cr.ps1
        $f = fname $cmd_path # Now 'cr.ps1'
        $cmd = strip_ext $f  # Now 'cr'
    }

    $version, $_ = get_current_version_with_setmsg

    # This condition is only met when global version is not set
    # Enforce users to set global version
    if ($version -eq $null) {
        return
    }

    # <2023-01-11> We use `rbenv global` as a compromising method
    # We hope users will run some Ruby commands in the root dir of a project, whenever they cd into a project.

    if ($_.Contains(".ruby-version")) {
        $current_global = get_global_version
        if (-Not ($version -eq $current_global)) {
            warn "rbenv: As a compromise, we change to global version for '.ruby-version'"
            rbenv global $version
        }
    }

    $rubyexe = $null
    $gem     = $null

    if ($cmd -eq 'ruby' -or $cmd -eq 'rubyw') {
        $rubyexe = get_ruby_exe_location_by_version $cmd $version
        return $rubyexe
    } else {
        # Still need to call this function to do some work (e.g. find available bins)
        $gem  = get_gem_bin_location_by_version $cmd $version
        return $gem
    }
}
