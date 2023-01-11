<div align="center">

<h1 align="center">rbenv for Windows</h1>

<p>

<a href="https://gitter.im/rbenv-for-windows/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge">
    <img src="https://badges.gitter.im/rbenv-for-windows/community.svg" alt="Gitter Chat" />
</a>

<a href="https://github.com/ccmywish/rbenv-for-windows/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/ccmywish/rbenv-for-windows.svg" alt="License" />
</a>

</p>

Manage multiple Rubies on Windows.

</div>

<br>

嗨, 你好

Hi, hello

**If you're interested in how it works, read these sections for quick and enough information:**

1. [Relation with rbenv and RubyInstaller2](#RelationWithOtherProjects)
2. [How does it work?](#HowDoesItWork)
2. [FAQ for maintainers](#FAQforDevs)

<br>

## Screenshot

![screenshot](images/screenshot.png)

<br>

## Install

**Requirements:**

- Windows 7 SP1+ / Windows Server 2008+
- [PowerShell 5](https://aka.ms/wmf5download) (or later, include [PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-6)) and [.NET Framework 4.5](https://www.microsoft.com/net/download) (or later)
- PowerShell must be enabled for your user account e.g. `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

<hr>

**It's portable, be bold to try it now:**

```PowerShell
mkdir "C:\Ruby-on-Windows"
git -C "C:\Ruby-on-Windows" clone "https://github.com/ccmywish/rbenv-for-windows" rbenv
```

In your `$profile`, you should add theses:

```PowerShell
# rbenv for Windows
$env:RBENV_ROOT = "C:\Ruby-on-Windows"

# I have pre-defined a mirror for you guys, see share/mirrors.ps1
# Note, this must be placed before 'init'
$env:RBENV_USE_MIRROR = "CN"  # For Chinese users

& "$env:RBENV_ROOT\rbenv\bin\rbenv.ps1" init
```

<br>

## Usage

**Note:** You can omit many numbers when you specify a version!

Try use
- `rbenv global 3`
- `rbenv local 2.`
- `rbenv install 3.1`

```PowerShell
# List recent Ruby versions
rbenv install -l

# List all Ruby versions
rbenv install -a

# Hooray! So easy to try Ruby dev branch!
rbenv install head

# Install Ruby 3.1.2-1
rbenv install 3.1.2

rbenv install 3.0.0-1

# Install devkit

# No need to run it by yourself now,
# It will run automatically when first setup rbenv
rbenv install msys
# or
rbenv install msys2
# or
rbenv install devkit

# List all installed versions
rbenv versions

# Set global version
rbenv global 3.0.0-1
# Check global version
rbenv global

# Set local version
rbenv local 3.1.2-1

# Check versions
rbenv versions

# Set Ruby version in this shell
rbenv shell 3.0.0-1

# Show current version
rbenv version

# Unset Ruby version in this shell
rbenv shell --unset

rbenv uninstall 3.1.2

# Update rbenv itself!
rbenv update
```

Not easy to download on Github? Use a mirror!

```PowerShell
# Use a custom mirror
$env:RBENV_USE_MIRROR = "https://abc.com/abc-<version>"

# see share/mirrors.ps1
# I have pre-defined a mirror for you guys
# Note, this must be placed before 'init'
$env:RBENV_USE_MIRROR = "CN"  # For Chinese users
```

**Note:**

From `3.1.0-1`, we should download `rubyinstaller-<version>.7z` directly, no devkit. That's only about 15MB. **Every Ruby shares one MSYS64.**

However, before `3.1.0-1`, we have to download `rubyinstaller-devkit-<version>.7z`, with devkit. That's about 130MB ... **Every Ruby has their own MSYS64.**

<br>

<a id="RelationWithOtherProjects"> </a>
## Relation with `rbenv` and `RubyInstaller2`

[rbenv](https://github.com/rbenv/rbenv) works on Unix-like systems in a native way (using Bash), it uses the plugin [ruby-build](https://github.com/rbenv/ruby-build) to download CRuby source code and compile, then install. `rbenv` does a great job! I really want it to run on my Windows.

Our `rbenv-for-windows` works on Windows, also in a native way (using PowerShell), we use the great and battle-tested [RubyInstaller2](https://github.com/oneclick/rubyinstaller2) directly to install the binary, it hence saves your time.

`rbenv-for-windows` is trying to make commands compatible with `rbenv`, which can make you feel consistent in different systems. During early stage of development I'm making it work without reading the source code of `rbenv`, but later when I have to implement `rbenv local` feature, I ask the `rbenv`'s author for help, finally also introduced the concept of shims, but a little differently.

<br>

## Known issues

**The current implementation has these drawbacks and issues:**

1. When changing into a dir that has `.ruby-version`, you will use the correct version, but your `prompt` will still display the wrong version.

    [We can't have a good prompt using `starship`](https://github.com/ccmywish/rbenv-for-windows/issues/4).

    This is caused by shims used by `rbenv local`, I can't find a good way to solve it.

    However I make `rbenv global` work great with `prompt` by using `junction`. It **won't lead to the situation**: You can't change global version while running a Ruby-related process on that version.

2. Bad integration with `Bundler`, [Bundle install will not trigger hooks to rehash](https://github.com/ccmywish/rbenv-for-windows/issues/5).

    I don't know if these are bugs of Bundler on Windows, please help this project if you can. As a compromise, I only have to `rbenv rehash version xxx` after you `rbenv global xxx`.

    **I suggest you mainly use `rbenv global` and `rbenv shell` to work, even `bundle exec` will work wrongly if you use `rbenv local`.**

    The main reason I make this project, is just I want to use multiple rubies through CLI, not GUI. So I focus just more on the installation process.

3. We only support CRuby, x64 versions, provided by RubyInstaller2

    Sorry for that I have no plan to add x86 versions and other Ruby implementations like mruby, JRuby, TruffleRuby and so on, because of my extremely lack of time in next recent years for developing. If you want to support it, consider to be a maintainer please! Thank you!

4. We don't support old versions that have a little different leading URL

    Very small URL changes will make our work double, I don't have time for it. So keep URLs convention stable is very important. Luckily, these exceptions are very old Ruby versions (part of 2.4, 2.5 series) built by RubyInstaller, don't worry! See [share/README.md](./share/README.md) for details.

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

## Environment Variables

name | default | description
-----|---------|------------
`$env:RBENV_VERSION` | N/A | Specifies the Ruby version to be used in a shell. <br> **This variable is set by command `rbenv shell`, not yourself!**
`$env:RBENV_ROOT` | `C:\Ruby-on-Windows` | Defines the directory under which MSYS2, Ruby versions, shims and rbenv itself reside.
`$env:RBENV_SYSTEM_RUBY` | No this if you don't have a Ruby installed by RubyInstaller GUI | **This variable is set automatically when your terminal start, not set yourself!**
`$env:RUBYLIB` | `$env:RBENV_ROOT\rbenv\share` | **This variable is set automatically when your terminal start, not set yourself!**

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

## Thanks

1. I reuse a lot of code pieces from [scoop](https://github.com/ScoopInstaller/Scoop)
2. The [RubyInstaller2](https://github.com/oneclick/rubyinstaller2) builds Ruby on Windows day and night
3. The [rbenv](https://github.com/rbenv/rbenv) is our role model

<br>
