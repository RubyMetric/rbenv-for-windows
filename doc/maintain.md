# Maintain

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
