# ---------------------------------------------------------------
# File          : install.ps1
# Authors       : Aoran Zeng <ccmywish@qq.com>
# Created On    : <2023-03-04>
# Last Modified : <2024-08-24>
#
# install:
#
#   It installs/(Or Update) rbenv for Windows for users
# ----------
param($cmd, $config)

$tag = "latest-binary"

if ($config -eq "cn") {
    $repo    = "https://gitee.com/ccmywish/rbenv-for-windows"
    $welcome = "rbenv: Downloading pre-compiled binaries from Gitee... "
} else {
    $repo    = "https://github.com/ccmywish/rbenv-for-windows"
    $welcome = "rbenv: Downloading pre-compiled binaries from GitHub... "
}
# ---------------------------------------------------------------

$goodbye = "Finished"
$err_msg = 'rbenv installer: You must define $env:RBENV_ROOT first'
$install = 'rbenv: Installation complete!'
$update  = 'rbenv: Update complete!'


function download_binaries() {
    Write-Host -f green $welcome -NoNewline

    # Explicitly use curl.exe rather than curl
    # Because on PowerShell v5.1, curl is aliased to `Invoke-Webrequest` by default
    curl.exe -sSL "$repo/releases/download/$tag/ruby.exe" -o "$env:RBENV_ROOT\rbenv\bin\ruby.exe"

    curl.exe -sSL "$repo/releases/download/$tag/rbenv-exec.exe" -o "$env:RBENV_ROOT\rbenv\libexec\rbenv-exec.exe"

    Write-Host -f green $goodbye
}

if ($cmd -eq "update") {
    # git -C $env:RBENV_ROOT\rbenv pull # THIS IS ALREADY DONE in rbenv-update.ps1
    download_binaries
    Write-Host -f green $update

} elseif($env:RBENV_ROOT) {
    # Install
    mkdir $env:RBENV_ROOT
    git -C $env:RBENV_ROOT clone $repo rbenv
    download_binaries
    Write-Host -f green $install

} else {
    Write-Error $err_msg
}
