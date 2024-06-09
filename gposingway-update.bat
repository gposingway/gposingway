@echo off
cls
setlocal enabledelayedexpansion
setlocal ENABLEEXTENSIONS

:: 2024/06/08   1.0.2   FIX - replaced BITSADMIN with powershell for file transfer
:: 2024/06/08   1.0.1   FIX - Added checks for pre-existing directories before attempting backup

:: Configuration 
set "GPOSINGWAY_DEFINITIONS_URL=https://github.com/gposingway/gposingway/releases/latest/download/gposingway-definitions.json"
set "GAME_DIR=%~dp0"
set "GPOSINGWAY_WORK_DIR=%GAME_DIR%.gposingway"
set "BACKUP_DIR=%GPOSINGWAY_WORK_DIR%\Backup"
set "TEMP_DIR=%GPOSINGWAY_WORK_DIR%\temp"

for /f "tokens=1-6 delims=/: " %%a in ('robocopy "|" . /njh /ndl ^| find ":"') do (
    set "DATE_TIME=%%a-%%b-%%c-%%d-%%e-%%f"
)

:: Welcome Message
echo ------------------------------------------------
echo  (\(\
echo  ( o.o)    GPosingway Update/Installer Tool
echo  O_(")(")
echo ------------------------------------------------
echo.
echo Welcome to the GPosingway Installer^^!
echo.
echo Let's check some things before we start...

:: Check FFXIV executable and working directory
if not exist ffxiv_dx11.exe (
    echo.
    echo Please make sure this .BAT file is placed in your FFXIV game directory:
    echo "[...]\SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game"
    pause
    exit /b 1
)

:: Check ReShade installation
if not exist dxgi.dll (
    echo WARNING: ReShade with full add-on support not found.
    echo GPosingway requires the latest version of ReShade.
    echo Download it from: https://reshade.me/
    pause
)

:: Create working directory
if not exist "%GPOSINGWAY_WORK_DIR%" md "%GPOSINGWAY_WORK_DIR%"
if not exist "%TEMP_DIR%" md "%TEMP_DIR%"

:: Check GPosingway installation status

set "CURRENT_VERSION="
if exist "%GPOSINGWAY_WORK_DIR%\gposingway-definitions.json" (
    for /f "delims=" %%a in ('powershell -command "Get-Content '%GPOSINGWAY_WORK_DIR%\gposingway-definitions.json' | ConvertFrom-Json | Select-Object -ExpandProperty version"') do set "CURRENT_VERSION=%%a"
) else if exist "%GPOSINGWAY_WORK_DIR%\gposingway-version.txt" (
    set /p CURRENT_VERSION=<"%GPOSINGWAY_WORK_DIR%\gposingway-version.txt"
)

if defined CURRENT_VERSION (
    echo.
) else (
    set "INITIAL_INSTALL=true"
)

:: User choice for initial installation
if defined INITIAL_INSTALL (
    :INSTALL_CHOICE
    echo No previous GPosingway found^^! Proceed with installation?
    choice /c YN /m "[Y]es or [N]o"
    if errorlevel 2 (
        echo Installation aborted.
        exit /b 0
    ) else if errorlevel 1 (
        goto :MAIN
    )
)

GOTO :MAIN

:: Download subroutine
:DOWNLOAD

set result=

echo - Downloading %2...

powershell.exe -Command "& { (New-Object System.Net.WebClient).DownloadFile('%1', '%3') }"
if !errorlevel! neq 0 (
    echo ERROR: Failed to download %2.
    pause
    exit /b 1
)
echo - ...done^^!
GOTO :EOF

:: Extract subroutine
:EXTRACT
if not exist "%TEMP_DIR%" md "%TEMP_DIR%"
powershell -command "Expand-Archive -Force '%1' '%2%'" >nul
if !errorlevel! neq 0 (
    echo ERROR: Failed to extract %1.
    pause
    exit /b 1
)

GOTO :EOF

:: Main installation/update process

:MAIN

:: Download definitions file
call :DOWNLOAD "%GPOSINGWAY_DEFINITIONS_URL%" "Latest GPosingway definitions" "%TEMP_DIR%\gposingway-definitions.json"

:: Get latest version and patch URL from definitions

for /f "delims=:," %%a in ('powershell -command "Get-Content '%TEMP_DIR%\gposingway-definitions.json' | ConvertFrom-Json | Select-Object -ExpandProperty version"') do set "LATEST_VERSION=%%a"

echo  Latest version: %LATEST_VERSION%

if defined INITIAL_INSTALL goto :do-installation

echo Current version: %CURRENT_VERSION%


    if "!LATEST_VERSION!" == "!CURRENT_VERSION!" (
        echo Seems you have the latest version already, no updates necessary^^!
        GOTO :deprecated-cleanup
    )

    if not "!LATEST_VERSION!" == "!CURRENT_VERSION!" (
        echo A newer version of GPosingway is available^^! Do you want to install this update?
        CHOICE /C YN /M "[Y]es or [N]o"
        if errorlevel 2 exit /b 0
        set INSTALL_UPDATE=1
        goto :do-installation
    )

goto :optional-installations

:do-installation

if not exist "%TEMP_DIR%\gposingway-definitions.json" exit /b 1
for /f "delims=" %%a in ('powershell -command "Get-Content '%TEMP_DIR%\gposingway-definitions.json' | ConvertFrom-Json | Select-Object -ExpandProperty gposingwayUrl"') do set "GPOSINGWAY_PATCH_URL=%%a"

echo.
echo Backing up existing shaders and presets...

if not exist "%BACKUP_DIR%" md "%BACKUP_DIR%"
if not exist "%BACKUP_DIR%\%DATE_TIME%" md "%BACKUP_DIR%\%DATE_TIME%"

if exist "reshade-shaders\" (
    robocopy "reshade-shaders" "%BACKUP_DIR%\%DATE_TIME%\reshade-shaders" /e >nul

    if !errorlevel! gtr 8 (
        echo ERROR: Failed to back up reshade-shaders.
        pause
        exit /b 1
    )
)

if exist "reshade-presets\" (
    robocopy "reshade-presets" "%BACKUP_DIR%\%DATE_TIME%\reshade-presets" /e >nul
    if !errorlevel! gtr 8 (
        echo ERROR: Failed to back up reshade-presets.
        pause
        exit /b 1
    )
)

echo Done^^! You can find your full backup here:
echo   %BACKUP_DIR%\%DATE_TIME%

if exist "reshade-shaders\" (
    :: Clean shaders folder for initial installation
    if defined INITIAL_INSTALL rd /s /q "reshade-shaders\shaders"
)

:: Download and extract patch

echo.
Echo Now I'll download and install the update. Sit tight^^!
call :DOWNLOAD "%GPOSINGWAY_PATCH_URL%" "latest GPosingway package" "%TEMP_DIR%\gposingway.zip"
call :EXTRACT "%TEMP_DIR%\gposingway.zip" "."

:: Process definitions JSON

:deprecated-cleanup

:: Deprecated items
echo.
echo Doing some clean-up...
if not exist "%TEMP_DIR%\gposingway-definitions.json" exit /b 1
for /f "delims=" %%a in ('powershell -command "Get-Content '%TEMP_DIR%\gposingway-definitions.json' | ConvertFrom-Json | Select-Object -ExpandProperty Deprecated"') do (
    for %%b in (%%a) do (

        rmdir /s /q "%GAME_DIR%%%~b" 2>nul
        del /q /f "%GAME_DIR%%%~b" 2>nul
    )
)

::Optional installation
:optional-installations

if not exist "%TEMP_DIR%\gposingway-definitions.json" exit /b 1
set "OPTIONAL_NAMES="
for /f "tokens=*" %%a in ('powershell -command "Get-Content '%TEMP_DIR%\gposingway-definitions.json' | ConvertFrom-Json | Select-Object -ExpandProperty Optional | Select-Object -ExpandProperty Name"') do (
    set "OPTIONAL_NAMES=!OPTIONAL_NAMES! %%a"
)

if not defined OPTIONAL_NAMES (
    goto :wrap-up
) 

echo.
echo Some optional add-ons are available^^!

for %%a in (!OPTIONAL_NAMES!) do (

    echo Would you like to install %%a?
    choice /c YN /m "[Y]es or [N]o"
    if !errorlevel! equ 1 (

        for /f "tokens=*" %%c in ('powershell -command "Get-Content '%TEMP_DIR%\gposingway-definitions.json' | ConvertFrom-Json | Select-Object -ExpandProperty Optional | Where-Object {$_.Name -eq '%%a'} | Select-Object -ExpandProperty Url"') do set "OPTIONAL_URL=%%c"
        for /f "tokens=*" %%c in ('powershell -command "Get-Content '%TEMP_DIR%\gposingway-definitions.json' | ConvertFrom-Json | Select-Object -ExpandProperty Optional | Where-Object {$_.Name -eq '%%a'} | Select-Object -ExpandProperty Mappings"') do set "OPTIONAL_MAPPINGS=%%c"

        echo Installing optional add-on: %%a

        if not exist "%TEMP_DIR%\%%a" md "%TEMP_DIR%\%%a"
        call :DOWNLOAD !OPTIONAL_URL! %%a "%TEMP_DIR%\%%a\%%a.zip"
        call :EXTRACT "%TEMP_DIR%\%%a\%%a.zip" "%TEMP_DIR%\%%a"

        for %%d in (!OPTIONAL_MAPPINGS!) do (
            for /f "tokens=1,2 delims=;:" %%e in ("%%~d") do (
                if exist "%TEMP_DIR%\%%a\%%~e" (
                    echo - %%~e to "%%~f"

                    set "MAP_SOURCE=%TEMP_DIR%\%%a\%%~e"
                    set "MAP_DEST=%%~f"

                    robocopy "!MAP_SOURCE!" "!MAP_DEST!" /e >nul
                )
            )
        )
        echo.
    )
)

:wrap-up
copy "%TEMP_DIR%\gposingway-definitions.json" "%GPOSINGWAY_WORK_DIR%\gposingway-definitions.json" >nul

:: Clean up
echo.
echo Removing all temporary files (%TEMP_DIR%)...

rd /s /q "%TEMP_DIR%"

echo.
echo GPosingway installation/update complete. Happy GPosing^^!

pause