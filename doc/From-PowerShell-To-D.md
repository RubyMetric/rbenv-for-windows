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
