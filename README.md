# GPosingway

![GPosingway Mascot](https://github.com/gposingway/gposingway/assets/18711130/c919c030-dff2-47e8-905d-f52d098aaa45)

This is a drop-in set for Final Fantasy XIV containing the DirectX 10/11/12 ReShade injector, a stable collection of shaders, textures, and presets gathered from the community and beyond. Gposingway aims to ensure that presets will work as intended by its creators by avoiding conflicts, mismatches and missing files, giving users a consistent experience.

---

**Current GPosingway version**: 5.8.0 Release 1  
**Current ReShade version**: 5.8.0 with add-on support

---

# Getting Started 

> [!IMPORTANT]
> **If you currently have any ReShade version installed on your XIV game folder**: Because of the possibility of conflicts with pre-existing, mismatched shaders, it is not advisable to merge Gposingway with a previous ReShade installation.

<br>

## Common scenario: Windows 10/11, DirectX 10/11/12

* [Download](https://github.com/gposingway/gposingway/releases/download/5.8.0R1/gposingway-580-r1.zip) this Community Patch (`gposingway-580-r1.zip`) and unzip. You'll see something like this:  
<img src='https://github.com/gposingway/gposingway/assets/18711130/5418bba7-784c-41eb-b751-b8310176d27b' alt='Screenshot of unzipped contents'>

* Copy and paste all the files and folders from the unzipped file to the XIV `game` folder (`SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game` by default.) Once finished, you'll see something like this:

<img src='https://github.com/gposingway/gposingway/assets/18711130/a896aa20-8970-4a80-8328-3bf030db22ab' alt='Screenshot of unzipped contents'>

* Launch the game. If you see the following instructions you're good to go!

![image](https://github.com/gposingway/gposingway/assets/18711130/65ef0e5f-f49e-4903-9105-acd9bb9c41e9)

<br>

## Alternative scenario: Other rendering APIs (DirectX 9, OpenGL, Vulkan) or Operating Systems

* [Download](https://www.mediafire.com/file/jtf9igqacroz5mz/ReShade_Setup_5.8.0.exe/file) and install ReShade 5.8.0, selecting no presets and no filters; that will only deploy the injector.

* Download and unzip GPosingway as described before, but remove the bundled ReShade injector (`dxgi.dll`) from the unzipped folder.
  
* Proceed with the copy and paste of the remaining unzipped files as described above.

---

## Features

- **Stable Baseline:** Gposingway offers a carefully curated collection of distributable shaders and textures, providing a stable foundation for your ReShade setup. This baseline helps avoid compatibility issues across different preset collections, ensuring a consistent and reliable experience.

- **Community Contributions:** Gposingway integrates presets, shaders, and fixes contributed by the FFXIV community; the patch contains a comprehensive package that reflects the diverse preferences and styles of preset creators.

- **Easy Integration:** Installing Gposingway is a breeze. Simply drop it into your existing FFXIV installation, and you're ready to go. No complex configurations or manual tweaks required.

## Q&A

### How does it work?

The package contains the ReShade 5.8.0 DirectX 10/11/12 injector (`dxgi.dll`) and all the necessary elements for the included preset collections to work as intended by their respective creators in the most common usage scenario; some community contributions like `FFKeepUI` were added, while some default shaders were renamed or removed to avoid conflicts.

### Why does it use ReShade 5.8.0 instead of the latest?

Gposingway currently utilizes ReShade version 5.8.0 as the baseline for compatibility reasons. This version has been thoroughly tested with the included shaders and provides a stable experience. Future updates may include support for newer ReShade versions.

### I have ReShade (or other ReShade-based injectors) already installed. How should I proceed?

Uninstall ReShade, if possible; alternatively, you can rename your pre-existing `reshade-shaders` folder to something else, merge the contents of the `reshade-presets` folder and manually move specific textures under the old `reshade-shaders\textures` used by your presets to the new folder of the same name. There are **no guarantees** that previously existing presets will continue working, though.

### Are there plans to support newer ReShade versions in the future?

Yes, the plan is to support newer ReShade versions in future updates. We aim to stay up-to-date with ReShade developments and provide users with the latest enhancements. Keep an eye on our GitHub repository for announcements and updates.

## Contribution Guidelines

We welcome contributions from the FFXIV community. If you have a preset collection, shader, or fix that you believe would benefit Gposingway users, feel free to submit a pull request!

Before contributing, please review our [contribution guidelines](CONTRIBUTING.md) to ensure a smooth collaboration process.

## Support and Feedback

If you encounter issues, have suggestions, or simply want to connect with other Gposingway users, visit the [Sights of Eorzea Discord server](https://discord.com/servers/sights-of-eorzea-1124828911700811957). We value your feedback and strive to create an inclusive and vibrant community.

## Included Preset collections

| Collection | Creator | License | Notes |
| --- | --- | --- | --- |
| IpsuShade | [Ipsusu](https://twitter.com/ipsusu) | [License](https://github.com/ipsusu/IpsuShade/blob/master/LICENSE.md) | [Download Page](https://github.com/ipsusu/IpsuShade)  |
| WiFi | [Wi-Fi ₍ᐢ.ˬ.ᐢ₎ 黒うさぎ](https://twitter.com/wifi_photospire) | MIT | [Download Page](https://potatoworshiper.wixsite.com/jagaimo-no-sekai/wifi-presets)  |
| Yomigami Okami | [Yomy](https://twitter.com/Yomigammy) | MIT - [License](https://github.com/MeynanAneytha/YomigamiOkami-reshade-shaders/blob/main/LICENSE) | Original [ReShade port](https://github.com/MeynanAneytha/YomigamiOkami-reshade-shaders#yomigamiokami-reshade-560-port) by [Meynan Aneytha](https://twitter.com/meynan_ffxiv) |
---

[GPosingway · a ReShade / XIV Community Patch](https://github.com/gposingway/gposingway/tree/main) is licensed under [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/?ref=chooser-v1) 
<img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/cc.svg?ref=chooser-v1">
<img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/by.svg?ref=chooser-v1">

Individual work elements (e.g. presets, shaders, textures) may have distinct distribution terms; check the list of included works above for their respective licenses.
