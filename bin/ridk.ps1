# ---------------------------------------------------------------
# File          : ridk.ps1
# Authors       : Aoran Zeng <ccmywish@qq.com>
# Created on    : <2023-08-01>
# Last modified : <2023-08-01>
#
# ruby:
#
#   Delegate to real ridk.ps1
#
# ----------
# Note:
#
# When you type 'ridk',                   this file is hit
# When you type 'ridk.ps1' or 'ridk.cmd', Nothing will be hit
# ---------------------------------------------------------------

. $env:RBENV_ROOT\rbenv\lib\version.ps1

$version, $_ = get_current_version_with_setmsg_from_fake_ruby

$rubyexe = get_ruby_exe_location_by_version "ridk" $version

& $rubyexe $args
