# ---------------------------------------------------------------
# File          : rbenv.ps1
# Authors       : ccmywish <ccmywish@qq.com>
#                 Scoop Contributoers
# Created on    : <2022-05-02>
# Last modified : <2022-05-06>
#
# rbenv:
#
#               rbenv for Windows
#
# -------
# Note:
#
#   I reuse a lot of code pieces from
#
#   <https://github.com/ScoopInstaller/Scoop>
#
#   Its license is "The Unlicense"
# ---------------------------------------------------------------

param($cmd)

$RBENV_VERSION = "rbenv v0.1.0"

. $PSScriptRoot\..\lib\core.ps1
. $PSScriptRoot\..\lib\commands.ps1
. $PSScriptRoot\..\lib\version.ps1


$available_commands = get_commands

if ($cmd -eq "init") {

    $rbenv_path_first = "$env:RBENV_ROOT\rbenv\bin;" + "$env:RBENV_ROOT\shims\bin;"
    $env:PATH = $rbenv_path_first + $env:PATH

    if (-Not (Test-Path $GLOBAL_VERSION_FILE) ) {
        # Defined in lib/version.ps1
        New-Item $GLOBAL_VERSION_FILE
    }
}

elseif ( @('-v', '--version') -contains $cmd -or $args[0] -contains '-v') {
    # Defined at the top of this file
    $RBENV_VERSION
}

elseif ( @($null, '--help', '/?') -contains $cmd -or $args[0] -contains '-h') {
    command_exec 'help' $args
}

elseif ($available_commands -contains $cmd) {
    command_exec $cmd $args
}

else {
    "rbenv: '$cmd' isn't a rbenv command. See 'rbenv help'."; exit 1
}
