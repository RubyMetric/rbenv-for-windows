# ---------------------------------------------------------------
# File          : ruby.ps1
# Authors       : ccmywish <ccmywish@qq.com>
# Created on    : <2023-03-03>
# Last modified : <2023-03-03>
#
# ruby:
#
#   Delegate to real ruby.exe
#
#   Relay: about 95ms
#
# ----------
# Note:
#
# When you type 'ruby',     this file is hit
# When you type 'ruby.exe', this file is NOT hit,
#                           instead, ruby.exe in rbenv\bin is hit
# ---------------------------------------------------------------

. $env:RBENV_ROOT\rbenv\lib\version.ps1

$version, $_ = get_current_version_with_setmsg_from_fake_ruby

$rubyexe = get_ruby_exe_location_by_version "ruby" $version

& $rubyexe $args
