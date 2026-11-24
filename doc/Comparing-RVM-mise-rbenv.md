<!-- -----------------------------------------------------------
 ! SPDX-License-Identifier: GFDL-1.3-or-later
 ! -------------------------------------------------------------
 ! Doc Type      : Markdown
 ! Doc Name      : Comparing-RVM-mise-rbenv.md
 ! Doc Authors   : Aoran Zeng <ccmywish@qq.com>
 ! Contributors  : Nil Null
 ! Created On    : <2026-11-24>
 ! Last Modified : <2026-11-24>
 ! ---------------------------------------------------------- -->

# Comparing RVM, mise and rbenv for Windows

Command names should describe the information users want, rather than a
program's internal state of knowledge.

## RVM

RVM's [`rvm list known`](https://rvm.io/rubies/list) lists Ruby versions known
to RVM that can be installed, not the versions already installed by the user.
The name "known" describes what RVM knows and does not clearly communicate that
the user is asking for downloadable versions. RVM also notes that it can
install versions not included in that list.

In rbenv for Windows, `rbenv list -r` (or `--remote`) asks for available
versions, while `rbenv list -l` (or `--local`) asks for installed versions.
The remote list comes from the bundled catalog, not a live network request.
There is no `rbenv list known` command: `remote` and `local` communicate the
requested information more clearly.

## mise

mise's [`ls`](https://mise.jdx.dev/cli/ls.html) lists installed and active
tool versions; `-i` / `--installed` restricts the result to installed versions.
Its [`ls-remote`](https://mise.jdx.dev/cli/ls-remote.html) lists versions
available to install. These names describe the information being requested.

rbenv for Windows borrows `ls`, `-i` and `--installed` for familiarity, but
its default list contains installed Ruby versions only. Its `-l` / `--local`
also means installed versions; it does not have the same meaning as mise's
`--local` configuration filter.
