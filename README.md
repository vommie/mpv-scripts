# MPV Scripts

This repository contains a collection of individual Lua scripts designed to enhance the functionality of the [MPV media player](https://mpv.io/). All scripts are written by [vommie](https://github.com/vommie) and released into the **public domain**—feel free to use, modify, or distribute them as you wish! They are only tested on Linux.

## Installation

To use these scripts, copy them into MPV's script directory:
- **Linux**: `~/.config/mpv/scripts/`
- **Windows**: `C:\Users\<YourUsername>\AppData\Roaming\mpv\scripts\`
- **MacOS**: `~/.config/mpv/scripts/`

Ensure the `.lua` files are placed directly in the `scripts` folder. MPV will load them automatically on startup.

## Scripts

Below is a brief description of each script included in this collection:

- **`ab_repeat.lua`**
 Enables frame-precise A-B looping. Set a start (A) and end (B) point to repeat a section of the video or audio. You can also save, load and delete multiple ab-repeats per video, an `ab-repeat.json` file inside of the mpv config directory is used as "database".
 *Default keybindings*: `HOME` (A), `END` (B), `DEL` (reset), `CTRL+S` (save an ab-repeat), `CTRL+L` (load an ab-repeat), `CTRL+DEL` (delete one or all ab-repeats).


- **`zoom_at_mouse.lua`**
 Zooms into the video centered on the mouse cursor using the mouse wheel while holding `Alt`. Experimental feature.
 *Default keybindings*: `Alt+WHEEL_UP` (zoom in), `Alt+WHEEL_DOWN` (zoom out), `Alt+r` (reset).

- **`mouse_fast_play.lua`**
 Increases playback speed when holding the left mouse button, similar to YouTube's fast-play feature.
 *Default keybinding*: `MBTN_LEFT` (hold to speed up, release to resume normal speed).

## Customization

Each script includes comments in the source code explaining how to modify keybindings or settings (e.g., zoom step, fast-play speed). Refer to the [MPV documentation](https://mpv.io/manual/stable/) for valid key names and further details.

## License

All scripts are **public domain**. No restrictions apply—do whatever you want with them!
