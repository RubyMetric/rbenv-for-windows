# ---------------------------------------------------------------
# File          : rbenv.ps1
# Authors       : ccmywish <ccmywish@qq.com>
# Created on    : <2022-05-02>
# Last modified : <2023-02-07>
# Contributors  : Scoop Contributors
#
#
#               rbenv for Windows
#
# -------
# Note:
#
#   I reuse a lot of code pieces from [scoop]
#
#   <https://github.com/ScoopInstaller/Scoop> ("The Unlicense")
#
# ---------------------------------------------------------------

param($cmd)

########################################
#       Inner global variables
########################################
# [String]
# rbenv's own version
# Not to conflict with $env:RBENV_VERSION ('rbenv shell' sets it)
$RBENV_OWN_VERSION       = "rbenv v1.2.0"

# [String]
# Where we check the global version
#
# Note that We redefined it at lib\version.ps1, because
# shim will directly uses it. We don't want it
# to be $env variable.
$GLOBAL_VERSION_FILE = "$env:RBENV_ROOT\global.txt"


<#
The init process does 6 things:

    1. Add two paths at the front of the user PATH (almost no delay)
       (1.1) rbenv\bin is to delegate all rbenv commands
       (1.2) shims\bin is to delegate all Ruby commands
    2. Add one path to RUBYLIB
    3. Ensure global.txt (   1ms    delay)
    4. Check system Ruby (10ms~20ms delay)
    5. If has system Ruby, rehash it just only one time (50ms, but only when you first setup rbenv)
    6. If no the shared MSYS2, install it
#>

if ($cmd -eq "init") {
    $rbenv_path_first = "$env:RBENV_ROOT\rbenv\bin;" + "$env:RBENV_ROOT\shims\bin;"
    $env:PATH = $rbenv_path_first + $env:PATH

    # For RubyGems plugin to work
    $env:RUBYLIB += "$env:RBENV_ROOT\rbenv\share"

    # Ensure our global.txt file
    if (-Not (Test-Path $GLOBAL_VERSION_FILE) ) {
        # Defined at the top
        New-Item $GLOBAL_VERSION_FILE | Out-Null
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
            write-host -f darkyellow $msg
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

    if (-Not (Test-Path "$env:RBENV_ROOT\msys64")) {
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
