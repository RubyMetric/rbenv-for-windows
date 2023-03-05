Write-Host "=> Test fake ruby.exe"
rdmd .\ruby.d -v
rdmd .\ruby.d --versino

Write-Host ""

Write-Host "=> Test rbenv-rehash.exe"
rdmd .\rbenv-rehash.d gem cr
rdmd .\rbenv-rehash.d version 3.1

Write-Host ""

Write-Host "=> Test rbenv-shim.exe"
rdmd .\rbenv-shim.d get_gem_executable "C:Ruby-on-Windows\shims\cr.bat"
