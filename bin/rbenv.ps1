# ---------------------------------------------------------------
# File          : rbenv.ps1
# Authors       : ccmywish <ccmywish@qq.com>
#                 Scoop Contributoers
# Created on    : <2022-05-02>
# Last modified : <2022-05-06>
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
$RBENV_VERSION       = "rbenv v0.1.0"

# [Hash]
# Ruby directly installed by RubyInstaller2 GUI
# ${ Version ; Path }
# Only assigned in 'rbenv init'
# $env:RBENV_SYSTEM_RUBY

# [String]
# Where we check the global version
$GLOBAL_VERSION_FILE = "$env:RBENV_ROOT\global.txt"



# The init process does three things:
#
# 1. Add two paths at the front of the user PATH (almost no delay)
# 2. Ensure global.txt (   1ms    delay)
# 3. Check system Ruby (10ms~20ms delay)
#
if ($cmd -eq "init") {
    $rbenv_path_first = "$env:RBENV_ROOT\rbenv\bin;" + "$env:RBENV_ROOT\shims\bin;"
    $env:PATH = $rbenv_path_first + $env:PATH

    # Ensure our global.txt file
    if (-Not (Test-Path $GLOBAL_VERSION_FILE) ) {
        # Defined at the top
        New-Item $GLOBAL_VERSION_FILE
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
            warn "rbenv: Only one system Ruby is support, but you've installed $($keys.Count)"
        }
        if ($k = $keys[0]) {
            $SYSTEM_RUBY = @{
                Version = $k.GetValue('DisplayVersion') ;
                Path    = $k.GetValue('InstallLocation')
            }
        }
    }

    # return instantly so that rbenv doesn't delay the user startup too much
    return
}


####################
#  source our libs
####################
. $PSScriptRoot\..\lib\core.ps1
. $PSScriptRoot\..\lib\commands.ps1
. $PSScriptRoot\..\lib\version.ps1


####################
#       main
####################
$available_commands = get_commands

if ( @('-v', '--version') -contains $cmd -or $args[0] -contains '-v') {
    # Defined at the top of this file
    $RBENV_VERSION
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
