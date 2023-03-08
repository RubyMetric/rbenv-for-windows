# 'rbenv on windows' patch to
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

hook = lambda do |installer|
  begin
    # Ignore gems that aren't installed in locations that rbenv searches for binstubs
    if installer.spec.executables.any? &&
      [Gem.default_bindir, Gem.bindir(Gem.user_dir)].include?(installer.bin_dir)

      installer.spec.executables.each do |e|
        success `#{RBENV_EXEC} rehash-gem #{e}`, use_print: true
      end

    end
  rescue
    warn "rbenv: error in Gem post-install hook (#{$!.class.name}: #{$!.message})"
  end
end


if defined?(Bundler::Installer) && Bundler::Installer.respond_to?(:install) && !Bundler::Installer.respond_to?(:install_without_rbenv_rehash)
  # For bundle install
  Bundler::Installer.class_eval do
    class << self
      alias install_without_rbenv_rehash install
      def install(root, definition, options = {})

        # https://github.com/rubygems/bundler/issues/5429?msclkid=d38c6a09cedb11ec94053204e56d147e
        # As the issues says:
        #   bundle install with path not works for post-install hook, it just adds $LOAD_PATH
        #   However, in my test, the hook won't be triggered even for the basic " gem 'xxx' "
        #
        # So, we have a bad integration with Bundler.
        # To compromise, I have to run `rbenv rehash version xxx` when `rbenv global xxx``
        #
        puts
        success "rbenv: Hi! If you see this line, please let me know how you do it."
        success "It means you successfully trigger the Bundler post-install hook on Windows"
        success "It is what we want but Bundler doesn't do correctly at present (2022-05-08)"
        puts

        begin
          if Gem.default_path.include?(Bundler.bundle_path.to_s)
            bin_dir = Gem.bindir(Bundler.bundle_path.to_s)
            bins_before = File.exist?(bin_dir) ? Dir.entries(bin_dir).size : 2
          end
        rescue
          warn "rbenv: error in Bundler post-install hook (#{$!.class.name}: #{$!.message})"
        end

        result = install_without_rbenv_rehash(root, definition, options)

        if bin_dir && File.exist?(bin_dir) && Dir.entries(bin_dir).size > bins_before
          # rehash for current version
          # Our code is correct, because our `rbenv rehash` will rehash the current version
          # So next time, you change global to this version, you really already get what you want in a Gemfile
          cur_ver = `#{FAKE_RUBY_EXE} -v`.split()[1]
          success `#{RBENV_EXEC} rehash-version #{cur_ver}`, use_print: true
        end
        result
      end
    end
  end
else
  # For gem install
  begin
    Gem.post_install(&hook)
    # I think we don't need to do this
    # Gem.post_uninstall(&hook)
  rescue
    warn "rbenv: error installing gem-rehash hooks (#{$!.class.name}: #{$!.message})"
  end
end
