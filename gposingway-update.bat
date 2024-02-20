echo off
cls
echo ------------------------------------------------
echo (\(\
echo ( o.o)    GPosingway Update Tool
echo O_(")(")
echo ------------------------------------------------
echo.

rem Shows the user the currently installed version, if available:

IF EXIST gposingway-version.txt (
	echo Current version: 
	copy gposingway-version.txt con >nul
	echo.
)

IF EXIST ffxiv_dx11.exe (
	goto check-current-version
) ELSE (
	echo.
	echo The Final Fantasy XIV executable [ffxiv_dx11.exe] was not found!
	echo.
	echo Make sure this update tool is in the game folder:
	echo [..]SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game
	echo.
	echo Exiting the update tool.

	goto done
)

rem Let's check the current version.
:check-current-version
echo.
echo Latest version: 
bitsadmin /transfer gposingway-version /download /priority FOREGROUND "https://github.com/gposingway/gposingway/releases/latest/download/gposingway-version.txt" "%cd%\gposingway-version-temp.txt" >nul
copy gposingway-version-temp.txt con >nul
echo.

rem compare the versions, but only if gposingway-version.txt exists locally:
IF EXIST gposingway-version.txt (
	fc gposingway-version.txt gposingway-version-temp.txt > nul
	if errorlevel 1 goto update-available
	goto newest-version-installed
) ELSE (
    goto update-available
)

rem Both the local and remote version files are identical, so there's nothing to do!
:newest-version-installed
echo.
echo You have the latest version!
del gposingway-version-temp.txt
goto done

rem The local and remote version files are different: let's download the latest available patch from the repository

:update-available
echo.
echo Downloading the latest version. This may take a minute...
bitsadmin /transfer gposingway-patch /download /priority FOREGROUND "https://github.com/gposingway/gposingway/releases/latest/download/gposingway.zip" "%cd%\gposingway-patch.zip" >nul
echo ...download finished. Unpacking...
powershell -command "Expand-Archive -Force '%~dp0gposingway-patch.zip' '%~dp0'"

echo ...unpacking finished. Cleaning up...

rem remove the patch file...
del gposingway-patch.zip

rem then the current version file...
IF EXIST gposingway-version.txt (
	del gposingway-version.txt
)

rem and rename the downloaded version file as the current version.
ren gposingway-version-temp.txt gposingway-version.txt

echo.
echo You now have the latest version. Happy GPosing!
goto done

:done
exit /b