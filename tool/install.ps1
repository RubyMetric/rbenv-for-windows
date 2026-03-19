# ---------------------------------------------------------------
# SPDX-License-Identifier: MIT
# ---------------------------------------------------------------
# File Name      : install.ps1
# File Authors   : Aoran Zeng <ccmywish@qq.com>
# Created On     : <2023-03-04>
# Major Revision :      5
# Last Modified  : <2026-01-07>
#
# install:
#
#   It installs/(Or Update) rbenv for Windows for users
# ---------------------------------------------------------------
param($cmd, $config)

$tag = "latest-binary"

$etag_filename = "rbenv-ETag.txt"

if ($config -eq "cn") {
              $repo = "https://gitee.com/RubyMetric/rbenv-for-windows"
       $dld_bin_msg = "从 Gitee 下载预编译二进制文件... "
      $dld_etag_msg_when_comparing = "从 Gitee 检查 $etag_filename... "
     $dld_etag_msg_when_missing = "下载 $etag_filename... "
} else {
              $repo = "https://github.com/RubyMetric/rbenv-for-windows"
       $dld_bin_msg = "Downloading pre-compiled binaries from GitHub... "
      $dld_etag_msg_when_comparing = "Checking $etag_filename from GitHub... "
     $dld_etag_msg_when_missing = "Downloading $etag_filename... "
}
# ---------------------------------------------------------------

$upstream_etag_filename = "upstream-$etag_filename"
$upstream_etag_file     = "$env:RBENV_ROOT\$upstream_etag_filename"
$local_etag_file        = "$env:RBENV_ROOT\$etag_filename"


function download_binary_files() {
    Write-Host -f Blue $dld_bin_msg -NoNewline

    # Explicitly use curl.exe rather than curl
    # Because on PowerShell v5.1, curl is aliased to `Invoke-Webrequest` by default
    curl.exe -fsSL "$repo/releases/download/$tag/ruby.exe" -o "$env:RBENV_ROOT\rbenv\bin\ruby.exe"

    curl.exe -fsSL "$repo/releases/download/$tag/rbenv-exec.exe" -o "$env:RBENV_ROOT\rbenv\libexec\rbenv-exec.exe"

    Write-Host -f Green "Finished"
}


function download_etag_file($type, $etag_file_status) {
<#
.PARAMETER type
    'install'  : when installing rbenv for the first time
    'update'   : when updating rbenv
.PARAMETER etag_file_status
    'exist'    : when the local etag file exists  ($type can be 'update' only)
    'missing'  : when the local etag file missing ($type can be 'install' or 'update')
#>
    if ($type -eq 'update' -and $etag_file_status -eq 'exist') {
        Write-Host -f Blue $dld_etag_msg_when_comparing -NoNewline
    } else {
        Write-Host -f Blue $dld_etag_msg_when_missing -NoNewline
    }

    # We must use -f, otherwise "not found" will also cause non-zero exit code
    curl.exe -fsSL "$repo/releases/download/$tag/$upstream_etag_filename" -o $upstream_etag_file

    if ($?) {
        if ($etag_file_status -eq 'missing') {
            Write-Host -f Green "OK!"
        } else {
            # Leave for the next step to output inline!
        }
    } else {
        # Don't use Write-Error here, because it will output extra info
        Write-Host -f Red "Download Error! $LASTEXITCODE"
        exit 1
    }
}


function update_when_local_etagfile_exist() {
    download_etag_file "update" "exist"

    if ($True -eq (is_binary_latest)) {
        Write-Host -f Green  "Already Latest"
    } else {
        Write-Host -f Yellow "Outdated"
        download_binary_files
        Copy-Item $upstream_etag_file $local_etag_file
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
    download_etag_file "update" "missing"

    download_binary_files
    Copy-Item $upstream_etag_file $local_etag_file
}


function is_binary_latest()
{
    $local_ver    = Get-Content $local_etag_file    -TotalCount 1
    $upstream_ver = Get-Content $upstream_etag_file -TotalCount 1

    if ($local_ver -ne $upstream_ver) {
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
    Remove-Item $upstream_etag_file
    Write-Host -f Green 'rbenv: Update complete!'

} else { # Install

    if ($env:RBENV_ROOT) {
        mkdir $env:RBENV_ROOT

        # (1)
        git -C $env:RBENV_ROOT clone $repo rbenv

        # (2)
        download_binary_files
        download_etag_file "install" "missing"

        # (3)
        Copy-Item $upstream_etag_file $local_etag_file
        # Write-Host -f Green "Set the local $etag_filename"

        # (END)
        Remove-Item $upstream_etag_file
        Write-Host -f Green 'rbenv-installer: Installation complete!'

    } else {
        Write-Error 'rbenv-installer: You must define $env:RBENV_ROOT first'
    }
}
