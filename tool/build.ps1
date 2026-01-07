# ---------------------------------------------------------------
# SPDX-License-Identifier: MIT
# ---------------------------------------------------------------
# File Name     : build.ps1
# File Authors  : Aoran Zeng <ccmywish@qq.com>
# Created On    : <2023-03-04>
# Last Modified : <2026-01-07>
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
#
#   You can also change the compiler by using '-compiler dmd' not '-compiler=dmd'
# ---------------------------------------------------------------

# working dir, is not where this script locates
# (get-location).path

param($option, $compiler = "ldc2")

$dir = "$env:RBENV_ROOT\rbenv"

$script:compiler_flags = @()

function set_compiler_flags($fast_mode) {
    if ($compiler -eq "ldc2") {
        use_ldc2 $fast_mode
    }

    elseif ($compiler -eq "dmd") {
        use_dmd $fast_mode
    }

    else {
        Write-Host "Unsupported D compiler: $compiler"
        exit 1
    }
}

function use_dmd($fast_mode) {
    if (!$fast_mode) {
        $script:compiler_flags = '-O', '-release', '-inline'
    } else {
        $script:compiler_flags = @()
    }
}

function use_ldc2($fast_mode) {
    if (!$fast_mode) {
        # ldc2's -O is -O3
        # ldc2 doesn't support '-inline'
        $script:compiler_flags = '-O', '-release'
    } else {
        $script:compiler_flags = @()
    }
}


function build_fake_ruby() {
    & $compiler $script:compiler_flags -of="$dir\bin\ruby.exe" "$dir\source\ruby.d" "$dir\source\rbenv\common.d"
}

function build_rbenv_exec() {
    & $compiler $script:compiler_flags -of="$dir\libexec\rbenv-exec.exe" "$dir\source\rbenv-exec.d" "$dir\source\rbenv\common.d"
}


# main
if ($option -eq 'fast') {
    set_compiler_flags $true
} else {
    set_compiler_flags $false
}

Write-Host "rbenv: " -NoNewline
if ($option -eq 'fast') {
    Write-Host "(fast mode) " -ForegroundColor Yellow -NoNewline
}
Write-Host "Using " -NoNewline
Write-Host "$compiler" -ForegroundColor Blue -NoNewline
Write-Host " with " -NoNewline
Write-Host "$script:compiler_flags" -ForegroundColor Magenta

Write-Host "rbenv: Building fake ruby.exe to $dir\bin\"
build_fake_ruby
Write-Host "rbenv: Building rbenv-exec.exe to $dir\libexec\"
build_rbenv_exec


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
