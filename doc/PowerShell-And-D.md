<!-- -----------------------------------------------------------
 ! Copyright © 2026 Aoran Zeng
 ! SPDX-License-Identifier: MIT
 ! -------------------------------------------------------------
 ! Doc Type      : Markdown
 ! Doc Name      : PowerShell-And-D.md
 ! Doc Authors   : Aoran Zeng <ccmywish@qq.com>
 ! Created On    : <2026-11-24>
 ! Last Modified : <2026-11-25>
 ! ---------------------------------------------------------- -->

# PowerShell and D

This project was proudly born in an era when code was written by hand. In the beginning, it was written entirely by humans, and entirely in PowerShell. There was no D in the project at all.

That changed when I realized that we needed a `ruby.exe` binary of our own. As described in [Principle](principle.md#fake-rubyexe), the fake Ruby executable lets tools such as Starship detect the Ruby version selected by rbenv. To make that possible, D entered the project.

Today, the project intentionally uses both languages. PowerShell remains the command-line interface and implements many user-facing operations. It also handles work that must affect the current shell: for example, `rbenv shell` changes the environment of the running PowerShell session. D is used for compiled executables and for logic that benefits from being shared by those executables.

The goal is not to port everything to D. Each language has a distinct role, and features stay in PowerShell when they depend on PowerShell behavior or are better handled there. Where both sides need the same logic, it can live in D and be called by PowerShell rather than being maintained twice.

When a PowerShell feature uses `rbenv-exec`, PowerShell delegates the operation
to D, reports D's errors, and propagates its exit status. Auxiliary
`rbenv-exec` commands used by PowerShell functions are surrounded by
underscores, such as `_get-all-installed-versions_`, to distinguish them from
commands that implement a user-facing operation.
