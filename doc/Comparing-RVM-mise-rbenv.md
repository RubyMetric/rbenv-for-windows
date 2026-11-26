<!-- -----------------------------------------------------------
 ! Copyright © 2026 Aoran Zeng
 ! SPDX-License-Identifier: MIT
 ! -------------------------------------------------------------
 ! Doc Type      : Markdown
 ! Doc Name      : Comparing-RVM-mise-rbenv.md
 ! Doc Authors   : Aoran Zeng <ccmywish@qq.com>
 ! Created On    : <2026-11-24>
 ! Last Modified : <2026-11-24>
 ! ---------------------------------------------------------- -->

# Comparing RVM, mise and rbenv for Windows

`rbenv for Windows` aims for **full compatibility with rbenv** while providing
additional commands. These extensions draw inspiration from mise and RVM,
but compatibility with them is not the goal: this project is not called
`RVM for Windows`. Instead, it aims to offer more rational extension commands
that make their purpose clear to users.

Command names should describe the information users want, rather than a
program's internal state of knowledge.

## Listing versions with `list` / `ls`

RVM's [`rvm list known`](https://rvm.io/rubies/list) lists Ruby versions known
to RVM that can be installed, not the versions already installed by the user.
The name "known" describes what RVM knows and does not clearly communicate that
the user is asking for downloadable versions. RVM also notes that it can
install versions not included in that list.

mise's [`ls`](https://mise.jdx.dev/cli/ls.html) lists installed and active
tool versions; `-i` / `--installed` restricts the result to installed versions.
Its [`ls-remote`](https://mise.jdx.dev/cli/ls-remote.html) lists versions
available to install. These names describe the information being requested.

In rbenv for Windows, `rbenv list -r` (or `--remote`) asks for available
versions, while `rbenv list -l` (or `--local`) asks for installed versions.
The remote list comes from the bundled catalog, not a live network request.
There is no `rbenv list known` command: `remote` and `local` communicate the
requested information more clearly. The `ls` alias and `-i` / `--installed`
options are borrowed from mise for familiarity, but the default list contains
installed Ruby versions only. Unlike mise's `--local` configuration filter,
`-l` / `--local` also means installed versions.

## Choosing a version with `use`

RVM's `use` reflects its shell-oriented design: it selects a Ruby for the
current shell, while [`--default`](https://rvm.io/rubies/default) also sets the
default for new shells. The word `use` alone does not tell a user whether the
choice is local to a project, limited to a shell, or global.

The same ambiguity exists in the name of
[`mise use`](https://mise.jdx.dev/cli/use.html). mise normally writes to a
project configuration, but its target depends on the directory and existing
configuration; `--global` selects the global configuration. Users must know
these rules to understand the scope from the command alone.

Rather than leave the choice entirely implicit, rbenv for Windows uses the
current directory as a practical signal to decide between local and global
scope, with explicit options for users who want to override the default.

`rbenv use <version>` delegates to `rbenv global` when the current directory
or any parent contains a `.git` directory, and to `rbenv local` otherwise.
This default avoids creating or changing a project's `.ruby-version` file
inside a Git repository, while still allowing a local selection outside one.
The search continues up to the filesystem root; a `.git` file does not count.

Use `-l` / `--local` or `-g` / `--global` to choose the scope explicitly. A
global change affects other directories too, and an existing local or
shell-specific version can override it. Use `--local` when the project itself
should record the version.

## Inspecting current versions with `current`

RVM's [`rvm current`](https://github.com/rvm/rvm/blob/master/help/current.md)
prints the current Ruby version and any active gemset. mise also has a
[`mise current`](https://github.com/jdx/mise/blob/main/src/cli/current.rs)
command: it is hidden from the command list and prints active tool versions,
optionally for one tool, in a script-friendly format.

`rbenv current` (also available as `rbenv cur`) shows the active Ruby version
and its source first, followed by
the configured global, local and shell versions and the detected system Ruby.
The local value is shown as written in the nearest `.ruby-version` file.
Shell takes precedence over local, which takes precedence over global; the
system Ruby is a separate installation and is active only when selected.

## Inspecting the environment with `info`

RVM provides [`rvm info`](https://rvm.io/rvm/cli) to show information about
the current Ruby. mise's [command list](https://mise.jdx.dev/cli/) does not
include an `info` command; [`mise tool ruby`](https://mise.jdx.dev/cli/tool.html)
shows information about Ruby as a managed tool, while
[`mise doctor`](https://mise.jdx.dev/cli/doctor.html) reports the mise setup
and checks it for problems.

`rbenv info` shows the rbenv, rbenv binary and PowerShell versions, then
runs `ridk version` for the selected Ruby. It is an environment information
command inspired by RVM, not a diagnostic equivalent of `mise doctor`.
