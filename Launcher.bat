@echo off
setlocal enabledelayedexpansion
:: =========================================================
:: 1. Self-elevation
:: =========================================================
if "%1"=="admin" goto :AdminMode

echo [INFO] Launch with admin rights...
"%SystemDrive%\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Command "Start-Process cmd -ArgumentList '/c \"%~f0\" admin' -Verb RunAs"
exit /B

:AdminMode
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
