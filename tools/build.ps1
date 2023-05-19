# ---------------------------------------------------------------
# File          : build.ps1
# Authors       : Aoran Zeng <ccmywish@qq.com>
# Created on    : <2023-03-04>
# Last modified : <2023-05-19>
#
# build:
#
#   Build binaries for rbenv for Windows from Dlang files.
#
#   I write this in PowerShell rather than Rakefile just to avoid
#   calling Ruby in the worst case.
#
#   Usage:
#
#       (1) ./build
#
#       (2) ./build export
# ---------------------------------------------------------------

# working dir, is not where this script locates
# (get-location).path

param($to_export)

$dir = "$env:RBENV_ROOT\rbenv"

function build_fake_ruby() {
    dmd -O -release -inline -of="$dir\bin\ruby.exe" "$dir\source\ruby.d" "$dir\source\rbenv\common.d"
}

function build_rbenv_exec() {
    dmd -O -release -inline -of="$dir\libexec\rbenv-exec.exe" "$dir\source\rbenv-exec.d" "$dir\source\rbenv\common.d"
}

Write-Host "rbenv: Building fake ruby.exe to $dir\bin\"
build_fake_ruby
Write-Host "rbenv: Building rbenv-exec.exe to $dir\libexec\"
build_rbenv_exec


if ($to_export -eq 'export') {
    $dest = "$HOME\Desktop\rbenv-for-Windows-export"
    mkdir $dest | Out-Null

    cp $dir\bin\ruby.exe $dest
    cp $dir\libexec\rbenv-exec.exe $dest
    Write-Host "rbenv: Copy built files to $dest"
}

