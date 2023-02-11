# Principle

<a id="RelationWithOtherProjects"> </a>
## Relation with `rbenv` and `RubyInstaller2`

[rbenv](https://github.com/rbenv/rbenv) works on Unix-like systems in a native way (using Bash), it uses the plugin [ruby-build](https://github.com/rbenv/ruby-build) to download CRuby source code and compile, then install. `rbenv` does a great job! I really want it to run on my Windows.

Our `rbenv-for-windows` works on Windows, also in a native way (using PowerShell), we use the great and battle-tested [RubyInstaller2](https://github.com/oneclick/rubyinstaller2) directly to install the binary, it hence saves your time.

`rbenv-for-windows` is trying to make commands compatible with `rbenv`, which can make you feel consistent in different systems.

<br>

<a id="HowDoesItWork"> </a>
## How does it work?

We are a little different with how `rbenv` works. Surely, we have shims too, but our shims folder is always pointing to the global version.

 Every time you use `rbenv global x.x.x`, the shims folder location will not change, but the content of it will change wholly (unlike `rbenv` on Linux, there it will stores shell scripts to delegate).

You are maybe questioning the performance now, we use `junction` in Windows, so there is so little overhead you'll notice, in fact, this leads to about just 10ms delay.

There are three kind of 'versions'
1. global version (set by `$env:RBENV_ROOT\global.txt`)
2. local version  (set by `$PWD\.ruby-version`)
3. shell version (set by `$env:RBENV_VERSION`)

<br>

### global version

After you setup `rbenv` your `path` will be:
```PowerShell
# for 'rbenv' command itself
$env:RBENV_ROOT\rbenv\bin

# for
# 1. ruby.exe rubyw.exe
# 2. gem.cmd, ...
# 3. bundler.bat irb.bat rdoc.bat rake.bat
#    and other gems bat
$env:RBENV_ROOT\shims\bin

# The default path of yours
$env:PATH
```

So every time you change global version, you will directly get what `$env:RBENV_ROOT\shims\bin` offers you!

<br>

### shell version

If we execute the command `rbenv shell 3.1.2`, we will get a new environment variable `$env:RBENV_VERSION = 3.1.2`, and now your path will be:

```PowerShell
$env:RBENV_ROOT\3.1.2\bin

$env:RBENV_ROOT\rbenv\bin

$env:RBENV_ROOT\shims\bin

$env:PATH
```
So in this shell, your env will not be affected with `global version` or `local version`. **A very simple hack in path!**

<br>

### local version

Like `rbenv` we also don't hook on changing location. We use shims too. Our shims are directly in every ruby `bin` directory. Every ruby-related command has a `PowerShell` script individually, this script is called `shim`. The script will delegate to the correct version's `bin` directory.

<br>

### Fake ruby.exe

There's a `ruby.exe` residing in `rbenv\bin`, whenever you call `ruby` or any `gem` commands, what you invoke in fact is always this `fake ruby.exe`.

This is the most difficult part when implementing `rbenv`. Because of the existence of `rbenv local`, I finally introduce the concept of `shim`, but very different with the original `rbenv`. Shell prompt like `starship` can't get the correct version, as it only invokes the `ruby.exe` to get version not through our shim file. There's no way to make `starship` get correct and without huge delay.

So the only method is to pretend to be the real `ruby.exe`. `starship` checks our `fake ruby.exe`'s version, hence get it correct. The fake one will check `shell version`, then `local version`, then `global version`. Otherwise, it will invoke `ruby.exe` in no consideration of this PowerShell's environment variables.

How does `gem` command get correct version? Every `gem` command through shim invokes the `fake ruby.exe` too, so we also get correct version. Then we make the first argument of ruby interpreter the so-called `bin stub file`(glossary from `RubyGems`).

<br>

<a id="FAQforDevs"> </a>
## FAQ for maintainers

> Q: Why multiple Rubies can share one MSYS2?

It's decided by RubyInstaller's tool: `ridk`, it's automatically loaded every time you use Ruby.

`ridk` has determined how you choose MSYS2, in this order:

1. MSYS2 inside Ruby dir
2. MSYS2 beside Ruby dir **(That's how `rbenv` works!)**
3. C:\msys64
4. Other ways including `scoop`
5. ...

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
