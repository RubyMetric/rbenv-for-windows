# ---------------------------------------------------------------
# File          : rbenv.ps1
# Authors       : ccmywish <ccmywish@qq.com>
# Created on    : <2022-05-02>
# Last modified : <2022-05-02>
#
# rbenv:
#
#               rbenv for Windows
#
# ----------
# Changelog:
#
# ~> v0.1.0
# <2022-05-02> Create file
# ---------------------------------------------------------------

<#

Comment:

#>

param($cmd)

. $PSScriptRoot\..\lib\commands.ps1




$GLOBAL_VERSION_FILE = "$env:RBENV_ROOT\global.txt"

if (! Test-Path $GLOBAL_VERSION_FILE ) {
  New-Item $GLOBAL_VERSION_FILE
}

$env:RBENV_VERSION_GLOBAL = Get-Content $GLOBAL_VERSION_FILE

$ruby_version_global_path = "$env:RBENV_ROOT\$env:RBENV_VERSION_GLOBAL\bin"
$env:PATH += ";$ruby_version_global_path"

haha
