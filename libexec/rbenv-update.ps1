# Usage: rbenv update [<rbenv>]
# Summary: Update rbenv or MSYS2
# Help: rbenv update          => Update rbenv itself
# rbenv update rbenv    => Update rbenv itself
# rbenv update msys     => Update msys2
# rbenv update msys2    => Same with 'update msys'

param($cmd)

function update_rbenv {
    git -C $env:RBENV_ROOT\rbenv pull
}


function update_msys2 {
    # ridk exec "pacman -Syu"
    ridk install 2
}


if (! $cmd) {
    update_rbenv
} elseif ($cmd -eq 'rbenv') {
    update_rbenv
} elseif ($cmd -eq 'msys' -or $cmd -eq 'msys2' ) {
    update_msys2
} else {
    rbenv help update
}
