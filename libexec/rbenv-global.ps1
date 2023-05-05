# Usage: rbenv global [<version>]
# Summary: Set or show the global Ruby version

param($cmd)

function set_global_version($version) {

    $version = auto_fix_version_for_installed $version

    $version | Out-File $GLOBAL_VERSION_FILE -NoNewline -Encoding ascii

    success "rbenv: Change to global version '$version'"

    # <2023-05-05> Although I've fixed the bug of bundler process to successfully trigger
    # the post-install hook in the share/rubygems_plugins.rb
    # And then, `rbenv rehash` after a `rbenv global` is no longer needed.
    #
    # But I think it now can be a second safeguard to ensure all gems' executables are there
    # in the shims dir. So I keep this statement.
    rbenv rehash version $version
}


if (! $cmd) {
  get_global_version
} else {
  set_global_version $cmd
}
