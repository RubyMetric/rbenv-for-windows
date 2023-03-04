# Maintain

1. Clean binaries and test

```PowerShell
.\tools\clean.ps1
```

2. Change `bin\source\README.md(i.e. this file)` to add a specific version to be released

3. Build binaries and test

```PowerShell
cd $env:RBENV_ROOT\rbenv
.\tools\build.ps1
```

4. Change `rbenv` version

In `bin\rbenv.ps1`, update `$RBENV_OWN_VERSION`

5. Change `tools\*.ps1` versions and tags

In `tools\install.ps1` and `tools\install-cn.ps1`, change `$tag` and `$$binary_version`

<br>

## Binary versions

### = v0.2.0
**Release time:** `<2023-03-04>`

**Release tag:**  rbenv for Windows tag v1.4.1

<br>

### = v0.1.0
**Release time:** `<2023-02-11>`

**Release tag:**  rbenv for Windows tag v1.3.0
