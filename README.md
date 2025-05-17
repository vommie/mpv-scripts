# MPV Scripts

This repository contains a collection of individual Lua scripts designed to enhance the functionality of the [MPV media player](https://mpv.io/). They are only tested on Linux.

## Installation

To use these scripts, copy them into MPV's script directory:
- **Linux**: `~/.config/mpv/scripts/`
- **Windows**: `C:\Users\<YourUsername>\AppData\Roaming\mpv\scripts\`
- **MacOS**: `~/.config/mpv/scripts/`

Ensure the `.lua` files are placed directly in the `scripts` folder. MPV will load them automatically on startup.

## Scripts

- **`ab_repeat.lua`**
 Adds frame-precise A-B looping and a save/load feature for A-B repeats. Set a start (A) and end (B) point to repeat a section of the video or audio. You can save, load and delete multiple ab-repeats, a file `ab-repeat.json` inside of the mpv config directory is used as storage.
 *Default keybindings*: `HOME` (A), `END` (B), `DEL` (reset), `CTRL+S` (save an ab-repeat), `CTRL+L` (load an ab-repeat), `CTRL+DEL` (delete one or all ab-repeats).

- **`mouse_fast_play.lua`**
 Increases playback speed when holding the left mouse button, similar to YouTube's fast-play feature.
 *Default keybinding*: `MBTN_LEFT` (hold to speed up, release to resume normal speed). A threshold ensures not to interfere with single or double clicks.

- **`zoom_at_mouse.lua`**
 Zooms into the video centered on the mouse cursor using the mouse wheel while holding `Alt`. Experimental feature, it's just an idea and needs to be improved.
 *Default keybindings*: `Alt+WHEEL_UP` (zoom in), `Alt+WHEEL_DOWN` (zoom out), `Alt+r` (reset).

## Customization

Each script includes comments in the source code explaining how to modify keybindings or settings.
Refer to the [MPV documentation](https://mpv.io/manual/stable/) for valid key names and further details.

## License

All scripts in this repository are public domain. No restrictions apply—do whatever you want with them!
