<div align="center">

<h1 align="center">rbenv for Windows</h1>

<p>

<a href="https://github.com/RubyMetric/rbenv-for-windows/blob/main/LICENSE.txt">
    <img src="https://img.shields.io/github/license/RubyMetric/rbenv-for-windows.svg" alt="License" />
</a>

</p>

Manage multiple Rubies on Windows.

</div>

<br>

嗨, 你好

Hi, hello

`rbenv for Windows` is a [rbenv] clone for Ruby users on Windows. After continuous improvements, It now can
1. Handle `rbenv local` well
2. Integrate with `RubyGems`, `Bundler` compactly
3. Interact with shell prompt tools like [starship] and [oh-my-posh] properly

There's a simple [record](./doc/benchmark.md) to show if `rbenv` will influence Ruby/Gem commands startup time significantly.

<br>

## Screenshot

![screenshot](image/screenshot.png)

<br>

## Install

### Requirements

- Windows 7 SP1+ / Windows Server 2008+
- [PowerShell 5](https://aka.ms/wmf5download) (or later, include [PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-6)) and [.NET Framework 4.5](https://www.microsoft.com/net/download) (or later)

    PowerShell must be enabled for your user account e.g.
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

- cURL
- Git
- 7zip

<br>

### Install Guides

> [!TIP]
> **It's portable, be bold to try it now**

<details>
<summary>For common users</summary>

First, input and run these commands in your terminal:

```PowerShell
# Customize the location you want to install to,
# preferably without spaces, as it has not been tested
$env:RBENV_ROOT = "C:\Ruby-on-Windows"
iwr -useb "https://github.com/RubyMetric/rbenv-for-windows/raw/main/tool/install.ps1" | iex
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
After adding these configurations to your $profile `notepad.exe $profile`, restart your terminal for the changes to take effect.

To update, use the following command:

```PowerShell
rbenv update
```

Note that, this tool is still under active development, if you've encountered some error, UPDATE FIRST!

</details>

<br>

<details>
<summary>For Chinese users</summary>

中国大陆用户请使用以下方式，通过Gitee避免网络问题，以及使用内置CN镜像。

首先，在你的终端中输入并运行以下命令:

```PowerShell
# 自定义你想安装到的位置，最好不要有空格，因为没有测试过
$env:RBENV_ROOT = "C:\Ruby-on-Windows"
$s = (iwr -useb "https://gitee.com/RubyMetric/rbenv-for-windows/raw/main/tool/install.ps1")
icm -sc ([scriptblock]::Create($s.Content)) -arg "install", "cn"
```

其次，在你的 `$profile` `notepad.exe $profile` 中, 添加这些内容:

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

请注意，此工具仍在积极开发中，如果您遇到了一些错误，请先更新!

</details>

<br>

<details>
<summary>For Russian users</summary>

You can refer to this article by [@SKOLIA0](https://github.com/SKOLIA0)

Вы можете обратиться к этой статье [@SKOLIA0](https://github.com/SKOLIA0)

https://github.com/SKOLIA0/rbenv-for-windows/blob/main/README_RU.md

</details>

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

1. We only support CRuby, x64 versions, provided by RubyInstaller2

    Sorry for that I have no plan to add x86 versions and other Ruby implementations like mruby, JRuby, TruffleRuby and so on. If you want to support it, consider to be a maintainer please! Thank you!

2. We don't support old versions that have a little different leading URL

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
2. The [RubyInstaller2] builds Ruby on Windows day and night
3. The [rbenv] is our role model

<br>

[RubyInstaller2]: https://github.com/oneclick/rubyinstaller2
[rbenv]: https://github.com/rbenv/rbenv
[starship]: https://github.com/starship/starship
[oh-my-posh]: https://github.com/JanDeDobbeleer/oh-my-posh
