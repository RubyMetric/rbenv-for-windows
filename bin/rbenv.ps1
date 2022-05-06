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


# The init process only does one things:
#
# => Add two paths at the front of the user PATH
#
if ($cmd -eq "init") {
    $rbenv_path_first = "$env:RBENV_ROOT\rbenv\bin;" + "$env:RBENV_ROOT\shims\bin;"
    $env:PATH = $rbenv_path_first + $env:PATH
    # return instantly so that rbenv doesn't delay the user startup too much
    return
}


########################################
#       Inner global variables
########################################
# [String]
# rbenv's own version
$RBENV_VERSION       = "rbenv v0.1.0"

# [Hash]
# Ruby directly installed by RubyInstaller2 GUI
# ${ Version ; Path }
$SYSTEM_RUBY         = $NULL

# [String]
# Where we check the global version
$GLOBAL_VERSION_FILE = "$env:RBENV_ROOT\global.txt"


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
