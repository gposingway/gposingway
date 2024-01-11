# GPosingway

![GPosingway Mascot](https://github.com/gposingway/gposingway/assets/18711130/c919c030-dff2-47e8-905d-f52d098aaa45)

This is a drop-in package for Final Fantasy XIV containing a stable collection of shaders, textures, and presets gathered from the community and beyond. Gposingway aims to ensure that presets will work as intended by its creators by avoiding conflicts, mismatches and missing files, giving users a consistent experience.

---

**Current GPosingway version**: 5.8.0 Release 1  
**Current ReShade version**: 5.8.0 with add-on support

---

# Installation

Check out the latest [release](https://github.com/gposingway/gposingway/releases/tag/5.8.0R1) - you'll find detailed instructions for all the required steps to get you started.

---

## Features

- **Stable Baseline:** Gposingway offers a carefully curated collection of distributable shaders and textures, providing a stable foundation for your ReShade setup. This baseline helps avoid compatibility issues across different preset collections, ensuring a consistent and reliable experience.

- **Community Contributions:** Gposingway integrates presets, shaders, and fixes contributed by the FFXIV community; the patch contains a comprehensive package that reflects the diverse preferences and styles of preset creators.

- **Easy Integration:** Installing Gposingway is a breeze. Simply drop it into your existing FFXIV installation, and you're ready to go. No complex configurations or manual tweaks required.

## Q&A

### How does it work?

The package contains all the necessary elements for the majority of preset collections to work as intended by their respective creators in the most common usage scenarios; some community contributions like `FFKeepUI` were added, while some default shaders were renamed or removed to avoid conflicts.

### Why does it use ReShade 5.8.0 instead of the latest?

Gposingway currently utilizes ReShade version 5.8.0 as the baseline for compatibility reasons. This version has been thoroughly tested with the included shaders and provides a stable experience. Future updates may include support for newer ReShade versions.

### I have ReShade (or other ReShade-based injectors) already installed. How should I proceed?

You can rename your pre-existing `reshade-shaders` and `reshade-shaders` folders to something else prior to deploying GPosingway; this way you can switch between GPosingway and your previous collection. There are **no guarantees** that GPosingway will work with different ReShade versions, however.

### Are there plans to support newer ReShade versions in the future?

Yes, the plan is to support newer ReShade versions in future updates. We aim to stay up-to-date with ReShade developments and provide users with the latest enhancements. Keep an eye on our GitHub repository for announcements and updates.

## Contribution Guidelines

We welcome contributions from the FFXIV community. If you have a preset collection, shader, or fix that you believe would benefit Gposingway users, feel free to submit a pull request!

Before contributing, please review our [contribution guidelines](md/contributing.md) to ensure a smooth collaboration process.

## Support and Feedback

If you encounter issues, have suggestions, or simply want to connect with other Gposingway users, visit the [Sights of Eorzea Discord server](https://discord.com/servers/sights-of-eorzea-1124828911700811957). We value your feedback and strive to create an inclusive and vibrant community.

## Included Preset collections

| Collection | Creator | License | Notes |
| --- | --- | --- | --- |
| IpsuShade | [Ipsusu](https://twitter.com/ipsusu) | [License](https://github.com/ipsusu/IpsuShade/blob/master/LICENSE.md) | [Download Page](https://github.com/ipsusu/IpsuShade)  |
| WiFi | [Wi-Fi ₍ᐢ.ˬ.ᐢ₎ 黒うさぎ](https://twitter.com/wifi_photospire) | MIT | [Download Page](https://potatoworshiper.wixsite.com/jagaimo-no-sekai/wifi-presets)  |
| Yomigami Okami | [Yomy](https://twitter.com/Yomigammy) | MIT - [License](https://github.com/MeynanAneytha/YomigamiOkami-reshade-shaders/blob/main/LICENSE) | Original [ReShade port](https://github.com/MeynanAneytha/YomigamiOkami-reshade-shaders#yomigamiokami-reshade-560-port) by [Meynan Aneytha](https://twitter.com/meynan_ffxiv) |
---

[GPosingway · a ReShade / XIV Community Patch](https://github.com/gposingway/gposingway/tree/main) is [licensed](license.md) under [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/?ref=chooser-v1) 
<img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/cc.svg?ref=chooser-v1">
<img style="height:22px!important;margin-left:3px;vertical-align:text-bottom;" src="https://mirrors.creativecommons.org/presskit/icons/by.svg?ref=chooser-v1">

Individual work elements (e.g. presets, shaders, textures) may have distinct distribution terms; check the list of included works above for their respective licenses.
