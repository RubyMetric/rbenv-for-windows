# Usage: rbenv global [<version>]
# Summary: Set or show the global Ruby version

param($cmd)

function get_global_version() {
  # common.d will ensure a global.txt (but empty)
  $cont = Get-Content $GLOBAL_VERSION_FILE
  if (!$cont) {
    warn "rbenv: No global version has been set, use rbenv global <version>"
  } else {
    $cont
  }
}


function set_global_version($version) {

    $version = auto_fix_version_for_installed $version

    # Out-File defaults to UTF-16LE in Windows PowerShell 5.1 and UTF-8 without
    # a BOM in PowerShell 7.
    # Explicit `-Encoding UTF8` writes a BOM in 5.1, but not in 7.
    # Explicit `-Encoding ASCII` gives version files the same bytes in both.
    $version | Out-File $GLOBAL_VERSION_FILE -NoNewline -Encoding ASCII

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
