# Usage: rbenv global [<version>]
# Summary: Set or show the global Ruby version

param($cmd)

function set_global_version($version) {

    $version = auto_fix_version_for_installed $version

    $version | Out-File $GLOBAL_VERSION_FILE -NoNewline -Encoding ascii

    success "rbenv: Change to global version '$version'"

    # As the share/rubygems_plugins.rb says
    # This is a compromise for Bundler's failure on triggering the post-install hook
    rbenv rehash version $version
}


if (! $cmd) {
  get_global_version
} else {
  set_global_version $cmd
}
