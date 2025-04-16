# GPosingway Installation Guide

GPosingway is powered by ReShade, a powerful post-processing tool. To get started, you need to install ReShade first, followed by GPosingway. Follow the steps below to set up your environment.

---

## ReShade Installation

### General Steps
1. **Download the Installer**:
   - Visit the [ReShade website](https://reshade.me) or use the [MediaFire repository](https://www.mediafire.com/folder/reshade_versions) to download the latest version of ReShade with Add-On support.

2. **Run the Installer**:
   - Launch the ReShade installer and click `Browse...`.  
     ![Browse Button](https://github.com/gposingway/gposingway/assets/18711130/6a57b0d1-5684-441b-94b3-01254d38095a)
   - Locate the `ffxiv_dx11.exe` file in the `game` folder and click `Open`.  
     ![Select Game File](https://github.com/gposingway/gposingway/assets/18711130/433815f2-3648-4efd-b8c3-18786bd1a657)

3. **Select Rendering API**:
   - Choose the appropriate rendering API (DirectX 10/11/12 for most users).  
     ![Rendering API](https://github.com/gposingway/gposingway/assets/18711130/45358023-2100-455c-9619-7c04f5487b4d)

4. **Skip Optional Steps**:
   - In the `Select preset to install` and `Select effect packages to install` windows, click `Skip`.  
     ![Skip Preset](https://github.com/gposingway/gposingway/assets/18711130/c458f994-5b5e-495f-9c4e-04122a63b4a6)
     ![Skip Effects](https://github.com/gposingway/gposingway/assets/18711130/0ff6a3ae-32f4-408a-935a-db9c8d30fb89)

5. **Finish Installation**:
   - Click `Finish` to complete the setup.
     ![Finish Installation](https://github.com/gposingway/gposingway/assets/18711130/9ab2bf1f-a809-4130-aea7-0f767e8dbe84)

### Notes
- Ensure compatibility between the ReShade version and GPosingway.
- If you encounter issues, refer to the [Troubleshooting Guide](troubleshooting.md).

---

## GPosingway Installation

### Manual Installation
1. **Extract the Package**:
   - Right-click the downloaded GPosingway package and select `Extract All...`.
     ![Extract All](https://github.com/gposingway/gposingway/assets/18711130/7968f27b-f5b5-4c1c-ba07-5911a8f7a79e)
   - Click `Extract` in the dialog box.
     ![Extract Button](https://github.com/gposingway/gposingway/assets/18711130/7d3c3978-355e-4b0e-9a74-c64ab2318f65)

2. **Copy Files**:
   - Copy all files and folders from the extracted package to the `game` folder of your FFXIV installation (e.g., `SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game`).
     ![Copy Files](https://github.com/gposingway/gposingway/assets/18711130/5654b154-4599-4623-94f2-d177c5668a18)

3. **Verify Installation**:
   - Launch the game. If you see GPosingway instructions on startup, the installation was successful.
     ![Startup Instructions](https://github.com/gposingway/gposingway/assets/18711130/65ef0e5f-f49e-4903-9105-acd9bb9c41e9)

### Using the Installer
1. **Prepare the Installer**:
   - Copy the `gposingway-update.bat` file to the `game` folder of your FFXIV installation.
     ![Installer File](https://github.com/gposingway/gposingway/assets/18711130/ab2da9d6-bf6c-4c15-bf44-20a8ddae69a1)

2. **Run the Installer**:
   - Double-click `gposingway-update.bat`.
     ![Run Installer](https://github.com/gposingway/gposingway/assets/18711130/9cf1ac93-20b7-41f3-b17e-4e44babb59fc)
   - If prompted by Windows Defender, click `More Info` and then `Run Anyway`.
     ![Run Anyway](https://github.com/gposingway/gposingway/assets/18711130/a47d0795-caa3-4a7e-a9f8-75d7b2d8961e)
   - Follow the on-screen instructions to complete the installation.
     ![Installer Instructions](https://github.com/gposingway/gposingway/assets/18711130/57dbca2b-be15-4e7a-af70-ec97fbe3e03a)

3. **Update GPosingway**:
   - To update, run `gposingway-update.bat` again. The installer will patch your installation.
     ![Update Installer](https://github.com/gposingway/gposingway/assets/18711130/6dc7431a-9793-46b3-9889-434b645bac8e)

---

## Additional Resources
- [GPosingway GitHub Repository](https://github.com/gposingway/gposingway)
- [Sights of Eorzea Discord Server](https://discord.com/servers/sights-of-eorzea-1124828911700811957)
