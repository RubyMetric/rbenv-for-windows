@echo off
SET cmd="%~dp0\ruby.exe -v"
FOR /F "tokens=2 delims= " %%i IN ('%cmd%') DO SET ver=%%i

%~dp0..\..\%ver%\bin\ridk %*
