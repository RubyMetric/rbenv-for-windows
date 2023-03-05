# ---------------------------------------------------------------
# File          : clean.ps1
# Authors       : Aoran Zeng <ccmywish@qq.com>
# Created on    : <2023-03-04>
# Last modified : <2023-03-05>
#
# clean:
#
#   Clean binaries for rbenv for Windows from Dlang files.
# ---------------------------------------------------------------

$dir = "$env:RBENV_ROOT\rbenv"

function clean_fake_ruby() {
    rm "$dir\bin\ruby.exe"
    rm "$dir\bin\ruby.obj"
}

function clean_rbenv_exec() {
    rm "$dir\libexec\rbenv-exec.exe"
    rm "$dir\libexec\rbenv-exec.obj"
}


Write-Host "rbenv: Clean fake ruby.exe/.obj in $dir\bin\"
clean_fake_ruby
Write-Host "rbenv: Clean rbenv-exec.exe/.obj in $dir\libexec\"
clean_rbenv_exec
