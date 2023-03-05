# ---------------------------------------------------------------
# File          : install-cn.ps1
# Authors       : Aoran Zeng <ccmywish@qq.com>
# Created on    : <2023-03-04>
# Last modified : <2023-03-05>
# Contributors  :
#
# install-cn:
#
#   It installs rbenv for Windows for Chinese users
#
# ----------
param($cmd)
$repo = "https://gitee.com/ccmywish/rbenv-for-windows"
$tag  = "v1.4.3"
# ---------------------------------------------------------------

function download_binaries() {
    Write-Host -f blue "rbenv: 下载预编译二进制文件..."

    curl -sSL "$repo/releases/download/$tag/ruby.exe" -o "$env:RBENV_ROOT\rbenv\bin\ruby.exe"

    curl -sSL "$repo/releases/download/$tag/rbenv-exec.exe" -o "$env:RBENV_ROOT\rbenv\libexec\rbenv-exec.exe"

    Write-Host -f green "rbenv: 安装完成!"
}


if ($cmd -eq "update") {
    # noop
} elseif($env:RBENV_ROOT) {
    mkdir $env:RBENV_ROOT
    git -C $env:RBENV_ROOT clone $repo rbenv
    download_binaries
} else {
    Write-Error 'rbenv installer: 您必须首先定义 $env:RBENV_ROOT'
}
