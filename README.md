# GPosingway

![GPosingway Mascot](https://github.com/gposingway/gposingway/assets/18711130/c919c030-dff2-47e8-905d-f52d098aaa45)

This is a drop-in set for Final Fantasy XIV containing the ReShade redistributable a stable collection of shaders, textures, and presets gathered from the community and beyond. Gposingway aims to ensure that presets will work as intended by avoiding conflicts, mismatches and missing files, helping both preset users and creators.

---

**Current ReShade version**: 5.8.0 with add-on support

---

## Getting Started (clean install)

- [Download](https://github.com/gposingway/gposingway/archive/refs/heads/main.zip) and unzip this Community Patch (`gposingway-main.zip`). You'll see something like this:

![Screenshot of unzipped contents](https://github.com/gposingway/gposingway/assets/18711130/5fc2c3ba-7a64-4443-b048-961dd367dd91)

- Copy and paste all the files and folders from the unzipped file to the XIV `game` folder (`SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game` by default.) Once finished, you'll see something like this:

![image](https://github.com/gposingway/gposingway/assets/18711130/c55110f0-deb1-446c-b869-7c7c4c639c61)

- Launch the game. If you see the following instructions you're good to go!

![image](https://github.com/gposingway/gposingway/assets/18711130/65ef0e5f-f49e-4903-9105-acd9bb9c41e9)

## Features

- **Stable Baseline:** Gposingway offers a carefully curated collection of distributable shaders and textures, providing a stable foundation for your ReShade setup. This baseline helps avoid compatibility issues across different preset collections, ensuring a consistent and reliable experience.

- **Community Contributions:** Gposingway integrates presets, shaders, and fixes contributed by the FFXIV community; the patch contains a comprehensive package that reflects the diverse preferences and styles of preset creators.

- **Easy Integration:** Installing Gposingway is a breeze. Simply drop it into your existing FFXIV installation, and you're ready to go. No complex configurations or manual tweaks required.

- **Regular Updates:** The project is actively maintained to keep up with the evolving FFXIV community and ReShade developments. Expect periodic updates that may include new presets, optimizations, and compatibility fixes.

## Q&A

### How does it work?

The package contains the ReShade 5.8.0 injector (`dxgi.dll`) and all the necessary elements for the included preset collections to work as intended by their respective creators. Some community contributions like `FFKeepUI` were added, while some default shaders were renamed or removed to avoid conflicts.

### Can I drop it over previous installations of ReShade?

Because of the possibility of conflicts with pre-existing, mismatched shaders, that's not advisable. You can however rename your pre-existing `reshade-shaders` folder to something else, and try merging the contents of the `reshade-presets` folder. (There are no guarantees that previously existing presets will continue working, though.)

### Why does it use ReShade 5.8.0 instead of the latest?

Gposingway currently utilizes ReShade version 5.8.0 as the baseline for compatibility reasons. This version has been thoroughly tested with the included shaders and provides a stable experience. Future updates may include support for newer ReShade versions.

### Are there plans to support newer ReShade versions in the future?

Yes, the Gposingway team has plans to support newer ReShade versions in future updates. We aim to stay up-to-date with ReShade developments and provide users with the latest enhancements. Keep an eye on our GitHub repository for announcements and updates.

## Contribution Guidelines

We welcome contributions from the FFXIV community. If you have a preset collection, shader, or fix that you believe would benefit Gposingway users, feel free to submit a pull request!

Before contributing, please review our [contribution guidelines](CONTRIBUTING.md) to ensure a smooth collaboration process.

## Support and Feedback

If you encounter issues, have suggestions, or simply want to connect with other Gposingway users, visit the [Sights of Eorzea Discord server]([https://discord.gg/gposingway](https://discord.com/servers/sights-of-eorzea-1124828911700811957)). We value your feedback and strive to create an inclusive and vibrant community.

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
