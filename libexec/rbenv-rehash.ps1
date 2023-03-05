# Usage: rbenv rehash [<command>] [<version/gem>]
# Summary: Rehash rbenv shims (run this after installing gems)
# Help: rbenv rehash                => rehash the current version
# rbenv rehash version xxx    => rehash all gems in specific version
# rbenv rehash gem xxx        => rehash a gem
#

param($cmd, $argument)


function rehash_single_gem ($name, $echo_or_not=$True) {
    & "$env:RBENV_ROOT\rbenv\libexec\rbenv-exec.exe" rehash-gem $name
}


function rehash_version ($version) {
    & "$env:RBENV_ROOT\rbenv\libexec\rbenv-exec.exe" rehash-version $version
}


if (!$cmd) {
    $version, $_ = get_current_version_with_setmsg_from_fake_ruby
    rehash_version $version

} elseif ($cmd -eq 'version') {
    if (!$argument) { rbenv help rehash; return}
    rehash_version $argument

} elseif ($cmd -eq 'gem') {
    if (!$argument) { rbenv help rehash; return}
    rehash_single_gem $argument

} else {
    rbenv help rehash
}
