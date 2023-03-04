# ---------------------------------------------------------------
# File          : build.ps1
# Authors       : Aoran Zeng <ccmywish@qq.com>
# Created on    : <2023-03-04>
# Last modified : <2023-03-04>
# Contributors  :
#
# build:
#
#   Build binaries for rbenv for Windows from Dlang files.
#
#   I write this in PowerShell rather than Rakefile just to avoid
#   calling Ruby in the worst case.
#
# ----------
# Changelog:
#
# ~> v0.1.0
# <2023-03-04> Create file
# ---------------------------------------------------------------

# working dir, is not where this script locates
# (get-location).path

$dir = "$env:RBENV_ROOT\rbenv"

function build_fake_ruby() {
    dmd -O -release -inline -of="$dir\bin\ruby.exe" "$dir\bin\source\ruby.d" "$dir\bin\source\rbenv.d"
}

function build_rbenv_rehash() {
    dmd -O -release -inline -of="$dir\libexec\rbenv-rehash.exe" "$dir\bin\source\rbenv-rehash.d" "$dir\bin\source\rbenv.d"
}


Write-Host "rbenv: Build fake ruby.exe to $dir\bin\"
build_fake_ruby
Write-Host "rbenv: Build rbenv-rehash.exe to $dir\libexec\"
build_rbenv_rehash
