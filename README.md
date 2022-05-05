# rbenv for Windows

[![Join the chat at https://gitter.im/rbenv-for-windows/community](https://badges.gitter.im/rbenv-for-windows/community.svg)](https://gitter.im/rbenv-for-windows/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Manage multiple Rubies on Windows.

<br>

## What difficulties we have met?

I need your help guys!

1. [rbenv local: How to check .ruby-version automatically](https://github.com/ccmywish/rbenv-for-windows/issues/2)
2. [Need upstream support for devkit in 7zip archive](https://github.com/ccmywish/rbenv-for-windows/issues/3)


<br>

## NOTE

At early stage, not available for users. But It's portable, be bold to try it first!

<br>

## Install

```PowerShell
mkdir -p "C:\Ruby-on-Windows"
git clone -C "C:\Ruby-on-Windows" "https://github.com/ccmywish/rbenv-for-windows" rbenv
```

In your $profile, you should add theses:

```PowerShell
# rbenv for Windows
$env:RBENV_ROOT = "C:\Ruby-on-Windows"
& "$env:RBENV_ROOT\rbenv\bin\rbenv.ps1" init
```

<br>

## Usage

```PowerShell
# Install Ruby 3.1.2-1
rbenv install 3.1.2

rbenv install 3.0.0-1

# Install devkit
# We need upstream support to implement this!
rbenv install msys

# List all installed versions
rbenv versions

# Set global version
rbenv global 3.0.0-1
# Check global version
rbenv global

rbenv shell 3.1.2-1

# Show current version
rbenv version

rbenv uninstall 3.1.2

# Update rbenv itself!
rbenv update
```


<br>

## Environment Variables

- `RBENV_ROOT`: Ruby-on-Windows

name | default | description
-----|---------|------------
`RBENV_VERSION` | | Specifies the Ruby version to be used.<br>Also see [`rbenv shell`](#rbenv-shell)
`RBENV_ROOT` | `C:\Ruby-on-Windows` | Defines the directory under which MSYS2, Ruby versions, shims and rbenv itself reside.<br>Also see `rbenv root`
`RBENV_DIR` | `$PWD` | Directory to start searching for `.ruby-version` files.


<br>
