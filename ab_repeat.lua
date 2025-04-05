-- This script enables a frame precise A-B repeat functionality in MPV. It allows you to set an A point (start) and a B point (end) in a video or audio file to loop playback between these two points. If only an A point is set, it loops from A to the end of the file. The script also provides a reset function to clear the points.
--
-- Keybindings: You can change the keys used to set A point ("HOME"), B point ("END"), and reset points ("DEL") by modifying the mp.add_key_binding lines below. For example, replace "HOME" with "a" to use the 'a' key instead. Check MPV's documentation for valid key names.
--
-- This source code is public domain, do whatever you want.

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local a_point = nil
local b_point = nil

local function set_a_point()
    a_point = mp.get_property_number("time-pos")
    if a_point then
        mp.osd_message("A point set at " .. string.format("%.2f", a_point) .. "s")
        msg.info("Set A point at " .. string.format("%.3f", a_point) ..
                " seconds | Playback position: " ..
                mp.get_property("time-pos") ..
                " | Duration: " .. mp.get_property("duration"))
    else
        mp.osd_message("Failed to set A point")
        msg.error("Failed to set A point - no time-pos available")
    end
end

local function set_b_point()
    b_point = mp.get_property_number("time-pos")
    if b_point then
        mp.osd_message("B point set at " .. string.format("%.2f", b_point) .. "s")
        msg.info("Set B point at " .. string.format("%.3f", b_point) ..
                " seconds | Playback position: " ..
                mp.get_property("time-pos") ..
                " | Duration: " .. mp.get_property("duration"))

        if a_point then
            if a_point <= b_point then
                mp.osd_message("Starting AB loop: " ..
                              string.format("%.2f", a_point) .. "s -> " ..
                              string.format("%.2f", b_point) .. "s")
                msg.info("Initiating AB loop from " .. string.format("%.3f", a_point) ..
                        " to " .. string.format("%.3f", b_point) .. " seconds")
                mp.commandv("seek", a_point, "absolute", "exact")
            else
                mp.osd_message("Error: B point before A point")
                msg.warn("Invalid loop: B (" .. string.format("%.3f", b_point) ..
                        ") is before A (" .. string.format("%.3f", a_point) .. ")")
                b_point = nil
            end
        end
    else
        mp.osd_message("Failed to set B point")
        msg.error("Failed to set B point - no time-pos available")
    end
end

local function reset_points()
    a_point = nil
    b_point = nil
    mp.osd_message("AB points cleared")
    msg.info("Cleared all AB points | Current position: " ..
            mp.get_property("time-pos") ..
            " | Duration: " .. mp.get_property("duration"))
end

local function check_position()
    local pos = mp.get_property_number("time-pos")
    local duration = mp.get_property_number("duration")

    if pos and duration then
        if a_point and b_point and pos >= b_point then
            mp.commandv("seek", a_point, "absolute", "exact")
            msg.verbose("Looping from " .. string.format("%.3f", b_point) ..
                       " back to " .. string.format("%.3f", a_point))
        elseif a_point and not b_point and pos >= duration then
            mp.commandv("seek", a_point, "absolute", "exact")
            msg.verbose("End reached, jumping to A point at " ..
                       string.format("%.3f", a_point))
        elseif not a_point and b_point then
            mp.commandv("seek", 0, "absolute", "exact")
            msg.verbose("No A point set, jumping to start (0.000)")
            b_point = nil  -- Reset B wenn kein A existiert
        end
    end
end

mp.add_key_binding("HOME", "set-a-point", set_a_point)
mp.add_key_binding("END", "set-b-point", set_b_point)
mp.add_key_binding("DEL", "reset-points", reset_points)

mp.observe_property("time-pos", "number", check_position)

msg.info("AB Repeat Script initialized")
