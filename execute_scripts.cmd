@echo off

:: Executes all PowerShell scripts inside the scripts folder and its subfolders as administrator, logs each execution result, and keeps the console open at the end.

setlocal EnableExtensions EnableDelayedExpansion
title PowerShell Script Executor

fltmc >nul 2>&1

if errorlevel 1 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%ComSpec%' -ArgumentList '/c','\"%~f0\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

set "SCRIPT_DIR=%~dp0scripts"
set "LOG_FILE=%~dp0script_execution.log"

set /a TOTAL=0
set /a SUCCESS=0
set /a ERRORS=0

dir /b /s "%SCRIPT_DIR%\*.ps1" >nul 2>&1

if errorlevel 1 (
    echo No .ps1 files were found.
    goto FINAL
)

for /r "%SCRIPT_DIR%" %%F in (*.ps1) do (

    set /a TOTAL+=1

    echo.
    echo ============================================================
    echo Executing: %%~fF
    echo ============================================================
    echo.

    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { & '%%~fF'; exit 0 } catch { Write-Host ''; Write-Host '[ERROR]' $_.Exception.Message -ForegroundColor Red; exit 1 }"

    set "RESULT=!ERRORLEVEL!"

    if "!RESULT!"=="0" (
        set "EXEC_SUCCESS=True"
        set "EXEC_ERROR=False"
        set /a SUCCESS+=1
        echo [OK] %%~nxF
    ) else (
        set "EXEC_SUCCESS=False"
        set "EXEC_ERROR=True"
        set /a ERRORS+=1
        echo [ERROR] %%~nxF
    )

    >> "%LOG_FILE%" echo ============================================================
    >> "%LOG_FILE%" echo Start: !date! !time!
    >> "%LOG_FILE%" echo File: %%~fF
    >> "%LOG_FILE%" echo Executed successfully: !EXEC_SUCCESS!
    >> "%LOG_FILE%" echo Executed with error: !EXEC_ERROR!
    >> "%LOG_FILE%" echo ============================================================
)

:FINAL

echo.
echo ============================================================
echo FINAL RESULT
echo ============================================================
echo.
echo Total found : %TOTAL%
echo Successful  : %SUCCESS%
echo Errors      : %ERRORS%
echo.
echo Log:
echo %LOG_FILE%
echo.

pause