# Usage: rbenv global [<version>]
# Summary: Set or show the global Ruby version

param($cmd)

function set_global_version($version) {

    $version = auto_fix_version_for_installed $version

    $shimsdir = "$env:RBENV_ROOT\shims"

    if (Test-Path $shimsdir) {
        # remove read-only attribute on link
        # attrib $shimsdir -R /L

        # remove the junction
        Remove-Item $shimsdir -Recurse -Force -ErrorAction Stop
    }

    if ($version -eq 'system') {
        $_, $path = get_system_ruby_version_and_path
    } else {
        $path = "$env:RBENV_ROOT\$version"
    }
    New-Item -Path $shimsdir -ItemType Junction -Value $path | Out-Null
    $version | Out-File $GLOBAL_VERSION_FILE -NoNewline

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
