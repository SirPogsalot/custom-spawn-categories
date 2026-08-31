@echo off
setlocal EnableExtensions
cd /d "%~dp0"

rem ---------------------------------------------------------------------------
rem Friendly wrapper for the PowerShell compatibility checker.
rem
rem Accepted inputs (order-independent, up to two):
rem   - generator-*.zip
rem   - mcreator.exe OR an MCreator installation folder containing mcreator.exe
rem
rem Common examples:
rem   check-compatibility.bat "C:\path\generator-26.1.x.zip"
rem   check-compatibility.bat "C:\path\generator-1.21.8.zip" "C:\Program Files\Pylo\MCreator 2026.1\MCreator"
rem
rem If the generator ZIP is inside <MCreator>\plugins, the PowerShell checker can
rem automatically infer that MCreator installation, so dragging the ZIP alone is
rem normally enough.
rem ---------------------------------------------------------------------------

set "GENERATOR_ZIP="
set "MCREATOR_EXE="
set "ARG_ERROR="

if not "%~1"=="" call :classify "%~1"
if not "%~2"=="" call :classify "%~2"
if not "%~3"=="" (
    echo ERROR: Too many arguments. Supply at most one generator ZIP and one MCreator target.
    set "ARG_ERROR=1"
)

if defined ARG_ERROR (
    echo.
    echo Usage:
    echo   check-compatibility.bat "C:\path\generator-XX.X.x.zip"
    echo   check-compatibility.bat "C:\path\generator-XX.X.x.zip" "C:\path\to\MCreator"
    echo.
    pause
    exit /b 2
)

if defined GENERATOR_ZIP (
    if defined MCREATOR_EXE (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-compatibility.ps1" -GeneratorZip "%GENERATOR_ZIP%" -MCreatorExe "%MCREATOR_EXE%"
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-compatibility.ps1" -GeneratorZip "%GENERATOR_ZIP%"
    )
) else (
    if defined MCREATOR_EXE (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-compatibility.ps1" -MCreatorExe "%MCREATOR_EXE%"
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-compatibility.ps1"
    )
)

set "EXIT_CODE=%ERRORLEVEL%"
echo.
if "%EXIT_CODE%"=="0" (
    echo Compatibility check completed with no hard failures.
) else if "%EXIT_CODE%"=="3" (
    echo Compatibility check was incomplete. Check the report for missing input.
) else (
    echo Compatibility check found one or more hard failures.
)
echo See the reports folder in the source root for full details.
echo.
pause
exit /b %EXIT_CODE%

:classify
set "INPUT_PATH=%~f1"
if not exist "%INPUT_PATH%" (
    echo ERROR: Input does not exist: %~1
    set "ARG_ERROR=1"
    goto :eof
)

if /I "%~x1"==".zip" (
    if defined GENERATOR_ZIP (
        echo ERROR: More than one ZIP was supplied. Supply exactly one generator ZIP.
        set "ARG_ERROR=1"
    ) else (
        set "GENERATOR_ZIP=%INPUT_PATH%"
    )
    goto :eof
)

if /I "%~x1"==".exe" (
    if defined MCREATOR_EXE (
        echo ERROR: More than one MCreator target was supplied.
        set "ARG_ERROR=1"
    ) else (
        set "MCREATOR_EXE=%INPUT_PATH%"
    )
    goto :eof
)

if exist "%INPUT_PATH%\mcreator.exe" (
    if defined MCREATOR_EXE (
        echo ERROR: More than one MCreator target was supplied.
        set "ARG_ERROR=1"
    ) else (
        set "MCREATOR_EXE=%INPUT_PATH%\mcreator.exe"
    )
    goto :eof
)

echo ERROR: Unrecognized input: %~1
echo        Expected a generator ZIP, mcreator.exe, or an MCreator installation folder.
set "ARG_ERROR=1"
goto :eof
