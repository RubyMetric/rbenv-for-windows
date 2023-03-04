def build_fake_ruby
  sh "dmd -of=./bin/ruby.exe ./bin/source/ruby.d ./bin/source/rbenv.d"
end

def build_rbenv_rehash
  sh "dmd -of=./bin/rbenv-rehash.exe ./bin/source/rbenv-rehash.d ./bin/source/rbenv.d"
end


desc "rbenv: Build fake ruby.exe from D files"
task :build do
  build_fake_ruby
  build_rbenv_rehash
end
