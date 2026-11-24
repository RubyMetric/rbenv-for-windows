# ---------------------------------------------------------------
# SPDX-License-Identifier: MIT
# ---------------------------------------------------------------
# File Name      : install.ps1
# File Authors   : Aoran Zeng <ccmywish@qq.com>
# Created On     : <2023-03-04>
# Major Revision :      5
# Last Modified  : <2026-11-24>
# Encoding       : UTF-8 with BOM (required for PowerShell 5.1
#                | compatibility with ZH characters)
#
# install:
#
#   It installs/(Or Update) rbenv for Windows for users
#
# ---------------------------------------------------------------
param($cmd, $config)

$tag = "latest-binary"

$etag_filename = "rbenv-ETag.txt"
$remote_etag_filename = "remote-rbenv-ETag.txt"

if ($config -eq "cn") {
              $repo = "https://gitee.com/RubyMetric/rbenv-for-windows"
       $dld_bin_msg = "从 Gitee 下载预编译二进制文件... "
      $dld_etag_msg_when_comparing = "检查仓库中的 $remote_etag_filename... "
     $dld_etag_msg_when_missing = "设置本地 $etag_filename... "
} else {
              $repo = "https://github.com/RubyMetric/rbenv-for-windows"
       $dld_bin_msg = "Downloading pre-compiled binaries from GitHub... "
      $dld_etag_msg_when_comparing = "Checking $remote_etag_filename from the repository... "
     $dld_etag_msg_when_missing = "Setting local $etag_filename... "
}
# ---------------------------------------------------------------

$remote_etag_file = "$env:RBENV_ROOT\rbenv\share\$remote_etag_filename"
$local_etag_file  = "$env:RBENV_ROOT\$etag_filename"


function download_binary_files() {
    Write-Host -f Blue $dld_bin_msg -NoNewline

    # Explicitly use curl.exe rather than curl
    # Because on PowerShell v5.1, curl is aliased to `Invoke-Webrequest` by default
    curl.exe -fsSL "$repo/releases/download/$tag/ruby.exe" -o "$env:RBENV_ROOT\rbenv\bin\ruby.exe"

    curl.exe -fsSL "$repo/releases/download/$tag/rbenv-exec.exe" -o "$env:RBENV_ROOT\rbenv\libexec\rbenv-exec.exe"

    Write-Host -f Green "Finished"
}


function update_when_local_etagfile_exist() {
    Write-Host -f Blue $dld_etag_msg_when_comparing -NoNewline

    if ($True -eq (is_binary_latest)) {
        Write-Host -f Green  "Already Latest"
    } else {
        Write-Host -f Yellow "Outdated"
        download_binary_files
        Copy-Item $remote_etag_file $local_etag_file
        Write-Host -f Green "Update the local $etag_filename"
    }
}


function update_when_local_etagfile_missing() {
<#
.DESCRIPTION
For:
    1. old users' transition
    2. $local_etag_file was accidentally deleted
#>
    Write-Host -f Yellow "Lacking of local $etag_filename, rbenv will prepare it for you"
    Write-Host -f Blue $dld_etag_msg_when_missing -NoNewline

    download_binary_files
    Copy-Item $remote_etag_file $local_etag_file
    Write-Host -f Green "OK!"
}


function is_binary_latest()
{
    $local_ver    = Get-Content $local_etag_file    -TotalCount 1
    $remote_ver   = Get-Content $remote_etag_file   -TotalCount 1

    if ($local_ver -ne $remote_ver) {
        return $False
    } else {
        return $True
    }
}


if ($cmd -eq "update") { # update

    # (1)
    Write-Host -f Blue "Git pulling the latest source of rbenv..."
    git -C $env:RBENV_ROOT\rbenv pull

    # (2)
    if (Test-Path $local_etag_file) {
        update_when_local_etagfile_exist
    } else {
        update_when_local_etagfile_missing
    }

    # (END)
    Write-Host -f Green 'rbenv: Update complete!'

} else { # Install

    if ($env:RBENV_ROOT) {
        mkdir $env:RBENV_ROOT

        # (1)
        git -C $env:RBENV_ROOT clone $repo rbenv

        # (2)
        download_binary_files

        # (3)
        Write-Host -f Blue $dld_etag_msg_when_missing -NoNewline
        Copy-Item $remote_etag_file $local_etag_file
        Write-Host -f Green "OK!"

        # (END)
        Write-Host -f Green 'rbenv-installer: Installation complete!'

    } else {
        Write-Error 'rbenv-installer: You must define $env:RBENV_ROOT first'
    }
}
