# Always check the system ruby first
#
# HKEY_CURRENT_USER
$install_keys = "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
# If installed multiple
# We choose the larger one, so using Descending
$keys = (Get-Item "$install_keys\RubyInstaller*") | Sort-Object -Descending

if (!$keys) {
    # no system Ruby at all
} else {

    if ($keys.Count -gt 1) {
        warn "rbenv: Only one system Ruby is support, but you've installed $($keys.Count)"
    }
    if ($k = $keys[0]) {
        $SYSTEM_RUBY = @{
            Version = $k.GetValue('DisplayVersion') ;
            Path    = $k.GetValue('InstallLocation')
        }
    }
}


# Ensure our global.txt file
if (-Not (Test-Path $GLOBAL_VERSION_FILE) ) {
    # Defined at the top
    New-Item $GLOBAL_VERSION_FILE
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
    $versions = (Get-ChildItem ($env:RBENV_ROOT)) `
                # + (Get-ChildItem "$rbenvdir\shims") `
                | Where-Object { $_.name -match '\d{1,}\.\d{1,}\.\d{1,}-\d{1,}.*?$' }

    # foreach ($ver in $versions) { $ver.Name }

    $versions = $versions | Sort-Object -Descending | ForEach-Object {
        $_.Name
    }

    if ($SYSTEM_RUBY) {
        $versions = [Collections.ArrayList] $versions
        $versions.Insert(0, "system")
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
            warn "rbenv: version $cur_ver is not installed"
        }

    # Check rbenv global
    } elseif ($cur_ver = get_global_version) {
        if (!$cur_ver) {
            warn "rbenv: No version has been set, try 'rbenv global <version>'"
        } else {
            $setmsg = "(set by $env:RBENV_ROOT\global.txt)"
            return $cur_ver, $setmsg
        }
    }
}


# This is called
#
# 1. directly by the rehash script
# 2. indirectly by command 'rbenv which'
#
# Here, $cmd is a Gem's  executable name
function get_gem_bin_location_by_version ($cmd, $version) {
    if (-not $cmd.EndsWith('.bat')) {
        $cmd = $cmd + '.bat'
    }

    if ($version -eq 'system') {

    } else {
        "$env:RBENV_ROOT\$version\bin\$cmd"
    }
}


# This is called
#
# 1. directly by the rehash script
# 2. indirectly by command 'rbenv which'
#
function get_ruby_exe_location_by_version ($exe, $version) {
    if (-not $exe.EndsWith('.exe')) {
        $exe = $exe + '.exe'
    }

    if ($version -eq 'system') {

    } else {
        if ($exe -eq 'ruby.exe') {
            "$env:RBENV_ROOT\$version\bin\ruby.exe"
        } elseif ($exe -eq 'rubyw.exe') {
            "$env:RBENV_ROOT\$version\bin\rubyw.exe"
        } else {
            Write-Host "This condition shouldn't be triggered at present"
            Write-Host "Because we only need to return ruby.exe and rubyw.exe"
            "$env:RBENV_ROOT\$version\bin\$exe"
        }
    }
}
