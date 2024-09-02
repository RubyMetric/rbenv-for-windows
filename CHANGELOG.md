# Changelog

## [Unreleased](#) (2024-09-02)

<br>

## [v1.5.1](#) (2024-09-02)

### New features:

- Conditionally update according to the binary version

### Bug fixes:

- `rbenv shell system`

### Deprecations:

- Move project URL and change tool directory name

<br>

## [v1.5.0](#) (2024-01-02)

### New features:

- Add `ridk.bat` for cmd users
- Add `rubyw.bat` for cmd users

### Deprecations:

- Not use `ruby.ps1` anymore

<br>

## [v1.4.9](#) (2023-09-26)

### New features:

- Add caller `ridk.ps1`

### Enhancements:

- Not use `git` to detect `.ruby-version`
- Support `ruby-` in `.ruby-version`

### Bug fixes:

- Fix ridk caller args for `ridk enable`

<br>

## [v1.4.8](#) (2023-05-20)

### Bug fixes:

- Fix bug: PowerShell `v5.x` series can't recognize `308` status code

    See GitHub Issue [#18](https://github.com/RubyMetric/rbenv-for-windows/issues/18), [#8](https://github.com/RubyMetric/rbenv-for-windows/issues/8), [#7](https://github.com/RubyMetric/rbenv-for-windows/issues/7)

<br>

## [v1.4.7](#) (2023-05-19)

### Enhancements:

- Use `informative version` when specific version not available

    1. version `x.x.xNotInstalled`
    2. version `NoGlobalVersionIsSet`

### Bug fixes:

- When `.ruby-version` has multiple lines

    **It should only read the first line.**

    But it read the whole file's content as version. I've fixed it to meet our expectations.

<br>

## [v1.4.6](#) (2023-05-05)

### Bug fixes:

- Use RubyGem's hook also in bundler process, this fixes the [one-year long bug: GitHub Issue #5](https://github.com/RubyMetric/rbenv-for-windows/issues/5):

<br>

## [v1.4.5](#) (2023-05-02)

### New features:

- Add gem name in output of gem install hook

### Enhancements:

- Support `oh-my-pwsh` by adding `--version` for `fake ruby.exe`

### Bug fixes:

- Design special mechanism for batch shim to swallow error when gem not found
- Fix incomplete output when gem command not exists in this Ruby version

### Deprecations:

- Use word `executable` in place of `gem` for rehash

<br>

## [v1.4.4](#) (2023-04-03)

### Enhancements:

- Always update from a specific tag
- Share more codes

### Bug fixes:

- Use ascii encoding for global version file

<br>

## [v1.4.3](#) (2023-03-05)

### Enhancements:

- `rbenv update` reuse installer
- Fix bug of `rbenv update cn` : no any behavior

<br>

## [v1.4.2](#) (2023-03-05)

### New features:

- Change shim from `PowerShell` script to `batch` file, this is to support `bundle exec`

### Enhancements:

- Add more precise documents
- Organize D files
- Enhance `rbenv update`
- Use versatile `rbenv-exec.exe`

<br>

## [v1.4.1](#) (2023-03-04)

### New features:

- Add installer script
- Add build script
- Refactor `rbenv rehash` in Dlang. This adds binary `.\libexec\rbenv-rehash.exe` making rehash time cost **from 120ms to 30ms**. This also removes the dependency on `pwsh.exe` in `rubygems_plugin.rb`.

### Enhancements:

- Remove redundant blank line in hook
- Add benchmark documents
- Add auto fix version feature into `fake ruby.exe`

### Bug fixes:

- Fix bug of `.editorconfig` to make it work for `Rakefile`

<br>

## [v1.4.0](#) (2023-03-03)

### New features:

- Use `ruby.ps1` and `rubyw.ps1` to delegate to `real ruby.exe`

### Enhancements:

- All shim is in shims dir
- Get current version from `fake ruby.exe`

### Bug fixes:

- Revert change: not bypass `.bat` or `.cmd` delegator in [v1.3.0]()

    See reasons: [GitHub Issue #12](https://github.com/RubyMetric/rbenv-for-windows/issues/12)

### Deprecations:

- Not use junction for shims dir
- Not use `fake ruby.exe (ruby.d)` to delegate anymore

<br>

## [v1.3.1](#) (2023-02-20)

### Enhancements:

- Keep up with upstream install options `nomodpath`, `noassocfiles`
- Deny the check for `C:\msys64` to be `the shared MSYS2`. See comments in `bin\rbenv.ps1`

<br>

## [v1.3.0](#) (2023-02-12)

### New features:

- Use `fake ruby.exe` to support shell prompt (e.g. `starship`) for `rbenv local` version
- ~~Bypass `.bat` or `.cmd` Windows executable delegator~~

    This is reverted in [v1.4.0]()

<br>

## [v1.2.0](#) (2023-02-08)

### New features:

- Add `$env:RBENV_INIT` to avoid double init

### Enhancements:

- Rename inner version to avoid conflict with global env variable and annotate better on init process

<br>

## [v1.1.0](#) (2023-01-11)

### New features:

- Change to global version as a compromise when there's a `.ruby-version` file
- Set `/currentuser` when version `>= 3.2.0-1` with MSYS2

### Enhancements:

- `rbenv local` command removes the RubyInstaller2 suffix when set

### Bug fixes:

- Fix bug on rehash two executables ruby and rubyw: remove .exe suffix

<br>

## [v1.0.0](#) (2022-05-09)

- Basically work

<br>

## [Initialize](#) (2022-05-02)

I write this because I want to use multiple Rubies on Windows, but Ridk is not very convenient. Maybe we need a rbenv for Windows.

<br>

<hr>

This Changelog is maintained with [chlog](https://github.com/ccmywish/chlog)

