# GPosingway Troubleshooting Guide

If you're having trouble with GPosingway, here are some things to try:

## Installation Problems

### GPosingway isn't working after installing
  * Make sure you have the right version of GPosingway for your ReShade.
  * If you're using the installer script, put the file directly in your main FFXIV folder.
  * If you're installing from the zip file, extract the files to your main FFXIV folder.
  * If you already have ReShade installed, rename the old shader and preset folders to avoid conflicts.

### Error messages during install or when starting FFXIV
  * Check for conflicts with other mods, especially Dalamud.
  * Delete the "dxgi.log" file in your FFXIV folder and restart the game.

### Presets look wrong or cause glitches
  * If you're using shaders from other sources, they might be conflicting. Most preset collections should work fine with GPosingway without needing extra shaders.

## Usage problems

### Changes make to presets (like shortcuts or adjusted shaders) aren't saved
- This seems to be permission related (i.e. ReShade isn't able to save changes to the preset files). You can try adjusting the permissions of the preset files themselves: On Windows Explorer, right-click the `reshade-presets` folder, select `properties`, go to the `Security` tab and locate the `Users` entry. If it looks like this:  
![image](https://github.com/user-attachments/assets/01b232c3-f2a7-40e5-8b4a-bbdc674ed15f)  
Then you may need to modify it. Click `Edit`, Select `Users`, check the `Modify` permission, like this:  
![image](https://github.com/user-attachments/assets/8cf8b772-69d7-45a2-ab3c-1eb210ad2e8a)  
And then click Apply. This will allow ReShade to save the preset with your new hotkey.

## Other Problems

### Can't find GPosingway presets
  * Look in the "reshade-presets" folder in your game folder.
  * Open the ReShade menu in the game (usually by pressing Home) and find the Presets tab.

### FFXIV is running slower with GPosingway
  * Press Shift + F2 to turn effects on and off.
  * Turn off any shaders you're not using.

### Need More Help?
  * **GPosingway Support:** Check the Issues section on the GPosingway GitHub page: [https://github.com/gposingway/gposingway](https://github.com/gposingway/gposingway)
  * **Discord:** Talk to the GPosingway team on the Sights of Eorzea Discord server: [https://discord.com/servers/sights-of-eorzea-1124828911700811957](https://discord.com/servers/sights-of-eorzea-1124828911700811957)

### Important Reminders
  * **Back up your files:** Always make a copy of your FFXIV game files before installing any tools, just in case.
  * **Compatibility:** GPosingway works best with certain versions of ReShade and FFXIV. Make sure you're using the right ones.
