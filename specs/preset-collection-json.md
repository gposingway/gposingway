## preset-collection.json Specification (Markdown Table)

This file defines a collection of presets for distribution, targeting a general folder structure.

**Properties**

| Property (Namespace) | Type | Description | Required |
|---|---|---|---|
| name | string | Human-readable name of the preset collection | Yes |
| folder | string | Name of the folder within the target directory for presets | Yes |
| version | string | Version number of the preset collection (e.g., "1.0.0") | No |
| license | string | License identifier for the preset collection (e.g., "MIT") | No |
| tags | array of strings | List of keywords or tags describing the collection | No |
| dependencies.name | string | Name of the dependency (well-known name or URL) | No (within dependencies array) |
| dependencies.url | string | URL of the dependency collection (if not a well-known name) | No (within dependencies array) |
| dependencies.optional | boolean | Flag indicating if the dependency is optional (true) or required (false) | No (within dependencies array, defaults to false) |
| author.name | string | Name of the author | No |
| author.links.* | string | URL of the author's profile on a specific social media platform (key represents platform, e.g., "twitter") | No (within author.links object) |
| description | string | Brief description of the preset collection | No |
| image | string | URL of an image representing the preset collection | No |
| examples.source | string | Location of the example file (relative path or URL) | No (within examples array) |
| examples.description | string | Description of the example file | No (within examples array) |

**Placement:**

The `preset-collection.json` file should be placed at the root level of the preset collection ZIP file. This allows the installer to identify and process the collection information.


## Simple Example (Minimal Information)

This example showcases a basic preset collection with only the required properties.

**preset-collection.json:**

```json
{
  "name": "Aquitaine Studios",
  "folder": "aquitaine-studios"
}
```

**Explanation:**

* `name`: "Aquitaine Studios" - A clear and concise description of the collection's content.
* `folder`: "aquitaine-studios" - Specifies the folder name within the `reshade-shaders` directory where the preset files will be placed.

## Complex Example (All Fields)

This example demonstrates using all the available properties in `preset-collection.json`.

**preset-collection.json:**

```json
{
  "name": "Aquitaine Studios",
  "folder": "aquitaine-studios",
  "version": "1.2.1",
  "license": "CC BY-NC-SA 4.0",
  "tags": ["vintage", "film", "emulation", "analog","abstract"],
  "dependencies": [
    {
      "name": "Aquitaine Studio Common Textures",
      "url": "https://github.com/LeonAquitaine/aquitaineStudios/releases/v1.0.1/common-textures.zip"
    },
    {
      "name": "iMMERSE",
    },
    {
      "name": "iMMERSE PRO",
      "optional": true
    }
  ],
  "author": {
    "name": "Leon Aquitaine",
    "links": {
      "bluesky": "https://bsky.app/profile/leonaquitaine.bsky.social",
      "twitter": "https://twitter.com/LeonAquitaine",
      "github": "https://github.com/LeonAquitaine"
    }
  },
  "description": "A collection of presets that emulate the look and feel of classic vintage film stocks.",
  "image": "https://github.com/LeonAquitaine/aquitaineStudios/releases/v1.0.1/aquitaine-studios-cover.png",
  "examples": [
    {
      "source": "previews/preset1.jpg",
      "description": "Sample of Preset #1"
    },
    {
      "source": "previews/preset2.jpg",
      "description": "Sample of Preset 2"
    }
  ]
}
```

**Explanation:**

This example utilizes all the properties of `preset-collection.json`:

* `name`, `folder`: Similar to the simple example.
* `version`: "1.2.1" - Specifies the collection's version number.
* `license`: "CC BY-NC-SA 4.0" - Defines the license under which the collection is distributed.
* `tags`: ["vintage", "film", "emulation", "analog", "abstract"] - Keywords for searchability.
* `dependencies`: Requires the well-known "iMMERSE" collection.
* `author`: Information about the author, including name and links to social media profiles.
* `description`: A detailed description of the collection's purpose.
* `image`: A URL pointing to a preview image of the collection.
* `examples`: An array of example files showcasing the presets before and after application.
