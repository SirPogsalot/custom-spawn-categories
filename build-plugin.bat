@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"

set "LOG_DIR=%CD%\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss" 2^>nul') do set "BUILD_TIMESTAMP=%%I"
if not defined BUILD_TIMESTAMP set "BUILD_TIMESTAMP=%RANDOM%"
set "LOG_FILE=%LOG_DIR%\build-%BUILD_TIMESTAMP%.log"

call :run_build > "%LOG_FILE%" 2>&1
set "BUILD_EXIT_CODE=%ERRORLEVEL%"

type "%LOG_FILE%"
echo.
if "%BUILD_EXIT_CODE%"=="0" (
    echo Build completed successfully.
) else (
    echo Build failed with exit code %BUILD_EXIT_CODE%.
)
echo Full log:
echo   %LOG_FILE%
echo.
pause
exit /b %BUILD_EXIT_CODE%

:run_build
echo ============================================================
echo Custom Spawn Categories plugin build
echo Started: %DATE% %TIME%
echo Working directory: %CD%
echo ============================================================
echo.

if "%MCREATOR_HOME%"=="" set "MCREATOR_HOME=C:\Program Files\Pylo\MCreator"
set "JDK_BIN=%MCREATOR_HOME%\jdk\bin"
set "APP_EXE=%MCREATOR_HOME%\mcreator.exe"
set "OUTPUT_NAME=custom-spawn-categories-0.3.0-beta1.zip"
set "SOURCE_BUNDLE_NAME=csc-0.3.0-beta1-maintenance-source.zip"

echo MCreator home: %MCREATOR_HOME%
echo Output file:   %CD%\build\%OUTPUT_NAME%
echo.

if not exist "%JDK_BIN%\javac.exe" (
    echo ERROR: Could not find MCreator's javac at:
    echo   %JDK_BIN%\javac.exe
    exit /b 1
)

if not exist "%JDK_BIN%\jar.exe" (
    echo ERROR: Could not find MCreator's jar tool at:
    echo   %JDK_BIN%\jar.exe
    exit /b 1
)

if not exist "%APP_EXE%" (
    echo ERROR: Could not find:
    echo   %APP_EXE%
    exit /b 1
)

if not exist "src\main\java" (
    echo ERROR: Could not find the Java source folder:
    echo   %CD%\src\main\java
    exit /b 1
)

if not exist "src\main\resources" (
    echo ERROR: Could not find the resources folder:
    echo   %CD%\src\main\resources
    exit /b 1
)

echo Java compiler:
"%JDK_BIN%\javac.exe" -version
echo.

echo [1/6] Cleaning build directory...
if exist build rmdir /s /q build
mkdir build\mcreator-api || exit /b 1
mkdir build\classes || exit /b 1
mkdir build\plugin || exit /b 1

echo [2/6] Extracting MCreator application classes...
pushd build\mcreator-api
"%JDK_BIN%\jar.exe" xf "%APP_EXE%"
if errorlevel 1 (
    popd
    echo ERROR: Failed to extract MCreator application classes.
    exit /b 1
)
popd

echo [3/6] Collecting and compiling Java sources...
rem javac argument files treat backslashes as escape characters. Convert all
rem source paths to forward slashes so sequences such as \t and \n are not
rem interpreted as tabs or newlines.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$files = Get-ChildItem -LiteralPath (Join-Path $PWD 'src\main\java') -Recurse -File -Filter '*.java';" ^
  "if (-not $files) { exit 2 };" ^
  "$lines = $files | ForEach-Object { [char]34 + $_.FullName.Replace('\','/') + [char]34 };" ^
  "Set-Content -LiteralPath (Join-Path $PWD 'build\sources.txt') -Value $lines -Encoding ASCII"
if errorlevel 2 (
    echo ERROR: No Java source files were found.
    exit /b 1
)
if errorlevel 1 (
    echo ERROR: Failed to create the Java source list.
    exit /b 1
)

for %%F in (build\sources.txt) do if %%~zF==0 (
    echo ERROR: No Java source files were found.
    exit /b 1
)

echo Source list:
type build\sources.txt
echo.

"%JDK_BIN%\javac.exe" --release 21 -cp "%CD%\build\mcreator-api" -d "%CD%\build\classes" @"%CD%\build\sources.txt"
if errorlevel 1 (
    echo ERROR: Java compilation failed.
    exit /b 1
)

echo [4/6] Copying plugin resources and classes...
xcopy "src\main\resources" "build\plugin" /e /i /q /y
if errorlevel 1 (
    echo ERROR: Failed to copy plugin resources.
    exit /b 1
)

xcopy "build\classes" "build\plugin" /e /i /q /y
if errorlevel 1 (
    echo ERROR: Failed to copy compiled classes.
    exit /b 1
)

echo [5/6] Creating embedded maintenance source bundle...
mkdir "build\maintenance-source\csc-beta1" || exit /b 1
mkdir "build\plugin\maintenance" || exit /b 1

xcopy "src" "build\maintenance-source\csc-beta1\src" /e /i /q /y >nul
if errorlevel 1 exit /b 1
xcopy "docs" "build\maintenance-source\csc-beta1\docs" /e /i /q /y >nul
if errorlevel 1 exit /b 1
xcopy "tools" "build\maintenance-source\csc-beta1\tools" /e /i /q /y >nul
if errorlevel 1 exit /b 1
copy /y "README.md" "build\maintenance-source\csc-beta1\README.md" >nul || exit /b 1
copy /y "CHANGELOG.md" "build\maintenance-source\csc-beta1\CHANGELOG.md" >nul || exit /b 1
copy /y "compatibility-spec.json" "build\maintenance-source\csc-beta1\compatibility-spec.json" >nul || exit /b 1
copy /y "build-plugin.bat" "build\maintenance-source\csc-beta1\build-plugin.bat" >nul || exit /b 1
if exist ".gitignore" copy /y ".gitignore" "build\maintenance-source\csc-beta1\.gitignore" >nul

pushd build\maintenance-source
"%JDK_BIN%\jar.exe" cf "..\%SOURCE_BUNDLE_NAME%" csc-beta1
if errorlevel 1 (
    popd
    echo ERROR: Failed to create the maintenance source bundle.
    exit /b 1
)
popd
copy /y "build\%SOURCE_BUNDLE_NAME%" "build\plugin\maintenance\%SOURCE_BUNDLE_NAME%" >nul || exit /b 1
> "build\plugin\maintenance\README.txt" echo This folder contains the complete source and maintenance kit used to build Custom Spawn Categories 0.3.0-beta1.
>> "build\plugin\maintenance\README.txt" echo Extract csc-0.3.0-beta1-maintenance-source.zip and start with docs\START-HERE.md.

echo [6/6] Assembling plugin ZIP...
pushd build\plugin
"%JDK_BIN%\jar.exe" cf "..\%OUTPUT_NAME%" .
if errorlevel 1 (
    popd
    echo ERROR: Failed to assemble the plugin ZIP.
    exit /b 1
)
popd

echo.
echo Built successfully:
echo   %CD%\build\%OUTPUT_NAME%
echo Embedded/source bundle:
echo   %CD%\build\%SOURCE_BUNDLE_NAME%
echo Finished: %DATE% %TIME%
exit /b 0
