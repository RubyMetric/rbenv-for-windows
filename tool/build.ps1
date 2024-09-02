# ---------------------------------------------------------------
# SPDX-License-Identifier: MIT
# ---------------------------------------------------------------
# File Name     : build.ps1
# File Authors  : Aoran Zeng <ccmywish@qq.com>
# Created On    : <2023-03-04>
# Last Modified : <2024-09-02>
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
#       (2) ./build fast
#
#       (3) ./build export
# ---------------------------------------------------------------

# working dir, is not where this script locates
# (get-location).path

param($option)

$dir = "$env:RBENV_ROOT\rbenv"

function build_fake_ruby($fastmode) {
    if(!$fastmode) {
        $flags = '-O', '-release', '-inline'
    }
    dmd $flags -of="$dir\bin\ruby.exe" "$dir\source\ruby.d" "$dir\source\rbenv\common.d"
}

function build_rbenv_exec($fastmode) {
    if(!$fastmode) {
        $flags = '-O', '-release', '-inline';
    }
    dmd $flags -of="$dir\libexec\rbenv-exec.exe" "$dir\source\rbenv-exec.d" "$dir\source\rbenv\common.d"
}


if ($option -eq 'fast') {
    Write-Host "rbenv: Fast Building fake ruby.exe to $dir\bin\"
    build_fake_ruby fast
    Write-Host "rbenv: Fast Building rbenv-exec.exe to $dir\libexec\"
    build_rbenv_exec fast
} else {
    Write-Host "rbenv: Building fake ruby.exe to $dir\bin\"
    build_fake_ruby
    Write-Host "rbenv: Building rbenv-exec.exe to $dir\libexec\"
    build_rbenv_exec
}


if ($option -eq 'export') {
    $dest = "$HOME\Desktop\rbenv-for-Windows-export"
    mkdir $dest | Out-Null

    Copy-Item $dir\bin\ruby.exe $dest
    Copy-Item $dir\libexec\rbenv-exec.exe $dest

    $content = 'v' + (Get-Date -Format "yyyy-MM-dd") + "`n# Don't Edit Me!"
    $file = "$dest\upstream-rbenv-binary-version.txt"
    Set-Content -Path $file -Value $content

    Write-Host "rbenv: Copy built files to $dest"
}
