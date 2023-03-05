# Maintain

1. Clean binaries and test

```PowerShell
.\tools\clean.ps1
```

2. Change `bin\source\README.md(i.e. this file)` to add a specific version to be released

3. Build binaries and test

```PowerShell
.\tools\build.ps1
```

4. Change `rbenv` version

In `bin\rbenv.ps1`, update `$RBENV_OWN_VERSION`

5. Change `tools\*.ps1` versions and tags

In `tools\install.ps1` and `tools\install-cn.ps1`, change `$tag`

<br>
