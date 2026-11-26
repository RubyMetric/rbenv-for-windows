:: --------------------------------------------------------------
:: Copyright © 2023-2026 Aoran Zeng
:: SPDX-License-Identifier: MIT
:: --------------------------------------------------------------
:: File          : rubyw.bat
:: Authors       : Aoran Zeng <ccmywish@qq.com>
:: Created on    : <2023-09-26>
:: Last modified : <2026-11-26>
::
:: rubyw:
::
::   Delegate to real 'rubyw.exe'
::
:: Note that: `bundle exec rubyw` will execute this script rather
:: than rubyw.ps1
:: --------------------------------------------------------------

@echo off
SET cmd="%~dp0\ruby.exe -v"
FOR /F "tokens=2 delims= " %%i IN ('%cmd%') DO SET ver=%%i

:: start is non-blocking, so the script will not wait for rubyw.exe to finish
start %~dp0..\..\%ver%\bin\rubyw.exe %*
