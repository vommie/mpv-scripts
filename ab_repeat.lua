
-- This script enables a frame precise A-B repeat functionality in MPV. It allows you to set an A point (start) and a B point (end) in a video or audio file to loop playback between these two points. If only an A point is set, it loops from A to the end of the file. If only an B point is set, it auto loops from the start of the video. The script also provides a reset function to clear the points.
--
-- You can also save, load and delete your AB-Repeats. Multiple AB-Repeat-Ranges per video are allowed. See the Keybindings. When you save an AB-Repeat, you can input an name for it or just press Enter for an default enumerated name.
--
-- Keybindings: You can change the keys used to set A point ("HOME"), B point ("END"), and reset points ("DEL") by modifying the mp.add_key_binding lines below. For example, replace "HOME" with "a" to use the 'a' key instead. Check MPV's documentation for valid key names. There are also Hotkeys for saving ("CTRL+S"), loading ("CTRL+L") and deleting ("CTRL+DEL") AB-Repeat-Ranges.
--
-- This source code is public domain, do whatever you want.

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

-- Configuration Variables
local CONFIG = {
    -- Automatically set A point to 0 if B is set first
    auto_set_a_point = true,
    -- Automatically set B point to last frame if A is set
    auto_set_b_point = true,
    -- Enable end-file handler as fallback for looping when B point is near video end, useful for streams or files with metadata issues
    use_end_file_handler = true,
    -- Show OSD messages for user actions like setting points or starting loops
    show_osd_messages = true,
    -- Tolerance (in seconds) for triggering loop before B point, applied only in the end region for automatic B points
    b_point_tolerance = 0.1,
    -- Duration (in seconds) of the end region before video end where b_point_tolerance is applied
    end_region_duration = 1.0,
    -- Timeout (in seconds) for the end-file handler seek to ensure reliability on slow systems or streams
    end_file_timeout = 0.01,
    -- Duration (in seconds) for displaying the load/delete menu
    menu_display_duration = 10,
    -- Reset AB points when a new file is loaded (different from the current file)
    reset_on_new_file = true,
    -- Show OSD message indicating if stored AB ranges exist for a new file
    show_stored_ranges_message = true
}

local CONFIG_ROOT = (os.getenv('APPDATA') or os.getenv('HOME')..'/.config')..'/mpv/'
if not utils.file_info(CONFIG_ROOT) then
    local mpv_conf_path = mp.find_config_file("scripts")
    local mpv_conf_dir = utils.split_path(mpv_conf_path)
    CONFIG_ROOT = mpv_conf_dir
end
local AB_RANGES_DB = CONFIG_ROOT..'ab_repeat.json'

local a_point = nil
local b_point = nil
local initial_loop_file_value = mp.get_property("loop-file", "no")
local video_duration = 0
local video_fps = 30
local last_video_key = nil

local function jump_to_a_point()
    if a_point then mp.commandv("seek", a_point, "absolute", "exact") end
end

local function show_osd(message, verbose, duration, always_show)
    if always_show or CONFIG.show_osd_messages then
        if duration then mp.osd_message(message, duration) else mp.osd_message(message) end
    end
    if verbose and msg[verbose] then
        msg[verbose](message)
    end
end

local function validate_points(new_point, is_a_point)
    if is_a_point and b_point and new_point > b_point then
        msg.error("Invalid A point: " .. new_point .. " after B: " .. b_point)
        show_osd("Error: A point after B point", "error")
        return false
    elseif not is_a_point and a_point and new_point < a_point then
        msg.error("Invalid B point: " .. new_point .. " before A: " .. a_point)
        show_osd("Error: B point before A point", "error")
        return false
    end
    return true
end

local function start_loop()
    mp.set_property("loop-file", "no")
    show_osd("Starting AB loop: " .. a_point .. " -> " .. b_point, "info")
    jump_to_a_point()
end

local function read_json_file()
    local file = io.open(AB_RANGES_DB, "r")
    if not file then return {} end
    local content = file:read("*all")
    file:close()
    local data = utils.parse_json(content)
    return data or {}
end

local function write_json_file(data)
    local file = io.open(AB_RANGES_DB, "w")
    if not file then
        msg.error("Failed to open file for writing: " .. AB_RANGES_DB)
        show_osd("Failed to save AB range", "error", nil, true)
        return false
    end

    local json_data = utils.format_json(data)
    if not json_data then
        msg.error("Failed to serialize JSON data: " .. utils.to_string(data))
        show_osd("Failed to serialize AB range data", "error", nil, true)
        file:close()
        return false
    end

    local success, write_err = pcall(function() file:write(json_data) end)
    if not success then
        msg.error("Failed to write JSON to file: " .. (write_err or "unknown error"))
        show_osd("Failed to write AB range", "error", nil, true)
        file:close()
        return false
    end

    file:close()
    msg.info("Successfully wrote AB range to " .. AB_RANGES_DB)
    return true
end

local function get_video_key()
    return mp.get_property("path") or ""
end

local function save_ab_range()
    if not a_point or not b_point then
        show_osd("No valid AB range to save", "error", nil, true)
        return
    end

    local data = read_json_file()
    local video_key = get_video_key()
    if not data[video_key] then data[video_key] = {} end
    local range_count = #data[video_key] + 1
    local default_name = "Range " .. range_count

    local input = ""
    local input_active = true
    local key_bindings = {}

    local function update_osd()
        local prompt = "Enter range name (Enter to confirm, Esc to cancel):\n" .. input
        show_osd(prompt, nil, CONFIG.menu_display_duration, true)
    end

    local function cleanup_input()
        input_active = false
        for _, binding in ipairs(key_bindings) do
            mp.remove_key_binding(binding.name)
        end
        key_bindings = {}
    end

    local function handle_input(event)
        if not input_active then return end
        if event.event ~= "down" then return end

        local key = event.key_name
        local text = event.key_text or event.text

        if key == "ENTER" then
            input_active = false
            local range_name = input:match("^%s*(.-)%s*$") or ""
            range_name = range_name ~= "" and range_name or default_name
            table.insert(data[video_key], { a_point = a_point, b_point = b_point, name = range_name })
            if write_json_file(data) then
                show_osd("Saved AB range: " .. range_name, "info", nil, true)
            end
            cleanup_input()
        elseif key == "ESC" then
            input_active = false
            show_osd("Save cancelled", "info", nil, true)
            cleanup_input()
        elseif key == "BS" then
            input = input:sub(1, -2)
            update_osd()
        elseif text and text:match("[%w%-%_%.,%s]") then
            input = input .. text
            update_osd()
        end
    end

    local chars = {
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
        "SPACE", "-", "_", ".", ","
    }

    for _, char in ipairs(chars) do
        local binding_name = "input_" .. char:gsub("[^%w]", "_")
        mp.add_forced_key_binding(char, binding_name, handle_input, { complex = true, repeatable = true })
        table.insert(key_bindings, { name = binding_name })
    end

    mp.add_forced_key_binding("ENTER", "input_enter", handle_input, { complex = true })
    mp.add_forced_key_binding("ESC", "input_esc", handle_input, { complex = true })
    mp.add_forced_key_binding("BS", "input_bs", handle_input, { complex = true, repeatable = true })
    table.insert(key_bindings, { name = "input_enter" })
    table.insert(key_bindings, { name = "input_esc" })
    table.insert(key_bindings, { name = "input_bs" })

    update_osd()

    mp.add_timeout(CONFIG.menu_display_duration, function()
        if input_active then
            input_active = false
            show_osd("Save cancelled", "info", nil, true)
            cleanup_input()
        end
    end)
end

local function show_menu(ranges, callback, action)
    if not ranges or #ranges == 0 then
        show_osd("No saved AB ranges", "info", nil, true)
        return
    end

    local menu_text = (action == "delete" and "Select range to delete (0: All, 1-9: Range):\n" or "Select range (1-9):\n")
    for i, range in ipairs(ranges) do
        menu_text = menu_text .. i .. ": " .. range.name .. " (" .. range.a_point .. " -> " .. range.b_point .. ")\n"
    end
    if #ranges > 9 then
        menu_text = menu_text .. "Warning: Only ranges 1-9 can be selected with keys. Use 0 to delete all (delete menu only)."
    end

    show_osd(menu_text, nil, CONFIG.menu_display_duration, true)
    for i = 1, math.min(#ranges, 9) do
        mp.add_forced_key_binding(tostring(i), "select_range_" .. i, function()
            callback(i)
            for j = 1, math.min(#ranges, 9) do
                mp.remove_key_binding("select_range_" .. j)
            end
            if action == "delete" then
                mp.remove_key_binding("delete_all_ranges")
            end
        end)
    end
    if action == "delete" then
        mp.add_forced_key_binding("0", "delete_all_ranges", function()
            callback(0)
            for j = 1, math.min(#ranges, 9) do
                mp.remove_key_binding("select_range_" .. j)
            end
            mp.remove_key_binding("delete_all_ranges")
        end)
    end
    mp.add_timeout(CONFIG.menu_display_duration, function()
        for j = 1, math.min(#ranges, 9) do
            mp.remove_key_binding("select_range_" .. j)
        end
        if action == "delete" then
            mp.remove_key_binding("delete_all_ranges")
        end
    end)
end

local function load_ab_range_menu()
    local data = read_json_file()
    local video_key = get_video_key()
    local ranges = data[video_key] or {}

    show_menu(ranges, function(index)
        local range = ranges[index]
        a_point = range.a_point
        b_point = range.b_point
        show_osd("Loaded AB range: " .. range.name, "info", nil, true)
        start_loop()
    end, "load")
end

local function delete_ab_range_menu()
    local data = read_json_file()
    local video_key = get_video_key()
    local ranges = data[video_key] or {}

    show_menu(ranges, function(index)
        if index == 0 then
            data[video_key] = nil
            write_json_file(data)
            show_osd("Deleted all AB ranges", "info", nil, true)
        else
            table.remove(ranges, index)
            if #ranges == 0 then
                data[video_key] = nil
            else
                data[video_key] = ranges
            end
            write_json_file(data)
            show_osd("Deleted AB range", "info", nil, true)
        end
    end, "delete")
end

local function set_a_point()
    local pos = mp.get_property_number("time-pos")
    if not pos then
        msg.error("Failed to set A point: no time-pos")
        show_osd("Failed to set A point", "error")
        return
    end

    a_point = pos
    show_osd("A point set at " .. a_point, "info")

    if CONFIG.auto_set_b_point and not b_point then
        if video_duration > 0 and video_fps > 0 then
            b_point = video_duration - (1 / video_fps)
            show_osd("B point set at " .. b_point, "info")
            start_loop()
        else
            msg.error("Failed to set B point: duration=" .. video_duration .. ", fps=" .. video_fps)
            show_osd("Failed to set automatic B point", "error")
            a_point = nil
            return
        end
    elseif b_point and validate_points(a_point, true) then
        start_loop()
    else
        a_point = nil
    end
end

local function set_b_point()
    local pos = mp.get_property_number("time-pos")
    if not pos then
        msg.error("Failed to set B point: no time-pos")
        show_osd("Failed to set B point", "error")
        return
    end

    b_point = pos
    show_osd("B point set at " .. b_point, "info")

    if CONFIG.auto_set_a_point and not a_point then
        a_point = 0
        show_osd("A point set at " .. a_point, "info")
    end

    if a_point and validate_points(b_point, false) then
        start_loop()
    else
        b_point = nil
    end
end

local function reset_points()
    if not a_point and not b_point then
        return
    end
    a_point = nil
    b_point = nil
    mp.set_property("loop-file", initial_loop_file_value)
    show_osd("AB points cleared", "info")
end

local function monitor_loop()
    local pos = mp.get_property_number("time-pos")
    if not pos or not a_point or not b_point then return end

    local end_region = CONFIG.end_region_duration >= 0 and CONFIG.end_region_duration or 0
    local is_near_end = video_duration > 0 and pos >= video_duration - end_region
    local trigger_pos = is_near_end and (b_point - CONFIG.b_point_tolerance) or b_point

    if pos >= trigger_pos then
        jump_to_a_point()
    end
end

local function on_end_file(event)
    if event.reason == "eof" and a_point and b_point then
        if mp.get_property("loop-file") ~= "no" then mp.set_property("loop-file", "no") end
        mp.add_timeout(CONFIG.end_file_timeout, function()
            jump_to_a_point()
        end)
    end
end

local function reset_points_on_new_file(current_video_key)
    if CONFIG.reset_on_new_file and last_video_key and current_video_key ~= last_video_key then
        reset_points()
        msg.info("New file: Reset AB points")
    end
end

local function show_stored_ranges_osd(video_key)
    if not CONFIG.show_stored_ranges_message then
        return
    end
    local data = read_json_file()
    local ranges = data[video_key] or {}
    local count = #ranges
    if count > 0 then
        show_osd(count .. " stored AB range(s) found for this video", "info", 3, true)
    end
end

local function on_file_loaded()
    video_duration = mp.get_property_number("duration") or 0
    if video_duration == 0 then
        msg.warn("Video duration is 0; possibly corrupt file or metadata missing")
    end
    video_fps = mp.get_property_number("container-fps")
    if not video_fps then
        local params = mp.get_property_native("video-params")
        video_fps = params and params.fps
    end
    if not video_fps then
        video_fps = mp.get_property_number("current-vf-fps") or
                    mp.get_property_number("estimated-vf-fps") or
                    30
    end
    msg.info("Initialized video duration: " .. video_duration)
    msg.info("Initialized video FPS: " .. video_fps)

    local current_video_key = get_video_key()
    if current_video_key ~= last_video_key then
        reset_points_on_new_file(current_video_key)
        show_stored_ranges_osd(current_video_key)
    end
    last_video_key = current_video_key
end

mp.register_event("file-loaded", on_file_loaded)
mp.add_key_binding("HOME", "set-a-point", set_a_point)
mp.add_key_binding("END", "set-b-point", set_b_point)
mp.add_key_binding("DEL", "reset-points", reset_points)
mp.add_key_binding("Ctrl+s", "save-ab-range", save_ab_range)
mp.add_key_binding("Ctrl+l", "load-ab-range-menu", load_ab_range_menu)
mp.add_key_binding("Ctrl+DEL", "delete-ab-range-menu", delete_ab_range_menu)

mp.observe_property("time-pos", "number", monitor_loop)
if CONFIG.use_end_file_handler then mp.register_event("end-file", on_end_file) end

msg.info("AB Repeat Script initialized")
