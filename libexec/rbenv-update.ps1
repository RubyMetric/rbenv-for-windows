# Usage: rbenv update [<rbenv>]
# Summary: Update rbenv or MSYS2
# Help: rbenv update          => Update rbenv itself
# rbenv update cn       => Update rbenv itself for Chinese users
# rbenv update rbenv    => Update rbenv itself
# rbenv update msys     => Update msys2
# rbenv update msys2    => Same with 'update msys'
# rbenv update devkit   => Same with 'update msys'

param($cmd)


# Invoke external script to update
function update_rbenv($config) {

    if ($config -eq "cn") {
        & "$env:RBENV_ROOT\rbenv\tool\install.ps1" update cn
    } else {
        & "$env:RBENV_ROOT\rbenv\tool\install.ps1" update
    }
}


function update_msys2 {
    # ridk exec "pacman -Syu"
    ridk install 2
}


if (! $cmd) {
    update_rbenv
} elseif ($cmd -eq 'rbenv') {
    update_rbenv
} elseif ($cmd -eq 'cn') {
    update_rbenv 'cn'
} elseif ($cmd -eq 'msys' -or $cmd -eq 'msys2' -or $cmd -eq 'devkit' ) {
    update_msys2
} else {
    rbenv help update
}
