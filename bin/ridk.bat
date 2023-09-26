:: --------------------------------------------------------------
:: File          : ridk.bat
:: Authors       : Aoran Zeng <ccmywish@qq.com>
:: Created on    : <2023-09-26>
:: Last modified : <2023-09-26>
::
:: ridk:
::
::   Delegate to real 'ridk.cmd'
:: --------------------------------------------------------------

@echo off
SET cmd="%~dp0\ruby.exe -v"
FOR /F "tokens=2 delims= " %%i IN ('%cmd%') DO SET ver=%%i

%~dp0..\..\%ver%\bin\ridk %*
