# ---------------------------------------------------------------
# File          : install.ps1
# Authors       : Aoran Zeng <ccmywish@qq.com>
# Created on    : <2023-03-04>
# Last modified : <2023-03-05>
#
# install:
#
#   It installs rbenv for Windows for common users
#
# ----------
param($cmd)
$repo = "https://github.com/ccmywish/rbenv-for-windows"
$tag  = "v1.4.3"
# ---------------------------------------------------------------

function download_binaries() {
    Write-Host -f blue "rbenv: Downloading pre-compiled binaries..."

    curl -sSL "$repo/releases/download/$tag/ruby.exe" -o "$env:RBENV_ROOT\rbenv\bin\ruby.exe"

    curl -sSL "$repo/releases/download/$tag/rbenv-exec.exe" -o "$env:RBENV_ROOT\rbenv\libexec\rbenv-exec.exe"

    Write-Host -f green "rbenv: Install finish!"
}

if ($cmd -eq "update") {
    # noop
} elseif($env:RBENV_ROOT) {
    mkdir $env:RBENV_ROOT
    git -C $env:RBENV_ROOT clone $repo rbenv
    download_binaries
} else {
    Write-Error 'rbenv installer: You must define $env:RBENV_ROOT first'
}
