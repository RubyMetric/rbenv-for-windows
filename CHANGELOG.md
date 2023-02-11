# Changelog

## [Unreleased](#) (2023-02-12)

<br>

## [v1.3.0](#) (2023-02-12)

### New features:

- Use fake `ruby.exe` to support shell prompt (e.g. `starship`) for `rbenv local` version
- Bypass `.bat` or `.cmd` Windows executable delegator

<br>

## [v1.2.0](#) (2023-02-08)

### New features:

- Add `$env:RBENV_INIT` to avoid double init

### Enhancements:

- Rename inner version to avoid conflict with global env variable and annotate better on init process

<br>

## [v1.1.0](#) (2023-01-11)

### New features:

- Change to global version as a compromise when there's a '.ruby-version' file
- Set '/currentuser' when version >= 3.2.0-1 with MSYS2

### Enhancements:

- 'rbenv local' command removes the RubyInstaller2 suffix when set

### Bug fixes:

- Fix bug on rehash two executables ruby and rubyw: remove .exe suffix

<br>

## [v1.0.0](#) (2022-05-09)

- Finish

<br>

## [Initialize](#) (2022-05-02)

I write this because I want to use multiple Rubies on Windows, but Ridk is not very convenient. Maybe we need a rbenv for Windows.

<br>

<hr>

This Changelog is maintained with [chlog](https://github.com/ccmywish/chlog)

