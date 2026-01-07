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
#       (1) ./build                   # Used for fast development
#
#       (2) ./build -Release          # Used for testing release build
#
#       (3) ./build -Release -Export  # Used for GitHub Release
#
#   You can change the compiler by using '-Compiler dmd' not '-Compiler=dmd'
# ---------------------------------------------------------------

# working dir, is not where this script locates
# (get-location).path

param([switch]$Release, [switch]$Export, $Compiler = "ldc2")

$dir = "$env:RBENV_ROOT\rbenv"

$script:compiler_flags = @()

function set_compiler_flags($mode) {
    if ($Compiler -eq "ldc2") {
        use_ldc2 $mode
    }

    elseif ($Compiler -eq "dmd") {
        use_dmd $mode
    }

    else {
        Write-Host "Unsupported D compiler: $Compiler"
        exit 1
    }
}

function use_dmd($mode) {
    if ($mode -eq 'release') {
        $script:compiler_flags = '-O', '-release', '-inline'
    } elseif ($mode -eq 'dev') {
        $script:compiler_flags = @()
    } else {
        $script:compiler_flags = @()
    }
}

function use_ldc2($mode) {
    if ($mode -eq 'release') {
        # ldc2's -O is -O3
        # ldc2 doesn't support '-inline'
        $script:compiler_flags = '-O', '-release'
    } elseif ($mode -eq 'dev') {
        $script:compiler_flags = @()
    } else {
        $script:compiler_flags = @()
    }
}


function build_fake_ruby() {
    & $Compiler $script:compiler_flags -of="$dir\bin\ruby.exe" "$dir\source\ruby.d" "$dir\source\rbenv\common.d"
}

function build_rbenv_exec() {
    & $Compiler $script:compiler_flags -of="$dir\libexec\rbenv-exec.exe" "$dir\source\rbenv-exec.d" "$dir\source\rbenv\common.d"
}


# main
Write-Host "rbenv: " -NoNewline
if ($Release) {
    Write-Host "(release mode) " -ForegroundColor Yellow -NoNewline
    set_compiler_flags 'release'
} else {
    Write-Host "(dev mode) " -ForegroundColor Yellow -NoNewline
    set_compiler_flags 'dev'
}
Write-Host "Using " -NoNewline
Write-Host "$Compiler" -ForegroundColor Blue -NoNewline
Write-Host " with " -NoNewline
Write-Host "$script:compiler_flags" -ForegroundColor Magenta

Write-Host "rbenv: Building fake ruby.exe to $dir\bin\"
build_fake_ruby
Write-Host "rbenv: Building rbenv-exec.exe to $dir\libexec\"
build_rbenv_exec


if ($Export) {
    $dest = "$HOME\Desktop\rbenv-for-Windows-export"
    mkdir $dest | Out-Null

    Copy-Item $dir\bin\ruby.exe $dest
    Copy-Item $dir\libexec\rbenv-exec.exe $dest

    $content = 'v' + (Get-Date -Format "yyyy-MM-dd") + "`n# Don't Edit Me!"
    $file = "$dest\ETag.txt"
    Set-Content -Path $file -Value $content

    Copy-Item $file "$dest\upstream-rbenv-binary-version.txt"

    Write-Host "rbenv: Copy built files to $dest"
}
