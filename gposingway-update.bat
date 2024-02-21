echo off
cls
echo ------------------------------------------------
echo  (\(\
echo  ( o.o)    GPosingway Update/Installer Tool
echo  O_(")(")
echo ------------------------------------------------
echo.

set must-clear-shader-folder="false"

rem Am I in the correct place?

IF not exist ffxiv_dx11.exe (
echo.
echo Make sure this update script is in the game folder:
echo [..]SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game
echo.
echo Exiting the update script.
pause
goto done
)

if not exist ".gposingway\" mkdir .gposingway

rem Shows the user the currently installed version, if available:

IF EXIST .gposingway\gposingway-version.txt (
	echo Current version: 
	copy .gposingway\gposingway-version.txt con >nul
	echo.
	goto start-installation
) 

rem If not, offers some pre-installation management options

echo It seems this is the first time GPosingway is being installed!
echo.
echo.
echo Options:
echo.
echo [I] - Install GPosingway.
echo       Your current shaders, presets and textures will be copied
echo       to '.gposingway\backup'; After that, your current shader 
echo       collection will be cleared to avoid conflicts.
echo.
echo [C] - Cancel installation.

CHOICE /C IC /M "Press I for Install or C for Cancel."

rem user selected Cancel.
IF ERRORLEVEL ==2 GOTO user-choice-cancel

rem let's set a flag to clear the current shader folder.
set must-clear-shader-folder="true"

GOTO start-installation

:user-choice-cancel
echo.
echo Got it! The installation process was cancelled.
GOTO done

:start-installation

rem Let's check the current version.
:check-current-version
echo.
echo Latest version: 
bitsadmin /transfer gposingway-version /download /priority FOREGROUND "https://github.com/gposingway/gposingway/releases/latest/download/gposingway-version.txt" "%cd%\.gposingway\gposingway-version-temp.txt" >nul
copy .gposingway\gposingway-version-temp.txt con >nul
echo.

rem compare the versions, but only if gposingway-version.txt exists locally:
IF EXIST .gposingway\gposingway-version.txt (
	fc .gposingway\gposingway-version.txt .gposingway\gposingway-version-temp.txt > nul
	if errorlevel 1 goto update-available
	goto newest-version-installed
) ELSE (
    goto update-available
)

rem Both the local and remote version files are identical, so there's nothing to do!
:newest-version-installed
echo.
echo You have the latest version!
del .gposingway\gposingway-version-temp.txt
goto done

rem The local and remote version files are different: let's download the latest available patch from the repository

:update-available
echo.
echo Downloading the latest version. This may take a minute...
bitsadmin /transfer gposingway-patch /download /priority FOREGROUND "https://github.com/gposingway/gposingway/releases/latest/download/gposingway.zip" "%cd%\.gposingway\gposingway-patch.zip" >nul

:backup-current-installation
rem If backup directory doesn't exist, create it.
if not exist ".gposingway\backup\" mkdir .gposingway\backup

rem Obtaining Year, Month and Day values in Batch can be VERY messy...
rem reference: https://stackoverflow.com/questions/3472631/how-do-i-get-the-day-month-and-year-from-a-windows-cmd-exe-script
rem This should work with all datetime formats.

for /F "skip=1 delims=" %%F in ('
    wmic PATH Win32_LocalTime GET Day^,Month^,Year /FORMAT:TABLE
') do (
    for /F "tokens=1-3" %%L in ("%%F") do (
        set day=0%%L
        set month=0%%M
        set year=%%N
    )
)
set day=%day:~-2%
set month=%month:~-2%

set backup-folder-name=%year%-%month%-%day%_%TIME:~0,2%-%TIME:~3,2%-%TIME:~6,2%
set backup-folder-name=%backup-folder-name: =0%

echo.
echo Backing up current installation to .gposingway\backup\%backup-folder-name%...

mkdir .gposingway\backup\%backup-folder-name%

robocopy reshade-presets .gposingway\backup\%backup-folder-name%\reshade-presets /E /NFL /NDL /NJH /NJS /nc /ns >nul
robocopy reshade-shaders .gposingway\backup\%backup-folder-name%\reshade-shaders /E /NFL /NDL /NJH /NJS /nc /ns >nul

:clean-shader-folder

if %must-clear-shader-folder%=="true" (
	rem easiest way is to just remove the folder and recreate it.
	echo Cleaning reshade-shaders\shaders...
	rd /s /q "reshade-shaders\shaders" > nul
	mkdir reshade-shaders\shaders > nul
)

echo Unpacking GPosingway update...
powershell -command "Expand-Archive -Force '%~dp0.gposingway\gposingway-patch.zip' '%~dp0'"

echo Wrapping up...

rem remove the patch file...
del .gposingway\gposingway-patch.zip

rem then the current version file...
IF EXIST .gposingway\gposingway-version.txt (
	del .gposingway\gposingway-version.txt
)

rem and rename the downloaded version file as the current version.
ren .gposingway\gposingway-version-temp.txt gposingway-version.txt

echo Done.

echo.
echo You now have the latest version. Happy GPosing!
goto done

:done
pause
exit /b