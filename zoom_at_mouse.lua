-- This is a simple MPV script that allows zooming into a video around the mouse cursor position using the mouse wheel while holding Alt.
-- The zoom centers on the mouse position, and the video is cropped to maintain the original resolution. This is still an experimental idea
-- and not perfectly polished - it may have bugs or unexpected behavior.
--
-- Customizable variables:
--   - `zoom_step`: Controls the zoom increment per scroll (default: 0.02). Increase for faster zooming, decrease for finer control.
--   - Keybindings: You can change the bindings near the end of this script (e.g., "Alt+WHEEL_UP", "Alt+WHEEL_DOWN", "Alt+r") to other keys or combinations.
--                 See MPV's documentation for valid key names and syntax.
--
-- This source code is public domain, do whatever you want.

local mp = require "mp"
local msg = require "mp.msg"

local zoom_step = 0.02
local current_zoom = 1.0

local function get_mouse_pos()
    local mouse_x, mouse_y = mp.get_mouse_pos()
    if not mouse_x or not mouse_y then
        msg.error("Fehler: Mausposition konnte nicht abgerufen werden.")
        mp.osd_message("Fehler: Mausposition nicht verfügbar", 2)
        return nil, nil
    end
    msg.info("Mausposition: (" .. mouse_x .. ", " .. mouse_y .. ")")
    return mouse_x, mouse_y
end

local function get_video_dimensions()
    local width = mp.get_property_number("width")
    local height = mp.get_property_number("height")
    if not width or not height then
        msg.error("Fehler: Videoabmessungen konnten nicht abgerufen werden.")
        mp.osd_message("Fehler: Videoabmessungen nicht verfügbar", 2)
        return nil, nil
    end
    msg.info("Videoabmessungen: " .. width .. "x" .. height)
    return width, height
end

local function zoom_at_mouse(direction)
    local new_zoom = current_zoom + (direction * zoom_step)
    if new_zoom < 1.0 then new_zoom = 1.0 end

    local mouse_x, mouse_y = get_mouse_pos()
    local vid_width, vid_height = get_video_dimensions()
    if not mouse_x or not vid_width then
        msg.error("Zoom abgebrochen: Ungültige Mausposition oder Videoabmessungen")
        return
    end

    local osd_width = mp.get_property_number("osd-width")
    local osd_height = mp.get_property_number("osd-height")
    if not osd_width or not osd_height then
        msg.error("Fehler: OSD-Abmessungen konnten nicht abgerufen werden.")
        mp.osd_message("Fehler: OSD-Abmessungen nicht verfügbar", 2)
        return
    end
    msg.info("OSD-Abmessungen: " .. osd_width .. "x" .. osd_height)

    local scale_x = vid_width / osd_width
    local scale_y = vid_height / osd_height
    msg.info("Skalierungsfaktor: (" .. scale_x .. ", " .. scale_y .. ")")

    local target_x = mouse_x * scale_x
    local target_y = mouse_y * scale_y
    msg.info("Zielpunkt im Video: (" .. target_x .. ", " .. target_y .. ")")

    local zoomed_width = vid_width * new_zoom
    local zoomed_height = vid_height * new_zoom
    msg.info("Gezoomte Dimensionen: " .. zoomed_width .. "x" .. zoomed_height)

    local offset_x = (target_x * new_zoom) - target_x
    local offset_y = (target_y * new_zoom) - target_y
    msg.info("Offset: (" .. offset_x .. ", " .. offset_y .. ")")

    offset_x = math.max(0, math.min(offset_x, zoomed_width - vid_width))
    offset_y = math.max(0, math.min(offset_y, zoomed_height - vid_height))
    msg.info("Begrenzter Offset: (" .. offset_x .. ", " .. offset_y .. ")")

    local debug_msg = string.format("Zoom: %.1f%% | Maus: (%d, %d) | Video: %dx%d",
        new_zoom * 100, mouse_x, mouse_y, vid_width, vid_height)
    mp.osd_message(debug_msg, 2)
    msg.info(debug_msg)

    local vf = string.format("lavfi=[scale=%f*iw:%f*ih,crop=%d:%d:%f:%f]",
        new_zoom, new_zoom, vid_width, vid_height, offset_x, offset_y)
    msg.info("Setze Video-Filter: " .. vf)
    local success = mp.set_property("vf", vf)
    if success then
        msg.info("Video-Filter erfolgreich gesetzt")
    else
        msg.error("Fehler beim Setzen des Video-Filters")
        mp.osd_message("Fehler beim Zoomen", 2)
    end

    current_zoom = new_zoom
end

local function reset_zoom()
    local success = mp.set_property("vf", "")
    current_zoom = 1.0
    msg.info("Zoom zurückgesetzt, Erfolg: " .. tostring(success))
end

mp.add_key_binding("Alt+WHEEL_UP", "zoom_in_at_mouse", function()
    msg.info("Alt + Mausrad hoch erkannt")
    zoom_at_mouse(1)
end)

mp.add_key_binding("Alt+WHEEL_DOWN", "zoom_out_at_mouse", function()
    msg.info("Alt + Mausrad runter erkannt")
    zoom_at_mouse(-1)
end)

mp.add_key_binding("Alt+r", "reset_zoom", reset_zoom)

mp.register_event("file-loaded", function()
    reset_zoom()
end)
