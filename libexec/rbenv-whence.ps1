# Usage: rbenv whence [<executable>]
# Summary: List all Ruby versions that contain the given executable


param($cmd)


if (!$cmd) {
    rbenv help whence
} else {
    list_who_has($cmd)
}
