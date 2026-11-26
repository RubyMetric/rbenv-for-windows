:: --------------------------------------------------------------
:: Copyright © 2023-2026 Aoran Zeng
:: SPDX-License-Identifier: MIT
:: --------------------------------------------------------------
:: File          : rbenv.bat
:: Authors       : Aoran Zeng <ccmywish@qq.com>
:: Created on    : <2026-11-26>
:: Last modified : <2026-11-26>
::
:: rbenv:
::
::   Delegate to 'rbenv.ps1'
:: --------------------------------------------------------------

@echo off
if not defined RBENV_ROOT (
    >&2 echo rbenv: environment variable RBENV_ROOT must be set
    exit /b 1
)

setlocal
set "rbenv_powershell=powershell.exe"
"%SystemRoot%\System32\where.exe" pwsh.exe >nul 2>&1
if not errorlevel 1 set "rbenv_powershell=pwsh.exe"

if "%~1"=="" goto noargs
%rbenv_powershell% -NoProfile -File "%~dp0rbenv.ps1" -cmd %*
exit /b %errorlevel%

:noargs
%rbenv_powershell% -NoProfile -File "%~dp0rbenv.ps1"
exit /b %errorlevel%
