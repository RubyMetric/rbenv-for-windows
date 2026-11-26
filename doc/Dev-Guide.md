<!-- -----------------------------------------------------------
 ! Copyright © 2026 Aoran Zeng
 ! SPDX-License-Identifier: MIT
 ! -------------------------------------------------------------
 ! Doc Name      : Dev-Guide.md
 ! Doc Authors   : Aoran Zeng <ccmywish@qq.com>
 ! Created On    : <2023-03-04>
 ! Last Modified : <2026-11-26>
 ! ---------------------------------------------------------- -->

## Commonly used commands

1. Clean binaries and test

    ```PowerShell
    .\tool\clean.ps1
    ```

2. Build binaries locally

    ```PowerShell
    .\tool\build.ps1
    ```

3. Test each command

    ```PowerShell
    rbenv version
    rbenv versions

    gem install cr.rb
    rbenv which cr
    rbenv whence cr

    rbenv global 3.1
    rbenv local 3.2
    rbenv shell 3.1.0
    ```


4. Change `rbenv` version

    In `bin\rbenv.ps1`, update `$RBENV_OWN_VERSION`

<br>



## Before release

1. Run `./tool/build.ps1 -Release -Export` to generate binaries

2. Change `./bin/rbenv.ps1` version number

3. Run `chlog` to update `CHANGELOG.md`

4. `git tag -a vx.y.z -m "Release vx.y.z"`

5. Draft a new release `vx.y.z` on GitHub and Gitee

6. Update tag `latest-binary` release on GitHub and Gitee
