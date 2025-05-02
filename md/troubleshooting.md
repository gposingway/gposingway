# GPosingway Troubleshooting Guide

Having issues with GPosingway? Use this guide to resolve common problems.

---

## Installation Issues

### Permissions Error
- **Problem**: The installation script lacks permission to modify files.
- **Solution**:
  1. Right-click the `game` folder and select `Properties`.
  2. Go to the `Security` tab and select `Users`.
  3. Click `Edit` and check the `Modify` permission.
  4. Click `Apply` to save changes.

### GPosingway Not Working
- **Problem**: Incorrect installation or version mismatch.
- **Solution**:
  - Ensure the correct GPosingway version is installed for your ReShade version.
  - Place the installer script or extracted files directly in the `game` folder.
  - Rename old shader and preset folders to avoid conflicts.

### Error Messages
- **Problem**: Conflicts with other mods or missing files.
- **Solution**:
  - Check for mod conflicts, especially with Dalamud.
  - Delete the `dxgi.log` file and restart the game.

---

## Usage Issues

### Presets Not Saving
- **Problem**: ReShade lacks permission to save changes.
- **Solution**:
  1. Right-click the `reshade-presets` folder and select `Properties`.
  2. Go to the `Security` tab and select `Users`.
  3. Click `Edit` and check the `Modify` permission.
  4. Click `Apply` to save changes.

### Misaligned Effects in Screenshots
- **Problem**: Incompatible resolution scaling settings.
- **Solution**:
  - Disable the following options:
    - `Enable dynamic resolution`
    - `Limb Darkening`
    - `Enable depth of field`
  - Set `3D Resolution Scaling` to `100` and `Edge Smoothing` to `FXAA` or `Off`.

### Empty or Placeholder Files
- **Understanding**: Files like `zfast_crt.fx` with just a `_x_gposingway_placeholder` technique are intentional.
- **Purpose**: These placeholder files prevent technique conflicts between different shader collections.
- **What to Do**: Do not delete these files or modify them, as they are vital for compatibility.

---

## Q&A

### How does GPosingway work?
GPosingway provides a curated collection of shaders, textures, and presets to ensure compatibility and stability. It eliminates common issues like missing files or shader conflicts, allowing presets to work as intended.

### Can I use GPosingway with an existing ReShade installation?
Yes, but it is recommended to rename your existing `reshade-shaders` and `reshade-presets` folders before installing GPosingway. This ensures no conflicts arise between the two setups.

### Are all shader collections included in GPosingway?
No, some shader collections, like [iMMERSE](https://github.com/martymcmodding/iMMERSE/blob/main/LICENSE), cannot be redistributed due to licensing restrictions. You may need to download these separately.

### Can I use any preset with GPosingway?
Yes, most presets should work without additional configuration. Ignore instructions to copy `.fx` and `.fxh` files, as GPosingway already includes the necessary shaders.

---

## Performance Issues

### Game Running Slowly
- **Problem**: High resource usage from shaders.
- **Solution**:
  - Press `Shift + F3` to toggle effects.
  - Disable unused shaders.

---

## Need More Help?
- **GitHub Issues**: Report problems or request support via [GitHub Issues](https://github.com/gposingway/gposingway/issues).
- **Discord**: Join the [Sights of Eorzea Discord Server](https://discord.com/servers/sights-of-eorzea-1124828911700811957) for community support.

---

## Important Reminders
- **Back Up Files**: Always back up your FFXIV game files before installing tools.
- **Compatibility**: Use compatible versions of ReShade and GPosingway.
