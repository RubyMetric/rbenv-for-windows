# Usage: rbenv whence [<executable>]
# Summary: List all Ruby versions that contain the given executable


param($cmd)


if (!$cmd) {
    rbenv help whence
} else {
     & "$env:RBENV_ROOT\rbenv\libexec\rbenv-exec.exe" list-who-has $cmd
}
