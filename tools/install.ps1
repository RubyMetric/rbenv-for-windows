# ---------------------------------------------------------------
# File          : install.ps1
# Authors       : Aoran Zeng <ccmywish@qq.com>
# Created on    : <2023-03-04>
# Last modified : <2023-04-03>
#
# install:
#
#   It installs/(Or Update) rbenv for Windows for common users
#
# ----------
param($cmd, $config)

$tag = "latest-binary"

if ($config -eq "cn") {
    $repo    = "https://gitee.com/ccmywish/rbenv-for-windows"
    $welcome = "rbenv: 从Gitee下载预编译二进制文件..."
    $goodbye = "rbenv: 安装完成!"
    $err_msg = 'rbenv installer: 您必须首先定义 $env:RBENV_ROOT'
} else {
    $repo    = "https://github.com/ccmywish/rbenv-for-windows"
    $welcome = "rbenv: Downloading pre-compiled binaries from GitHub..."
    $goodbye = "rbenv: Install finish!"
    $err_msg = 'rbenv installer: You must define $env:RBENV_ROOT first'
}
# ---------------------------------------------------------------

function download_binaries() {
    Write-Host -f green $welcome

    curl -sSL "$repo/releases/download/$tag/ruby.exe" -o "$env:RBENV_ROOT\rbenv\bin\ruby.exe"

    curl -sSL "$repo/releases/download/$tag/rbenv-exec.exe" -o "$env:RBENV_ROOT\rbenv\libexec\rbenv-exec.exe"

    Write-Host -f green $goodbye
}

if ($cmd -eq "update") {
    # noop
} elseif($env:RBENV_ROOT) {
    mkdir $env:RBENV_ROOT
    git -C $env:RBENV_ROOT clone $repo rbenv
    download_binaries
} else {
    Write-Error $err_msg
}
