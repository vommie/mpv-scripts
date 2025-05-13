-- This script enables a "hold to fast-play" feature in MPV (similar to YouTube). When the left mouse button (MBTN_LEFT) is held down for a specified duration, the playback speed increases to a user-defined fast speed. Releasing the button returns the speed to normal (1.0).
--
-- Keybinding: "MBTN_LEFT" (left mouse button) triggers the fast-play feature. Change the last line to another key or mouse button (e.g., "f", "SPACE", "MBTN_RIGHT") if desired.
--
-- This script was inspired and based on https://github.com/Ciacconas/mpv-scripts/blob/master/hold_accelerate.lua

-- This source code is public domain, do whatever you want.

local mp = require("mp")

local decay_delay = 0.05  -- Delay before OSD updates (in seconds), typically no need to change
local osd_duration = math.max(decay_delay, mp.get_property_number("osd-duration") / 1000)  -- Matches MPV's OSD duration
local fast_speed = 2.0    -- Speed multiplier when holding the button (e.g., 2.0 = 2x speed). Adjust this to change how fast playback becomes.
local hold_threshold = 0.25  -- Time in seconds to hold the button before fast playback starts. Increase for a longer delay, decrease for quicker response.

local timer = nil
local is_held = false

local function set_fast_speed()
    if is_held then
        mp.set_property("speed", fast_speed)
    end
end

local function fast_play(table)
    if table == nil then return end

    if table["event"] == "down" then
        is_held = true
        if timer then
            timer:kill()
        end
        timer = mp.add_timeout(hold_threshold, set_fast_speed)

    elseif table["event"] == "up" then
        is_held = false
        if timer then
            timer:kill()
        end
        mp.set_property("speed", 1.0)
    end
end

mp.add_forced_key_binding("MBTN_LEFT", "hold_fast", fast_play, { complex = true, repeatable = false })
