@echo off
:: =============================================================================
:: CR380 - Docker Lab — Multipass Provisioner (Windows)
:: =============================================================================
::
:: FR: Lance une VM Multipass avec cloud-init pour le lab Docker.
:: EN: Launch a Multipass VM with cloud-init for the Docker lab.
::
:: Usage: provision-multipass.bat [vm-name]
:: =============================================================================
setlocal

:: ---- Phase 1: Variables ---------------------------------------------------
set "VM_NAME=cr380-docker"
if not "%~1"=="" set "VM_NAME=%~1"

set "SCRIPT_DIR=%~dp0"
set "CLOUD_INIT=%~dp0user-data-fresh.yaml"

:: ---- Phase 2: Prerequisite checks ----------------------------------------
where multipass >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: multipass is not installed.
    echo   Install from: https://multipass.run
    endlocal
    exit /b 1
)

if not exist "%CLOUD_INIT%" (
    echo ERROR: Cloud-init file not found:
    echo   %CLOUD_INIT%
    endlocal
    exit /b 1
)

:: ---- Phase 3: VM existence check + launch ---------------------------------
multipass info "%VM_NAME%" >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo VM '%VM_NAME%' already exists. Delete it first:
    echo   multipass delete %VM_NAME% ^&^& multipass purge
    endlocal
    exit /b 1
)

echo Launching VM '%VM_NAME%'... (this may take 2-5 minutes)
multipass launch 24.04 --name "%VM_NAME%" --cloud-init "%CLOUD_INIT%" --cpus 2 --memory 4G --disk 20G
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to launch VM '%VM_NAME%'.
    echo   If partially created, clean up with:
    echo   multipass delete %VM_NAME% ^&^& multipass purge
    endlocal
    exit /b 1
)

:: ---- Phase 4: Success message ---------------------------------------------
echo.
echo VM '%VM_NAME%' is ready.
echo   Shell:  multipass shell %VM_NAME%
echo   Mount:  multipass mount %SCRIPT_DIR%.. %VM_NAME%:/home/ubuntu/CR380-docker-lab
echo   Delete: multipass delete %VM_NAME% ^&^& multipass purge

endlocal
exit /b 0
