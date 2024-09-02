# ---------------------------------------------------------------
# SPDX-License-Identifier: MIT
# ---------------------------------------------------------------
# File Name      : install.ps1
# File Authors   : Aoran Zeng <ccmywish@qq.com>
# Created On     : <2023-03-04>
# Major Revision :      4
# Last Modified  : <2024-09-02>
#
# install:
#
#   It installs/(Or Update) rbenv for Windows for users
# ---------------------------------------------------------------
param($cmd, $config)

$tag = "latest-binary"

$binver_filename = "rbenv-binary-version.txt"

if ($config -eq "cn") {
              $repo = "https://gitee.com/RubyMetric/rbenv-for-windows"
       $dld_bin_msg = "Downloading pre-compiled binaries from Gitee... "
    $dld_binver_msg = "Checking $binver_filename from Gitee... "
} else {
              $repo = "https://github.com/RubyMetric/rbenv-for-windows"
       $dld_bin_msg = "Downloading pre-compiled binaries from GitHub... "
    $dld_binver_msg = "Checking $binver_filename from GitHub... "
}
# ---------------------------------------------------------------

$upstream_binver_filename = "upstream-$binver_filename"
$upstream_binver_file     = "$env:RBENV_ROOT\$upstream_binver_filename"
$local_binver_file        = "$env:RBENV_ROOT\$binver_filename"


function download_binary_files() {
    Write-Host -f Blue $dld_bin_msg -NoNewline

    # Explicitly use curl.exe rather than curl
    # Because on PowerShell v5.1, curl is aliased to `Invoke-Webrequest` by default
    curl.exe -sSL "$repo/releases/download/$tag/ruby.exe" -o "$env:RBENV_ROOT\rbenv\bin\ruby.exe"

    curl.exe -sSL "$repo/releases/download/$tag/rbenv-exec.exe" -o "$env:RBENV_ROOT\rbenv\libexec\rbenv-exec.exe"

    Write-Host -f Green "Finished"
}

function download_binary_version_file($when) {
    Write-Host -f Blue $dld_binver_msg -NoNewline
    curl.exe -sSL "$repo/releases/download/$tag/$upstream_binver_filename" -o $upstream_binver_file

    if ($?) {
        if ($when -eq 'nonexist') {
            Write-Host -f Green "OK"
        } else {
            # Leave for the next step to output inline!
        }
    } else {
        Write-Error "Download Error!"
    }
}


# For:
# 1. old users' transition
# 2. $local_binver_file was accidentally deleted
function update_when_local_binverfile_exist() {
    download_binary_version_file

    if ($True -eq (is_binary_latest)) {
        Write-Host -f Green  "Already Latest"
    } else {
        Write-Host -f Yellow "Outdated"
        download_binary_files
        Copy-Item $upstream_binver_file $local_binver_file
        Write-Host -f Green "Update the local $binver_filename"
    }
}

function update_when_local_binverfile_nonexist() {
    Write-Host -f Yellow "Lacking of local $binver_filename, rbenv will auto prepare it for you"
    download_binary_version_file 'nonexist'

    download_binary_files
    Copy-Item $upstream_binver_file $local_binver_file
}


function is_binary_latest()
{
    $local_ver    = Get-Content $local_binver_file    -TotalCount 1
    $upstream_ver = Get-Content $upstream_binver_file -TotalCount 1

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
    if (Test-Path $local_binver_file) {
        update_when_local_binverfile_exist
    } else {
        update_when_local_binverfile_nonexist
    }

    # (END)
    Remove-Item $upstream_binver_file
    Write-Host -f Green 'rbenv: Update complete!'

} else { # Install

    if ($env:RBENV_ROOT) {
        mkdir $env:RBENV_ROOT

        # (1)
        git -C $env:RBENV_ROOT clone $repo rbenv

        # (2)
        download_binary_files
        download_binary_version_file "nonexist"

        # (3)
        Copy-Item $upstream_binver_file $local_binver_file
        Write-Host -f Green "Update the local $binver_filename"

        # (END)
        Remove-Item $upstream_binver_file
        Write-Host -f Green 'rbenv-installer: Installation complete!'

    } else {
        Write-Error 'rbenv-installer: You must define $env:RBENV_ROOT first'
    }
}
