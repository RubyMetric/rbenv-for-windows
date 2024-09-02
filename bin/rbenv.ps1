# ---------------------------------------------------------------
# Copyright © 2022-2024 曾奥然 (Aoran Zeng)
# SPDX-License-Identifier: MIT
# ---------------------------------------------------------------
# Project Name    : rbenv for Windows
# Project Authors : Aoran Zeng <ccmywish@qq.com>
# Contributors    : Scoop Contributors
# Created On      : <2022-05-02>
# Last Modified   : <2024-09-02>
#
# Credit:
#   I reuse a lot of code pieces from Scoop:
#   <https://github.com/ScoopInstaller/Scoop> ("The Unlicense")
# ---------------------------------------------------------------

param($cmd)

########################################
#       Inner global variables
########################################
# [String]
# rbenv's own version
# Not to conflict with $env:RBENV_VERSION ('rbenv shell' sets it)
$RBENV_OWN_VERSION       = "rbenv v1.5.1"

# [String]
# Where we check the global version
#
# Note that We redefined it at lib\version.ps1, because
# shim will directly uses it. We don't want it
# to be $env variable.
$GLOBAL_VERSION_FILE = "$env:RBENV_ROOT\global.txt"

# [String]
# Where we store shims(Gem executables delegate script)
#
# Note that We redefined it at libexec\rbenv-rehash.ps1,
#  We don't want it to be $env variable.
$SHIMS_DIR = "$env:RBENV_ROOT\shims"

<#
The init process does 7 things:

    1. Set init flag to avoid double init
    2. Add two paths at the front of the user PATH (almost no delay)
       (2.1) $env:RBENV_ROOT\rbenv\bin is to delegate rbenv commands and ruby(w).exe
       (2.2) $env:RBENV_ROOT\shims     is to delegate all Gem commands
    3. Add one path to RUBYLIB
    4. Ensure global.txt and shims dir (2ms       delay)
    5. Check system Ruby               (10ms~20ms delay)
    6. If has system Ruby, rehash it just only one time (50ms, but only when you first setup rbenv)
    7. If no the shared MSYS2, install it
#>

if ($cmd -eq "init") {

    if ($env:RBENV_INIT -eq 1) {
        # Avoid initializing more than once! This is important, because subshells will
        # init twice or more, for example in VSCode integrated terminal

        # Write-Host "rbenv: Avoid double init!"
        return
    }
    $env:RBENV_INIT = 1

    $rbenv_path_first = "$env:RBENV_ROOT\rbenv\bin;" + "$env:RBENV_ROOT\shims;"
    $env:PATH = $rbenv_path_first + $env:PATH

    # For RubyGems plugin to work
    $env:RUBYLIB += "$env:RBENV_ROOT\rbenv\share"

    # Ensure global.txt version file
    if (-Not (Test-Path $GLOBAL_VERSION_FILE) ) {
        # Defined at the top
        New-Item $GLOBAL_VERSION_FILE | Out-Null
    }

    # Ensure shims dir
    if (-Not (Test-Path $SHIMS_DIR) ) {
        # Defined at the top
        New-Item -Path $SHIMS_DIR -ItemType Directory | Out-Null
    }

    # Always check the system ruby first
    # Note that We only want to check it one time for sub commands to reuse,
    # hence no repetitive overhead.
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
            $msg = "rbenv: Only one system Ruby is supported, but you've installed $($keys.Count)"
            Write-Host -f darkyellow $msg
        }
        if ($keys[0]) {
            $k = $keys[0]
            # NOTE!!!
            # $env: variable are only types of String!
            # You can't assign it a hash, array!!!
            # So we hack it to a string split by '<=>'
            # e.g.
            #   3.1.2-1<=>C:\Ruby31-x64\
            #
            $s_rb_ver  = $k.GetValue('DisplayVersion')
            $s_rb_path = $k.GetValue('InstallLocation').TrimEnd('\')
            $env:RBENV_SYSTEM_RUBY = "$s_rb_ver<=>$s_rb_path"

            # Last thing, rehash it if not been rehashed
            if (Test-Path "$s_rb_path\bin\ruby.ps1") {
                rbenv rehash version system
            }
        }
    }

    # We MUST download our own MSYS2, and not reuse user's own!
    # Because the RubyInstaller2 bundled MSYS2 have everything ready to build CRuby gems,
    # battle-tested by upstream.
    #
    # However,we don't know what exists in user's own MSYS2, it may lack of something.
    #
    # And there's another reason:
    #   `ridk` is in Ruby commands runtime. When any Ruby command starts, it will search
    # MSYS2 existence, hence severely affect the start up time if not quickly checked.
    #
    if (-Not (Test-Path "$env:RBENV_ROOT\msys64") )
    {
        Write-Host -f DarkYellow "Seems you have just installed rbenv, auto install MSYS2 for you"
        Write-Host -f DarkYellow "MSYS2 is must-have if you want to install gems with C extensions"

        rbenv install msys
    }

    # return instantly so that rbenv doesn't delay the user startup too much
    return
}


####################
#  source our libs
####################
# All sub commands will go here hence using our libs, so that
# there is no need to load lib in every sub command file.

. $PSScriptRoot\..\lib\core.ps1
. $PSScriptRoot\..\lib\commands.ps1
. $PSScriptRoot\..\lib\version.ps1


####################
#       main
####################
$available_commands = get_commands

if ( @('-v', '--version') -contains $cmd -or $args[0] -contains '-v') {
    # Defined at the top of this file
    $RBENV_OWN_VERSION
}

elseif ( @($null, '--help', '/?') -contains $cmd -or $args[0] -contains '-h') {
    command_exec 'help' $args
}

# Delegate to sub commands
elseif ($available_commands -contains $cmd) {
    command_exec $cmd $args
}

else {
    "rbenv: '$cmd' isn't a rbenv command. See 'rbenv help'."; exit 1
}
