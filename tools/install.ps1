# ---------------------------------------------------------------
# File          : install.ps1
# Authors       : Aoran Zeng <ccmywish@qq.com>
# Created on    : <2023-03-04>
# Last modified : <2023-06-07>
#
# install:
#
#   It installs/(Or Update) rbenv for Windows for users
# ----------
param($cmd, $config)

$tag = "latest-binary"

if ($config -eq "cn") {
    $repo    = "https://gitee.com/ccmywish/rbenv-for-windows"
    $welcome = "rbenv: 从Gitee下载预编译二进制文件... "
    $goodbye = "结束"
    $err_msg = 'rbenv installer: 您必须首先定义 $env:RBENV_ROOT'
    $install = 'rbenv: 安装完成!'
    $update  = 'rbenv: 更新完成!'
} else {
    $repo    = "https://github.com/ccmywish/rbenv-for-windows"
    $welcome = "rbenv: Downloading pre-compiled binaries from GitHub... "
    $goodbye = "Finished"
    $err_msg = 'rbenv installer: You must define $env:RBENV_ROOT first'
    $install = 'rbenv: Installation Complete!'
    $update  = 'rbenv: Update Complete!'
}
# ---------------------------------------------------------------

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
