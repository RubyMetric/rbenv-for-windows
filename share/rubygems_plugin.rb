# 'rbenv for Windows' patch to
#   https://github.com/rbenv/rbenv/blob/master/rbenv.d/exec/gem-rehash/rubygems_plugin.rb
#

RBENV_EXEC    = ENV['RBENV_ROOT'] + '\rbenv\libexec\rbenv-exec.exe'
FAKE_RUBY_EXE = ENV['RBENV_ROOT'] + '\rbenv\bin\ruby.exe'

def success(msg, use_print: false)
  str = "\e[32m" + msg + "\e[0m"
  if use_print then print str
  else puts str
  end
end

# The installer is Gem::Installer instance
hook = lambda do |installer|
  begin
    # Ignore gems that aren't installed in locations that rbenv searches for binstubs
    if installer.spec.executables.any? &&
      [Gem.default_bindir, Gem.bindir(Gem.user_dir)].include?(installer.bin_dir)

      gem_name = installer.spec.name

      installer.spec.executables.each do |e|
        success `#{RBENV_EXEC} rehash-gem #{e} for #{gem_name}`, use_print: true
      end

    end
  rescue
    warn "rbenv: Error in Gem post-install hook (#{$!.class.name}: #{$!.message})"
  end
end

# NOTE:
#   I've deleted Bundler blocks in original rbenv's rubygems_plugin.rb as it has no effect,
#   because it monkey patches to the wrong place (at least wrong on Windows)

# For 'gem install' && 'bundle'
begin
  Gem.post_install(&hook)
  # I think we don't need to do this
  # Gem.post_uninstall(&hook)
rescue
  warn "rbenv: Error when installing Gem post-install hook (#{$!.class.name}: #{$!.message})"
end
