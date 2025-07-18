@echo off
setlocal enabledelayedexpansion
:: =========================================================
:: 1. Self-elevation
:: =========================================================
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting elevation...
    goto UACPrompt
)
goto Admin
:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B
:Admin
pushd "%CD%"
CD /D "%~dp0"
:: =========================================================
:: 2. Banner & credits
:: =========================================================
title Winget Offline Installer Launcher
cls
echo.
echo =========================================================
echo               Winget Installer Launcher
echo.
echo                   inspired by EXLOUD
echo               https://github.com/EXLOUD
echo =========================================================
echo.
:: =========================================================
:: 3. PowerShell detection (only PowerShell 5)
:: =========================================================
set "PS5_PATH=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
set "PS_EXE="
if exist "%PS5_PATH%" (
    set "PS_EXE=%PS5_PATH%"
    set "PS_VERSION=PowerShell 5"
    goto :psFound
)
echo [ERROR] PowerShell 5 not found.
pause
exit /b 1
:psFound
echo [INFO] Using %PS_VERSION%
:: =========================================================
:: 4. Locate the offline script
:: =========================================================
set "SCRIPT_DIR=%~dp0script"
set "PS_SCRIPT=%SCRIPT_DIR%\Install-Winget.ps1"
if not exist "%PS_SCRIPT%" (
    echo [ERROR] Script not found: %PS_SCRIPT%
    pause
    exit /b 1
)
echo [INFO] Script path: %PS_SCRIPT%
:: =========================================================
:: 5. User confirmation
:: =========================================================
:confirm
set /p "CONFIRM=Proceed with winget installation? (Y/N): "
if /i "!CONFIRM!"=="y" goto :run
if /i "!CONFIRM!"=="yes" goto :run
if /i "!CONFIRM!"=="n" goto :cancel
if /i "!CONFIRM!"=="no" goto :cancel
goto confirm
:cancel
echo Installation cancelled.
pause
exit /b 0
:: =========================================================
:: 6. Launch the PowerShell script
:: =========================================================
:run
cls
echo.
echo [INFO] Starting %PS_VERSION%...
echo.
cd /d "%SCRIPT_DIR%"
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
echo.
echo [INFO] Launcher finished.
pause
exit /b 0