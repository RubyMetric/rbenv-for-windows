Write-Host "=> Test fake ruby.exe"
rdmd .\ruby.d -v
rdmd .\ruby.d --versino

Write-Host ""

Write-Host "=> Test rbenv-exec.exe"
rdmd .\rbenv-exec.d rehash-gem     cr
rdmd .\rbenv-exec.d rehash-version 3.1
rdmd .\rbenv-exec.d shim-get-gem   "C:Ruby-on-Windows\shims\cr.bat"
