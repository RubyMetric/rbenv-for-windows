: ---------------------------------------------------------------
: File          : rubyw.bat
: Authors       : Aoran Zeng <ccmywish@qq.com>
: Created on    : <2023-09-26>
: Last modified : <2023-09-26>
:
: ruby:
:
:   Delegate to real 'rubyw.exe'
: ---------------------------------------------------------------

@echo off
SET cmd="%~dp0\ruby.exe -v"
FOR /F "tokens=2 delims= " %%i IN ('%cmd%') DO SET ver=%%i

start %~dp0..\..\%ver%\bin\rubyw.exe %*
