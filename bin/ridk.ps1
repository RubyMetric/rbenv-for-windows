# ---------------------------------------------------------------
# Copyright © 2023-2026 Aoran Zeng
# SPDX-License-Identifier: MIT
# ---------------------------------------------------------------
# File          : ridk.ps1
# Authors       : Aoran Zeng <ccmywish@qq.com>
# Created on    : <2023-08-01>
# Last modified : <2026-11-25>
#
# ruby:
#
#   Delegate to real 'ridk.ps1' or 'ridk.cmd'
#
# ----------
# Note:
#
# When you type 'ridk' or 'ridk.ps1',  this file is hit
# When you type 'ridk.bat',            this file is NOT hit
# ---------------------------------------------------------------

. $env:RBENV_ROOT\rbenv\lib\version.ps1

$version, $_ = get_current_version_with_setmsg_from_fake_ruby

$rubyexe = get_ridk_location_by_version $version

& $rubyexe @args

if (-not $?) {
    if ($LASTEXITCODE -eq 0) { exit 1 }
    exit $LASTEXITCODE
}
