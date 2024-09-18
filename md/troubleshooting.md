# GPosingway Troubleshooting Guide

Having problems with GPosingway? Let's get you back on track!

# Installation Issues

### GPosingway isn't working after install
  * **Version Check**: Ensure you've downloaded the correct GPosingway version for your installed ReShade.
  * **Installer Script**: If you're using the installer script, place the file directly in your main FFXIV folder.
  * **Zip File Install**: If using the zip, extract its contents into your main FFXIV `game` folder.
  * **Existing ReShade**: If you already have ReShade, rename its old shader and preset folders to prevent conflicts.

### Error messages during install or when starting FFXIV
  * **Mod Conflicts**: Check for conflicts with other mods, particularly Dalamud.
  * Delete the "dxgi.log" file in your FFXIV folder and restart the game.

### Presets look wrong or cause glitches
  * **Shader Conflicts**: If you're using shaders from other sources, they might be causing issues. Most preset collections should work fine with GPosingway without needing additional shaders.

# Usage

### Changes to presets (like shortcuts or adjusted configurations) aren't saved

**Permissions Issue**: This is likely due to ReShade not having permission to save changes to the preset files.
* Fix:
  * Right-click the `reshade-presets` folder in your `game` folder.
  * Select `Properties`.
  * Go to the `Security` tab.
  * Find the `Users` entry.
  * If the `Modify` permission is not checked like in the following image, click `Edit`:  
  ![image](https://github.com/user-attachments/assets/01b232c3-f2a7-40e5-8b4a-bbdc674ed15f)  
  * Select `Users`.
  * Check the `Modify` permission so the list looks like this:  
  ![image](https://github.com/user-attachments/assets/8cf8b772-69d7-45a2-ab3c-1eb210ad2e8a)
  * Click `Apply`.

### My screenshot shows some effect areas displaced to the side
**Scaling Issues**: This is caused by a incompatible resolution scaling value, like in the example below:  
![image](https://github.com/user-attachments/assets/bdd9d332-3d06-443e-b373-cc39ac175d64)  
Resulting in misplaced effect areas like the following example:  
![image-mh](https://github.com/user-attachments/assets/9c6410aa-821d-4e51-9ad7-cb3e15e0beeb)
* Fix:
  * Make sure the following options are **disabled**:
    * `Enable dynamic resolution`
    * `Naturally darken the edges of the screen (Limb Darkening)`
    * `Enable depth of field`
  * Make sure the following options are set:
   * `3D Resolution Scaling` to `100`
   * `Edge Smoothing (Anti-aliasing)` to `FXAA` or `Off`

# Other Problems

### FFXIV is running slower with GPosingway
  * Press `Shift + F3` to turn effects on and off.
  * Turn off any shaders you're not using.

### Need More Help?
  * **GPosingway Support:** Visit the Issues section on the GPosingway GitHub page: [https://github.com/gposingway/gposingway](https://github.com/gposingway/gposingway)
  * **Discord:** Chat with the GPosingway team on the Sights of Eorzea Discord server: [https://discord.com/servers/sights-of-eorzea-1124828911700811957](https://discord.com/servers/sights-of-eorzea-1124828911700811957)

### Important Reminders
  * **Back up your files:** Always make a copy of your FFXIV game files before installing any tools, just in case.
  * **Compatibility:** GPosingway works best with certain versions of ReShade and FFXIV. Make sure you're using the right ones.
