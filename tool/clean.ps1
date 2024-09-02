# ---------------------------------------------------------------
# SPDX-License-Identifier: MIT
# ---------------------------------------------------------------
# File Name     : clean.ps1
# File Authors  : Aoran Zeng <ccmywish@qq.com>
# Created On    : <2023-03-04>
# Last Modified : <2023-03-05>
#
# clean:
#
#   Clean binaries for rbenv for Windows from Dlang files.
# ---------------------------------------------------------------

$dir = "$env:RBENV_ROOT\rbenv"

function clean_fake_ruby() {
    Remove-Item "$dir\bin\ruby.exe"
    Remove-Item "$dir\bin\ruby.obj"
}

function clean_rbenv_exec() {
    Remove-Item "$dir\libexec\rbenv-exec.exe"
    Remove-Item "$dir\libexec\rbenv-exec.obj"
}


Write-Host "rbenv: Clean fake ruby.exe/.obj in $dir\bin\"
clean_fake_ruby
Write-Host "rbenv: Clean rbenv-exec.exe/.obj in $dir\libexec\"
clean_rbenv_exec
