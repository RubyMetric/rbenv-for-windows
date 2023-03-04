# Benchmark

## Get version

- **Description:** Directly call **real** ruby.exe to get version info
- **Time:** `25~29ms`

```PowerShell
Ruby-on-Windows\3.2.1-1\bin\ruby.exe -v
```

- **Description:** Directly call **fake** ruby.exe to get version info
- **Time:** `60~63ms`

```PowerShell
ruby.exe -v
```

- **Description:** Get ruby version in normal way. This invokes **fake** `ruby.exe -v` and then call **real** `ruby.exe -v`
- **Time:** `90~94ms`

```PowerShell
ruby -v
# or
ruby --version
```

- **Description:** This invokes 'ruby.exe -v'
- **Time:** `72~76ms`

```PowerShell
rbenv version
```

<br>

**Conclusion: normally, we will always use `ruby -v` to get version, it delays about 65ms.**

<br>

## `ruby` startup time

```PowerShell
# 270~281ms
ruby -e ""

# 270~287ms
ruby -e "puts 'Hello World'"

# 204~220ms
Ruby-on-Windows\3.2.1-1\bin\ruby.exe -e "puts 'Hello World'"
```

**Conclusion: normally, we will always use `ruby -e` to execute, it delays about 65ms.**

<br>

## `gem` startup time

```PowerShell
# 447~480ms
cr -h

# 382~390ms
C:\Ruby-on-Windows\3.2.0-1\bin\cr.bat -h
```

**Conclusion: normally, we will always use `gem name` to execute, it delays about 57~100ms.**
