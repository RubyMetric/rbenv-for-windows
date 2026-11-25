<!-- -----------------------------------------------------------
 ! SPDX-License-Identifier: GFDL-1.3-or-later
 ! -------------------------------------------------------------
 ! Doc Type      : Markdown
 ! Doc Name      : PowerShell-problems.md
 ! Doc Authors   : Aoran Zeng <ccmywish@qq.com>
 ! Contributors  : Nil Null
 ! Created On    : <2026-11-25>
 ! Last Modified : <2026-11-25>
 ! ---------------------------------------------------------- -->

# PowerShell problems: text file encoding

## rbenv and the two PowerShell versions

rbenv for Windows uses PowerShell for its command-line interface, alongside
D executables for shared version detection and other operations. The project
supports both Windows PowerShell 5.1 (`powershell.exe`) and the newer PowerShell
7 (`pwsh.exe`).

Users may run the same rbenv commands in either shell, and both must be able to
work with the same version files. Their different text-encoding defaults make
that less straightforward than it looks.

## Strings and file bytes

PowerShell strings are not the same thing as the bytes written to a file.
When another program reads that file, the writer and reader must agree on an
encoding. This matters for rbenv's `global.txt` and `.ruby-version`, which are
used by both the PowerShell commands and the D executables.

## The defaults are not the same

For new or empty files, without an explicit `-Encoding`:

| Command | Windows PowerShell 5.1 | PowerShell 7 |
| --- | --- | --- |
| `Set-Content` | System ANSI code page | UTF-8 without a BOM |
| `Out-File` | UTF-16LE with a BOM | UTF-8 without a BOM |

Even in 5.1, the default depends on the cmdlet. The ANSI code page also depends
on the system locale. Do not assume that omitting `-Encoding` means UTF-8
everywhere.

For example, writing `3.2.1` with `-NoNewline` produces these bytes:

```text
ASCII / UTF-8 without BOM:  33 2E 32 2E 31
UTF-8 with BOM:             EF BB BF 33 2E 32 2E 31
UTF-16LE with BOM:          FF FE 33 00 2E 00 32 00 2E 00 31 00
```

The BOM is a marker at the beginning of a Unicode file. A reader that simply
treats every byte as part of the version string can mistake it for version
data. UTF-16 also stores this example's characters as two-byte code units.
`-NoNewline` only suppresses the final newline; it does not select an encoding
or remove a BOM.

### Explicit UTF-8 still differs

`-Encoding UTF8` is not identical across these versions:

| Explicit encoding | Windows PowerShell 5.1 | PowerShell 7 |
| --- | --- | --- |
| `-Encoding UTF8` | UTF-8 **with** BOM | UTF-8 **without** BOM |
| `-Encoding ASCII` | ASCII, no BOM | ASCII, no BOM |

ASCII is appropriate only when the permitted text is ASCII. It cannot represent
arbitrary Unicode text. For an ASCII-only version such as `3.2.1`, ANSI and
UTF-8 also happen to produce the same bytes, so an encoding mistake can remain
unnoticed in normal testing.

## What we did in rbenv

### `rbenv global`: `Out-File` without an encoding

An earlier implementation wrote the global version using:

```powershell
$version | Out-File $GLOBAL_VERSION_FILE -NoNewline
```

Although the newline was removed, Windows PowerShell 5.1 still wrote UTF-16LE
with a BOM. This was not a safe format for the D implementation, which read
the file as bytes and cast those bytes to a string without decoding them.
It could therefore interpret the BOM and zero bytes as part of the version.

In 2023, commit `c46681d` changed this to explicitly use ASCII:

```powershell
$version | Out-File $GLOBAL_VERSION_FILE -NoNewline -Encoding ASCII
```

This produced the same BOM-free bytes in PowerShell 5.1 and 7 for ASCII version
names. The current [global command](../libexec/rbenv-global.ps1) delegates to
`rbenv-exec.exe`, which checks that the installed version is ASCII and writes
the same bytes without a BOM or newline.

### `rbenv local`: `Set-Content` without an encoding

The previous [local command](../libexec/rbenv-local.ps1) used:

```powershell
Set-Content $local_version_file $version -NoNewline
```

This relied on the PowerShell version and, in 5.1, the system's ANSI code page.
The usual version strings are ASCII, so this often produced the expected bytes,
but the file format was not explicitly defined. An externally created
`.ruby-version` may also use a different encoding.

The current implementation delegates version resolution and writing to
`rbenv-exec.exe`. D matches the requested version against installed Rubies,
removes the RubyInstaller suffix, then writes `.ruby-version` in the current
directory as UTF-8 bytes without a BOM or newline. This preserves the portable
`.ruby-version` format and does not depend on PowerShell's `Set-Content` default.

### Reading old files

Changing the writer does not change files that already exist. The shared D
reader in [version_files.d](../source/rbenv/version_files.d) therefore still accepts UTF-8
with or without a BOM, and BOM-marked UTF-16LE or UTF-16BE, converting the
contents to UTF-8 before interpreting the version. Invalid encodings are
reported rather than silently treated as a valid version.

This does not mean every legacy ANSI file is supported: a BOM-free file is
interpreted as UTF-8. ASCII-only files are valid UTF-8, but non-ASCII bytes
from an old system code page may not be.

## Checking the bytes

Inspect the bytes rather than relying only on how a text editor displays a file:

```powershell
$bytes = [System.IO.File]::ReadAllBytes($path)
[System.BitConverter]::ToString($bytes)
```

For cross-version testing, run the same write in both `powershell.exe` and
`pwsh.exe`. Test the reader as well as the writer: the resulting file must
be usable by the fake `ruby.exe` and by `rbenv current`.

## References

- [Microsoft: about Character Encoding, Windows PowerShell 5.1](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding?view=powershell-5.1)
- [Microsoft: about Character Encoding, PowerShell 7](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding?view=powershell-7.5)
