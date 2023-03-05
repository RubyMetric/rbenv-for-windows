<div align="center">

<h1 align="center">rbenv for Windows</h1>

<p>

<a href="https://matrix.to/#/#rbenv-for-windows_community:gitter.im">
    <img src="https://badges.gitter.im/repo.svg" alt="Gitter Chat" />
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

`rbenv for Windows` is a `rbenv` clone for Ruby users on Windows. After continuous improvements, It now can handle `rbenv local` and other Windows-specific issues properly.

**If you're interested in how it works, read these sections for quick and enough information:**

1. [Relation with `rbenv` and with `RubyInstaller2`](./doc/principle.md#relation-with-rbenv-and-with-rubyinstaller2)
2. [Ways to solve Windows-specific issues](./doc/principle.md#ways-to-solve-windows-specific-issues)
3. [How do three versions work?](./doc/principle.md#how-do-three-versions-work)
4. [FAQ for developers](./doc/principle.md#FAQforDevs)
5. [Environment Variables](#EnvVar)

There's a [benchmark](./doc/benchmark.md) to show if `rbenv` will influence Ruby/Gem commands startup time significantly.

<br>

## Screenshot

![screenshot](images/screenshot.png)

<br>

## Install

**Requirements:**

- Windows 7 SP1+ / Windows Server 2008+
- [PowerShell 5](https://aka.ms/wmf5download) (or later, include [PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-6)) and [.NET Framework 4.5](https://www.microsoft.com/net/download) (or later)
- PowerShell must be enabled for your user account e.g. `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

<br>

**It's portable, be bold to try it now:**

### For common users

First, input and run these commands in your terminal:

```PowerShell
# Customize the location you want to install to,
# preferably without spaces, as it has not been tested
$env:RBENV_ROOT = "C:\Ruby-on-Windows"
iwr -useb "https://github.com/ccmywish/rbenv-for-windows/raw/main/tools/install.ps1" | iex
```

Then, in your `$profile`, you should add theses:

```PowerShell
# rbenv for Windows
$env:RBENV_ROOT = "C:\Ruby-on-Windows"

# Not easy to download on Github?
# Use a custom mirror!
# $env:RBENV_USE_MIRROR = "https://abc.com/abc-<version>"

& "$env:RBENV_ROOT\rbenv\bin\rbenv.ps1" init
```

To update, use the following command:

```PowerShell
rbenv update
```

<br>

### For Chinese users

中国大陆用户请使用以下方式，通过Gitee避免网络问题，以及使用内置CN镜像。

首先，在你的终端中输入并运行以下命令:

```PowerShell
# 自定义你想安装到的位置，最好不要有空格，因为没有测试过
$env:RBENV_ROOT = "C:\Ruby-on-Windows"
iwr -useb "https://gitee.com/ccmywish/rbenv-for-windows/raw/main/tools/install-cn.ps1" | iex
```

其次，在你的 `$profile` 中, 添加这些内容:

```PowerShell
# rbenv for Windows
$env:RBENV_ROOT = "C:\Ruby-on-Windows"

# 我为大陆用户预置了镜像, 请查看 share/mirrors.ps1
# 请注意，这个必须放在 'init' 之前
$env:RBENV_USE_MIRROR = "CN"

& "$env:RBENV_ROOT\rbenv\bin\rbenv.ps1" init
```

更新请使用以下命令

```PowerShell
rbenv update cn
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

**Note:**

From `3.1.0-1`, we should download `rubyinstaller-<version>.7z` directly, no devkit. That's only about 15MB. **Every Ruby shares one MSYS64.**

However, before `3.1.0-1`, we have to download `rubyinstaller-devkit-<version>.7z`, with devkit. That's about 130MB ... **Every Ruby has their own MSYS64.**

<br>

## Known issues

**The current implementation has these drawbacks and issues:**

1. Bad integration with `Bundler`: [`bundle install` will not trigger hooks to rehash](https://github.com/ccmywish/rbenv-for-windows/issues/5).

    I don't know if these are bugs of Bundler on Windows, please help this project if you can. As a compromise, I only have to `rbenv rehash version xxx` after you `rbenv global xxx`. This is a simple method to make shims dir always full with kinds of shims.

2. We only support CRuby, x64 versions, provided by RubyInstaller2

    Sorry for that I have no plan to add x86 versions and other Ruby implementations like mruby, JRuby, TruffleRuby and so on. If you want to support it, consider to be a maintainer please! Thank you!

3. We don't support old versions that have a little different leading URL

    Very small URL changes will make our work double, I don't have time for it. So keep URLs convention stable is very important. Luckily, these exceptions are very old Ruby versions (part of 2.4, 2.5 series) built by RubyInstaller, don't worry! See [share/README.md](./share/README.md) for details.

<br>

<a id="EnvVar"> </a>
## Environment Variables

### rbenv user defined

name | example | description
-----|---------|------------
`$env:RBENV_ROOT` | e.g.: `C:\Ruby-on-Windows` | Defines the directory under which MSYS2, Ruby versions, shims and rbenv itself reside.
`$env:RBENV_USE_MIRROR` | e.g.: `"CN"` | Defines the mirror site for download links.

### rbenv auto defined

name | init value | description
-----|---------|------------
`$env:RBENV_INIT` | 1 | To avoid double init. **This variable is set automatically when your terminal start, not set yourself!**
`$env:RUBYLIB` | `$env:RBENV_ROOT\rbenv\share` | For RubyGems plugin to work. **This variable is set automatically when your terminal start, not set yourself!**
`$env:RBENV_SYSTEM_RUBY` | `3.1.2-1<=>C:\Ruby31-x64\` | **This variable is set automatically when your terminal start, not set yourself!** No this if you don't have a Ruby installed by RubyInstaller GUI

### rbenv commands defined

name | example | description
-----|---------|------------
`$env:RBENV_VERSION` | 3.2.0 | Specifies the Ruby version to be used in a shell. <br> **This variable is set by command `rbenv shell`, not manually!**

<br>

## Thanks

1. I reuse a lot of code pieces from [scoop](https://github.com/ScoopInstaller/Scoop)
2. The [RubyInstaller2](https://github.com/oneclick/rubyinstaller2) builds Ruby on Windows day and night
3. The [rbenv](https://github.com/rbenv/rbenv) is our role model

<br>
