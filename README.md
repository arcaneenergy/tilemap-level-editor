# Tilemap Level Editor (Archived)

![Banner](readme/banner.png)

Simple level editor for Godot with JSON export functionality. Made with Godot.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/E1E5CVWWE)

- [Github Project](https://github.com/arcaneenergy/tilemap-level-editor)
- [YouTube](https://www.youtube.com/c/ArcaneEnergy)
- [Website](https://arcaneenergy.github.io/)


---

## Download

Download the exported program on itch.io.

[**itch.io download link**](https://arcaneenergy.itch.io/tilemap-level-editor)

## Video
[<img src="https://img.youtube.com/vi/01ktb-9E6J0/maxresdefault.jpg" width="50%">](https://youtu.be/01ktb-9E6J0)

## Use case

This is currently used in a personal project. It's used to load in JSON files into Godot to recreate the levels at runtime. The exported JSON file contains all levels and individual cells. This makes it easy to recreate the level in Godot.

Alternatively, you can use this program to easily create levels in the editor.

## Controls

Placement:
- Left click: Place tile (if selected)
- Right click: Delete tile

Other:
- TAB: Toggle GUI
- SHIFT + Scroll up: Increase brush size
- SHIFT + Scroll down: Decrease brush size

Camera:
- Middle mouse drag: Drag camera around
- W / ↑: Move camera up
- S / ↓: Move camera down
- A / ←: Move camera left
- D / →: Move camera right
- Mouse scroll up: Zoom in
- Mouse scroll down: Zoom out

## UI Overview

Create new layers with the `+ New Layer` button. This brings up a dialog box for selecting an image file. After selecting a file, the new layer appears in the list.

Switch between layers by pressing the arrow to the left of the layer. This will open the tileset on the left. Use the up and down arrow keys to move layers.

![Screenshot 1](readme/screenshot_1.png)

Select a tile and start drawing.

![Screenshot 2](readme/screenshot_2.png)

Change the size and shape of the cursor using the buttons in the lower right corner.

![Screenshot 3](readme/screenshot_3.png)

## Exported JSON file

The exported JSON file might look like this:

```json
{
    "layers": [
        {
            "texture_path": "C:/tilemap-level-editor/test/tileset.png",
            "cells": [
                [
                    4,
                    -5,
                    -3
                ],
            ]
        }
    ],
    "objects": [
        {
            "key": "player",
            "position": [
                2,
                4
            ]
        }
    ]
}
```

Each cell contains an ID, an x and a y position. The ID is used to identify which cell in the tileset it refers to.

## Problems

- [ ] Currently the program only supports tiles of 16x16 size. The spritesheet needs to be divisible by 16 (16, 32, 48, 64 etc.)
- [ ] Exported texture paths are absolute.

Godot_v3.5-rc2
