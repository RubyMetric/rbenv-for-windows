# Usage: rbenv which [<executable>]
# Summary: Display the full path to an executable

param($cmd)


if (!$cmd) {
    rbenv help which
} else {
    get_executable_location $cmd
}
