<div align="center">
<h1 align="center">rbenv for Windows</h1>

[![Join the chat at https://gitter.im/rbenv-for-windows/community](https://badges.gitter.im/rbenv-for-windows/community.svg)](https://gitter.im/rbenv-for-windows/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

    Manage multiple Rubies on Windows.
</div>


嗨, 你好

Hi, hello

**If you are curious how I make it work, you can read the two sections**

1. [How does it work?](#HowDoesItWork)
2. [FAQ for developers and maintainers](#FAQforDevs)

<br>

## Known issues

1. [Need upstream support for devkit in 7zip archive](https://github.com/ccmywish/rbenv-for-windows/issues/3)

    This can make download/install process much easier, and can be solved mostly if upstream can directly support it.

2. [We can't have a good prompt using `starship`](https://github.com/ccmywish/rbenv-for-windows/issues/4)

    This is caused by shims used by `rbenv local`, I can't find a good way to solve this. In order for `prompt` like `starshiip` to work, I make the `rbenv global` using another mechanism.

3. We only support CRuby, x64 versions, no plan to

    Sorry for that I have no plan to add x86 versions and other Ruby implementations like mruby, JRuby, TruffleRuby and so on, because of my extremely lack of time in next recent years for developing, if you want to support it, consider to be a maintainer please! Thank you!

<br>

In brief, the current implementation has two drawbacks:

1. When changing into a dir that has '.ruby-version', you will use the correct version, but your `prompt` will still display the wrong version.
2. To solve drawback 1, `rbenv global` can work great with `prompt`, but introduces another drawback: You can't change global version while running a Ruby-related process on that version.

<br>

## Requirements

- Windows 7 SP1+ / Windows Server 2008+
- [PowerShell 5](https://aka.ms/wmf5download) (or later, include [PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-6)) and [.NET Framework 4.5](https://www.microsoft.com/net/download) (or later)
- PowerShell must be enabled for your user account e.g. `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

<br>

## Install

It's portable, be bold to try it!

```PowerShell
mkdir -p "C:\Ruby-on-Windows"
git clone -C "C:\Ruby-on-Windows" "https://github.com/ccmywish/rbenv-for-windows" rbenv
```

In your `$profile`, you should add theses:

```PowerShell
# rbenv for Windows
$env:RBENV_ROOT = "C:\Ruby-on-Windows"
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
# We need upstream support to implement this!
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

# see share/mirros.ps1
# I have pre-defined a mirror for you guys
$env:RBENV_USE_MIRROR = "CN"  # For Chinese users
```

**Note:**

From `3.1.0-1`, we should download rubyinstaller-<version>.7z directly, no devkit! That's only about less than 15MB. **Every Ruby share one MSYS64!**

However, before `3.1.0-1`, we have to download rubyinstaller-devkit-<version>.7z, with devkit! That's about 100MB ... **Every Ruby has their own MSYS64!**

<br>

<a id="HowDoesItWork"> </a>
## How does it work?

We are a little different with how `rbenv` works. Surely, we have shims too, but our shims folder is always pointing to the global version.

 Every time you use `rbenv global x.x.x`, the shims folder location will not change, but the content of it will change wholly (unlike `rbenv` on Linux, there it will stores shell script to delegate).

You are maybe questioning the performance now, we use `junction` in Windows, so there is so little overhead you'll notice, in fact, this leads to about just 10ms delay.

There are three kind 'versions'
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

So every time you change global version, you will directly get what `$env:RBENV_ROOT\shims\bin` offers you! **No hack in path at all!**

<br>

### shell version

If we execute the command `rbenv shell 3.1.2`, we will get a new environment variable `$env:RBEVN_VERSION = 3.1.2`, and now your path will be:

```PowerShell
$env:RBENV_ROOT\3.1.2\bin

$env:RBENV_ROOT\rbenv\bin

$env:RBENV_ROOT\shims\bin

$env:PATH
```
So in this shell, your env will not be affected with `global version` or `local version`. **A very simple hack in path!**

<br>

### local version

Like `rbenv` we also don't hook on changing location. We use shims too. Our shims is directly in every ruby `bin` directory. Every ruby-related command has a `PowerShell` script individually, this script is called `shim`. The script will delegate to the correct version's `bin` directory. **No hack in path at all!**

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
## FAQ for developers and maintainers

> Q: Why multiple Rubis can share one MSYS2?

A: It's decided by RubyInstaller's tool: `ridk`, it's automatically loaded every time you use Ruby.

`ridk` has determined how you choose MSYS2, in this order:

1. MSYS2 inside Ruby dir
2. MSYS2 beside Ruby dir **(That's how `rbenv` works!)**
3. C:\msys64
4. Other ways including `scoop`
5. ...

We place a MSYS2 beside all Rubies, so every Ruby can share it. Hence I call this MSYS2 **The shared MSYS2**.

<br>

> Q: If `rbenv global system`, shims have changed, am I still using the shared MSYS2 ?

A: No, it won't use the shared MSYS2, instead it will search the order for its own MSYS2.

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

1. Search in 3.1.2, collect all that need to be rehashed
2. rehash them one by one

<br>

## Thanks

1. I reuse a lot of code pieces from [scoop](https://github.com/ScoopInstaller/Scoop)
2. The [RubyInstaller2](https://github.com/oneclick/rubyinstaller2) builds Ruby on Windows day and night
3. The [rbenv](https://github.com/rbenv/rbenv) is our role model

<br>
