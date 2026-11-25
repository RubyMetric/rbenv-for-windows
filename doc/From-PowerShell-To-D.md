<!-- -----------------------------------------------------------
 ! SPDX-License-Identifier: GFDL-1.3-or-later
 ! -------------------------------------------------------------
 ! Doc Type      : Markdown
 ! Doc Name      : From-PowerShell-To-D.md
 ! Doc Authors   : Aoran Zeng <ccmywish@qq.com>
 ! Contributors  : Nil Null
 ! Created On    : <2026-11-24>
 ! Last Modified : <2026-11-24>
 ! ---------------------------------------------------------- -->

# From PowerShell to D

This project was proudly born in an era when code was written by hand. In the beginning, it was written entirely by humans, and entirely in PowerShell. There was no D in the project at all.

That changed when I realized that we needed a `ruby.exe` binary of our own. As described in [Principle](principle.md#fake-rubyexe), the fake Ruby executable lets tools such as Starship detect the Ruby version selected by rbenv. To make that possible, D entered the project.

For a while, some responsibilities were implemented in both D and PowerShell. Even then, all of the code was still written by humans.

As the two implementations accumulated more and more overlapping logic, maintaining both became increasingly difficult. I decided to gradually move that shared logic into D rather than keep two copies in sync.There is no rush to make this transition, though, since the implementation is not difficult.

PowerShell still has an essential role, though. Features such as `rbenv shell` depend on PowerShell's ability to update the environment of the current shell, so PowerShell remains an important part of the project. The goal is not to replace PowerShell entirely, but to put each language to work where it fits best.

For commands backed by `rbenv-exec`, PowerShell should act as a proxy: delegate
the operation to D, let D report errors, and propagate its exit status.
Auxiliary `rbenv-exec` commands used by PowerShell functions are surrounded by
underscores, such as `_get-all-installed-versions_`, to distinguish them from
commands that implement a user-facing operation.

## How the D code is organized

There are two executables, and they share the same facts:

- `ruby.exe` is the fake Ruby ([ruby.d](../source/ruby.d)).
- `rbenv-exec.exe` ([rbenv-exec.d](../source/rbenv-exec.d)) only picks the
  command that PowerShell asked for, and reports its failure.

Everything else is in [source/rbenv/](../source/rbenv), and it is layered:

| Layer | Modules | What it is for |
|-------|---------|----------------|
| Basics | `console`, `errors`, `host`, `paths` | Colored messages, `RbenvError`, the CPU architecture and system Ruby, where things are in `RBENV_ROOT` |
| Versions | `versions`, `installed_versions`, `remote_versions` | What a version name is, how versions are ordered and matched, and the two places they come from |
| Configuration | `version_files`, `active_version`, `current_versions` | Reading `global.txt` and `.ruby-version`, and deciding which version is in effect (shell, then local, then global) |
| Gems | `gem_executables` | Finding the executable of a Gem inside a Ruby version |
| Presentation | `version_messages` | Turning the active version into the text that `ruby.exe`, the shims and `rbenv current` show |
| Commands | `commands\*` | One module per feature of `rbenv-exec`: `global_version`, `local_version`, `rehash`, `whence`, `install_list`, and the ones that other programs read: `shim`, `current`, `powershell_helpers` |

A few rules keep this readable:

- **Facts are separated from text.** The configuration modules return facts: the
  version name, where it came from, and its state. Only `version_messages`
  turns an unavailable version into `xxxNotInstalled`, which starship/oh-my-posh
  users see.
- **Who reads the output matters.** For `shim`, `current` and `powershell_helpers`,
  stdout is a protocol with a batch shim or with PowerShell, not a message for
  the user. Diagnostics always go to stderr.
- **Expected failures are exceptions.** Code that finds a problem the user should
  read about throws `RbenvError`, and `rbenv-exec.d` prints it as `rbenv: ...`
  and exits with its exit code. Code never prints an error and exits by itself.
- **Adding a command** means writing a function in `commands\` and one line in the
  command table of `rbenv-exec.d`. The build script needs no change, because it
  compiles every module that an executable imports.

The JSON of `rbenv current` retains its formatted `source` field for compatibility.
