# ---------------------------------------------------------------
# File          : install.ps1
# Authors       : Aoran Zeng <ccmywish@qq.com>
# Created on    : <2023-03-04>
# Last modified : <2023-03-04>
# Contributors  :
#
# install:
#
#   It installs rbenv for Windows for common users
#
# ----------
$repo = "https://github.com/ccmywish/rbenv-for-windows"
$tag  = "v1.4.1"
$binary_version = "v0.2.0"
# ---------------------------------------------------------------

if($env:RBENV_ROOT)  {

mkdir $env:RBENV_ROOT

git -C $env:RBENV_ROOT clone $repo rbenv

curl -sSL "$repo/releases/download/$tag/fake-ruby-$binary_version.exe" -o "$env:RBENV_ROOT\rbenv\bin\ruby.exe"

curl -sSL "$repo/releases/download/$tag/rbenv-rehash-$binary_version.exe" -o "$env:RBENV_ROOT\rbenv\libexec\rbenv-rehash.exe"

}

else {
    Write-Error 'rbenv installer: 您必须首先定义 $env:RBENV_ROOT'
}
