# Principle

## Relation with `rbenv` and with `RubyInstaller2`

[rbenv](https://github.com/rbenv/rbenv) works on Unix-like systems in a native way (using Bash), it uses the plugin [ruby-build](https://github.com/rbenv/ruby-build) to download CRuby source code and compile, then install. `rbenv` does a great job, I want it to run on Windows.

`rbenv for Windows` works on Windows, also in a native way (using PowerShell and D pre-compiled binaries), we use the battle-tested [RubyInstaller2](https://github.com/oneclick/rubyinstaller2) directly to install CRuby, no need to compile as in `rbenv`, hence saves time.

`rbenv for Windows` is trying to make commands compatible with `rbenv`, which can make you feel consistent in different systems.

<br>

## Ways to solve Windows-specific issues

The working principle of `rbenv for Windows` is very similar to `rbenv`. However, on Windows, we are quite in trouble with `exeutables`. For example, files without an extension will not be executed in a proper way.

<br>

### fake ruby.exe

Shell prompt tools like `starship` always look for `ruby.exe` in `PATH`, however, this can't respect versions set by `rbenv for Windows`. Hence, I propose the idea of `fake ruby.exe`.

There's a `ruby.exe` residing in `rbenv\bin`, `starship` will be fooled by this `fake ruby.exe` to display correct version set by users.

Try use `ruby.exe` in your terminal, you will find that, all it will do is to handle `ruby.exe -v`(for `starship` to work) and `ruby.exe --version`(for `oh-my-posh` to work). All other commands will be rejected to notify that you shouldn't directly invoke it.

```PowerShell
❯ ruby.exe -v
ruby 3.2.0-1 (set by C:\Ruby-on-Windows\global.txt)

❯ ruby.exe --version
ruby 3.2.0-1 (set by C:\Ruby-on-Windows\global.txt)

❯ ruby.exe -h
rbenv: This is fake ruby.exe in $env:RBENV_ROOT\rbenv\bin
rbenv: You shouldn't invoke 'ruby.exe', instead you should invoke 'ruby'
```

<br>

### ruby/rubyw imitator

Whenever you call `ruby`(`rubybw`) (without suffix), what you invoke in fact is `ruby.ps1`(`rubyw.ps1`).

The two imitators are to help run `ruby` and `rubyw` with correct versions. Note that, it internally invoke `fake ruby.exe` to get current version info.

<br>

### rbenv-exec.exe

This native executable is called by
1. `rbenv rehash`,
2. `rbenv whence`
3. `batch` shim to find the correct version of gem executables.

When you type a gem command in your terminal, it runs the corresponding shim in shims dir. The shim invokes the `rbenv-exec.exe`, so we can get correct version.

```PowerShell
# call chain
1. shim xxx.bat
    2. rbenv-exec.exe
        3. find the correct version of the gem, e.g. C:\Ruby-on-Windows\3.2.0-1\bin\cr.bat
            4. C:\Ruby-on-Windows\3.2.0-1\bin\ruby.exe C:\Ruby-on-Windows\3.2.0-1\bin\cr
```

In the last step of the chain, the argument of ruby interpreter is the so-called `bin stub file` (glossary from `RubyGems`).

<br>

## How do three versions work?

There are three kind of 'versions'
1. global version (set by `$env:RBENV_ROOT\global.txt`)
2. local version  (set by `$PWD\.ruby-version`)
3. shell version (set by `$env:RBENV_VERSION`)

<br>

### global version

After you setup `rbenv` your `path` will be:
```PowerShell
# For
#   1. 'rbenv' command itself
#   2. fake ruby.exe
#   3. ruby/rubyw imitator
$env:RBENV_ROOT\rbenv\bin

# For
#   1. gem.cmd, ...
#   2. bundler.bat irb.bat rdoc.bat rake.bat and other gems bat
$env:RBENV_ROOT\shims

# The default path of yours
$env:PATH
```

<br>

### shell version

If we execute the command `rbenv shell 3.1.2`, we will get a new environment variable `$env:RBENV_VERSION = 3.1.2`, and now your path will be:

```PowerShell
$env:RBENV_ROOT\3.1.2-1\bin

$env:RBENV_ROOT\rbenv\bin

$env:RBENV_ROOT\shims

$env:PATH
```

So in this shell, your env will not be affected with `global version` or `local version`. It's a very simple hack in path.

<br>

### local version

Like `rbenv` we also don't hook on changing location. We use shims too. Our shims are in the shims dir `$env:RBENV_ROOT\shims` directory. Every Gem executable has a `batch` script (`.bat`) individually, this script is called `shim`. The script will delegate to the correct version's `bin` directory.

Note that, previous `v1.4.2`, we use `PowerShell` as shim script. However, it makes `bundle exec` can't find the gem executables. So, we change to use `batch` file.

<br>

<a id="FAQforDevs"> </a>
## FAQ for developers

> Q: Why multiple Rubies can share one MSYS2?

It's decided by RubyInstaller's tool: `ridk`, it's automatically loaded every time you use Ruby.

`ridk` has determined how you choose MSYS2, in this order:

1. MSYS2 inside Ruby dir
2. MSYS2 beside Ruby dir **(That's how `rbenv` works!)**
3. `C:\msys64`
4. where RubyInstaller.exe is installed (search the Registry)
5. Other ways including `scoop`
6. ...

See: https://github.com/oneclick/rubyinstaller2/blob/master/lib/ruby_installer/build/msys2_installation.rb

We place a MSYS2 beside all Rubies, so every Ruby can share it. Hence I call this MSYS2 **the shared MSYS2**.

<br>

> Q: If `rbenv global system`, shims have changed, am I still using the shared MSYS2 ?

No, it won't use the shared MSYS2, instead it will search the order for its own MSYS2.

E.g. if your system ruby is installed in `C:\Rubyx31-64`, it will search MSYS2 via

1. MSYS2 inside Ruby dir => `C:\Rubyx31-64\msys64`
2. MSYS2 beside Ruby dir => `C:\msys64`
3. `C:\msys64`
4. Others like the above order

<br>

> Q: When to rehash?

First, you should know what rehash will do:

If a gem/ruby.exe got rehashed, then **all installed Rubies** will get a shim.

This is one time one gem way. How to rehash all for a newly installed version? Every time you install a new Ruby, it will call `rbenv rehash version x.x.x`, so it will

1. Search in `x.x.x`, collect all that need to be rehashed
2. rehash them one by one

So, when to rehash (automatically, not user's behaviors)?

1. After `gem install xxx`
2. After `bundle install` (This hook doesn't work, please help if you can)
3. After installing a new Ruby version
4. After `rbenv global xxx` (This is a compromise as mentioned before)
5. After detecting a system Ruby

<br>
