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

:: Preserve the caller's delayed-expansion setting when returning the version.
setlocal
set "rbenv_delayed=0"
if "!rbenv_delayed!"=="0" set "rbenv_delayed=1"
setlocal DisableDelayedExpansion
if /i "%~1"=="shell" goto shell

:delegate
set "rbenv_powershell=powershell.exe"
"%SystemRoot%\System32\where.exe" pwsh.exe >nul 2>&1
if not errorlevel 1 set "rbenv_powershell=pwsh.exe"

if "%~1"=="" goto noargs
%rbenv_powershell% -NoProfile -File "%~dp0rbenv.ps1" -cmd %*
exit /b %errorlevel%

:noargs
%rbenv_powershell% -NoProfile -File "%~dp0rbenv.ps1"
exit /b %errorlevel%

:shell
if "%~2"=="" goto delegate
if /i "%~2"=="--unset" goto shell_unset
if "%~2"=="-" goto shell_unset

set "rbenv_shell_version="
:: Escaped outer quotes allow the resolver path to contain spaces or ampersands.
for /f "delims=" %%v in ('^""%RBENV_ROOT%\rbenv\libexec\rbenv-exec.exe" _find-installed-version_ "%~2"^"') do set "rbenv_shell_version=%%v"
if not defined rbenv_shell_version exit /b 1

if "%rbenv_delayed%"=="1" set "rbenv_shell_version=%rbenv_shell_version:!=^!%"
endlocal & endlocal & set "RBENV_VERSION=%rbenv_shell_version%"
exit /b 0

:shell_unset
endlocal & endlocal & set "RBENV_VERSION="
exit /b 0
