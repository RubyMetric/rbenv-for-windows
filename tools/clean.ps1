# ---------------------------------------------------------------
# File          : clean.ps1
# Authors       : ccmywish <ccmywish@qq.com>
# Created on    : <2023-03-04>
# Last modified : <2023-03-04>
# Contributors  :
#
# clean:
#
#   Clean binaries for rbenv for Windows from Dlang files.
#
# ----------
# Changelog:
#
# ~> v0.1.0
# <2023-03-04> Create file
# ---------------------------------------------------------------

$dir = "$env:RBENV_ROOT\rbenv"

function clean_fake_ruby() {
    rm "$dir\bin\ruby.exe"
    rm "$dir\bin\ruby.obj"
}

function clean_rbenv_rehash() {
    rm "$dir\libexec\rbenv-rehash.exe"
    rm "$dir\libexec\rbenv-rehash.obj"
}


Write-Host "rbenv: Clean fake ruby.exe/.obj in $dir\bin\"
clean_fake_ruby
Write-Host "rbenv: Clean rbenv-rehash.exe/.obj in $dir\libexec\"
clean_rbenv_rehash
