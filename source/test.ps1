Write-Host -f blue "=> Test fake ruby.exe"
rdmd .\ruby.d -v
rdmd .\ruby.d --versino
Write-Host ""

Write-Host -f blue "=> Test rbenv-exec.exe : rehash-gem"
rdmd .\rbenv-exec.d rehash-gem     cr
Write-Host ""

Write-Host -f blue "=> Test rbenv-exec.exe : rehash-version"
rdmd .\rbenv-exec.d rehash-version 3.1
Write-Host ""

Write-Host -f blue "=> Test rbenv-exec.exe : shim-get-gem"
rdmd .\rbenv-exec.d shim-get-gem   "C:Ruby-on-Windows\shims\cr.bat"
Write-Host ""

Write-Host -f blue "=> Test rbenv-exec.exe : list-who-has"
rdmd .\rbenv-exec.d list-who-has   cr
