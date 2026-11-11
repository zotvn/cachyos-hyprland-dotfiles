local mainMod = "SUPER"
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")
local qsIpc = "qs -p /home/zotvn/rice/qs-shell ipc call qsshell "
local grid_columns = 5

---------------------------
--------- PLUGINS ---------
---------------------------


-- Gamescope owns a relative pointer, so use its focused window to pick the overview.
hl.bind("SUPER + G", function()
    local w = hl.get_active_window()
    hl.plugin.hyprscape.toggle(w and w.class == "gamescope" and "focused" or "cursor")
end)

-- Перекинуть окно на другой монитор
hl.bind(mainMod .. " + CTRL + SHIFT + Right", hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mainMod .. " + CTRL + SHIFT + Left",  hl.dsp.window.move({ monitor = "-1" }))
hl.bind(mainMod .. " + CTRL + SHIFT + Up",    hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mainMod .. " + CTRL + SHIFT + Down",  hl.dsp.window.move({ monitor = "-1" }))

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------



-- Window manipulation
hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("hyprctl kill"))
local function window_is_game(w)
    if not w then
        return false
    end
    if w.content_type == "game" then
        return true
    end
    local class = string.lower(tostring(w.class or w.initial_class or w.initialClass or ""))
    local title = string.lower(tostring(w.title or w.initial_title or w.initialTitle or ""))
    local patterns = {
        "^steam_app", "gamescope", "%.exe$", "^wine", "lutris", "heroic",
        "minecraft", "lunar client", "osu!", "roblox",
        "deadlock", "cs2", "counter%-strike", "dota", "tf2",
    }
    for _, pattern in ipairs(patterns) do
        if class:match(pattern) or title:match(pattern) then
            return true
        end
    end
    return false
end

-- Games ignore SUPER+Q so they are not closed by accident; SUPER+SHIFT+Q still kills the window under the cursor.
hl.bind(mainMod .. " + Q", function()
    local w = hl.get_active_window()
    if window_is_game(w) then
        return
    end
    hl.dispatch(hl.dsp.window.close())
end)
-- Float active window as centered 16:9 pip; press again to tile back.
-- Any floating window (incl. fullscreen float) tiles on second press — not only PiP size.
-- Lua DSP only — raw `hyprctl dispatch` is intercepted by this Hyprland build and fails.
hl.bind(mainMod .. " + Space", function()
    local w = hl.get_active_window()
    if not w or not w.size then
        return
    end
    if w.floating then
        hl.dispatch(hl.dsp.window.fullscreen_state({ window = w, internal = 0, client = 0 }))
        hl.dispatch(hl.dsp.window.float({ action = "unset", window = w }))
        return
    end
    local pip_w, pip_h = 640, 360
    hl.dispatch(hl.dsp.window.float({ action = "set", window = w }))
    hl.dispatch(hl.dsp.window.resize({ x = pip_w, y = pip_h, relative = false }))
    hl.dispatch(hl.dsp.window.center())
end)
--hl.bind(mainMod .. " + D",           hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + J",           hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + Q",   hl.dsp.exec_cmd("/home/zotvn/rice/bin/hypr-kill-under-cursor"))

-- Change focus. no_warps stays on so the dock does not drag the pointer;
-- these keys move it onto the window they just focused.
local function focus_follow(direction)
    local before = hl.get_active_window()
    local before_addr = before and before.address or ""
    hl.dispatch(hl.dsp.focus({ direction = direction }))
    local w = hl.get_active_window()
    if not w or not w.at or not w.size or w.size.x < 1 or w.size.y < 1 then
        return
    end
    if w.address == before_addr then
        return
    end
    hl.dispatch(hl.dsp.cursor.move({
        x = math.floor(w.at.x + (w.size.x / 2)),
        y = math.floor(w.at.y + (w.size.y / 2)),
    }))
end

hl.bind(mainMod .. " + Left",  function() focus_follow("left") end)
hl.bind(mainMod .. " + Right", function() focus_follow("right") end)
hl.bind(mainMod .. " + Up",    function() focus_follow("up") end)
hl.bind(mainMod .. " + Down",  function() focus_follow("down") end)
hl.bind("ALT + Tab",           hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + Tab",   hl.dsp.window.cycle_next())

-- Move active window around workspaces & monitors
-- hl.bind(mainMod .. " + SHIFT + Up",                   hl.dsp.window.move({ direction = "u" }))
-- hl.bind(mainMod .. " + SHIFT + Right",                hl.dsp.window.move({ direction = "r" }))
-- hl.bind(mainMod .. " + SHIFT + Left",                 hl.dsp.window.move({ direction = "l" }))
-- hl.bind(mainMod .. " + SHIFT + Down",                 hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + 1",                    hl.dsp.window.move({ monitor = MONITOR1 }))
hl.bind(mainMod .. " + SHIFT + 2",                    hl.dsp.window.move({ monitor = MONITOR2 }))
hl.bind(mainMod .. " + SHIFT + 3",                    hl.dsp.window.move({ monitor = MONITOR3 }))
hl.bind(mainMod .. " + SHIFT + 4",                    hl.dsp.window.move({ monitor = MONITOR4 }))
hl.bind(mainMod .. " + SHIFT + mouse_up",             hl.dsp.window.move({ monitor   = "-1" }))
hl.bind(mainMod .. " + SHIFT + mouse_down",           hl.dsp.window.move({ monitor   = "+1" }))
--hl.bind(mainMod .. " + CONTROL + SHIFT + Right",      hl.dsp.window.move({ workspace = "m+1" }))
--hl.bind(mainMod .. " + CONTROL + SHIFT + Left",       hl.dsp.window.move({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "m+1" }))
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + CONTROL + " .. key, hl.dsp.window.move({ workspace = "m~" .. i }))
end

-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Zoom
local function zoomfunction(value)
    local monitor = hl.get_active_monitor()
    if not monitor or monitor.name ~= "PHONE" then
        return
    end
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
-- Zoom is phone-only and clears when focus leaves PHONE.
hl.on("monitor.focused", function(monitor)
    local target = monitor or hl.get_active_monitor()
    if target and target.name ~= "PHONE" then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    end
end)
hl.bind(mainMod .. " + Minus", function() zoomfunction(-0.3) end, { repeating = true})
hl.bind(mainMod .. " + Plus", function() zoomfunction(0.3) end, { repeating = true })

--# Zoom with keypad
hl.bind(mainMod .. " + KP_Subtract", function() zoomfunction(-0.3) end, { repeating = true })
hl.bind(mainMod .. " + KP_Add", function() zoomfunction(0.3) end, { repeating = true })


------------------
---- LAUNCHER ----
------------------

-- Keep terminal apps outside UWSM's short lived app scope. In Peak, Kitty
-- launched through `uwsm app --` was mapped briefly and then terminated.
local function launch_with_focus(command, classes)
    local workspace = hl.get_active_workspace()
    if workspace then
        local request = {
            workspace = workspace.id,
            classes = classes,
        }
        _G.__rice_pending_keylaunch_focus = request
        hl.timer(function()
            if _G.__rice_pending_keylaunch_focus == request then
                _G.__rice_pending_keylaunch_focus = nil
            end
        end, { timeout = 20000, type = "oneshot" })
    end
    hl.dispatch(hl.dsp.exec_cmd(command))
end
hl.bind(mainMod .. " + Return", function() launch_with_focus(TERMINAL, { kitty = true }) end)
hl.bind(mainMod .. " + E", function() launch_with_focus(FILE_MANAGER, { yazi = true }) end)
hl.bind(mainMod .. " + M",          hl.dsp.exec_cmd(TERMINAL .. " -e /home/zotvn/rice/bin/music"))
hl.bind(mainMod .. " + T",          hl.dsp.exec_cmd(EDITOR))
--hl.bind(mainMod .. " + C",          hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind("XF86Calculator",           hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind(mainMod .. " + W", function() launch_with_focus(launchPrefix .. BROWSER, { zen = true }) end)
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(TERMINAL .. " -e /home/zotvn/.local/bin/btop"))
hl.bind(mainMod .. " + Z",          hl.dsp.exec_cmd("/home/zotvn/rice/bin/hypr-settings"), { description = "Hyprland settings" })
hl.bind(mainMod .. " + X",          hl.dsp.exec_cmd(qsIpc .. "toggleMenu hub"))
-- Super+D = hex launcher. Workspace pin is armed only at launch time with a
-- class hint (see rice-arm-launcher-pin) — never on menu open.
hl.bind(mainMod .. " + D", function()
    hl.dispatch(hl.dsp.exec_cmd("/home/zotvn/rice/bin/hex-launcher"))
end)
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("rofi -show drun"))
-- Super+. = qs-shell emoji overlay (Emoji / Kaomoji / Fonts).
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("qs -p /home/zotvn/rice/qs-shell ipc call qsshell emoji"))
-- Super+V captures the original focused app before the overlay can move focus.
hl.bind(mainMod .. " + V", function()
    local w = hl.get_active_window()
    local address = w and tostring(w.address or "") or ""
    if not address:match("^0x[%da-fA-F]+$") then address = "" end
    hl.dispatch(hl.dsp.exec_cmd("/usr/bin/python3 /home/zotvn/rice/bin/rice-clipboard open " .. address))
end)

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio / media / brightness — qs-shell era (noctalia parked).
local mediaKeys = "/home/zotvn/rice/bin/rice-media-keys "
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(mediaKeys .. "volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(mediaKeys .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(mediaKeys .. "volume-mute"), { locked = true })
-- Some keyboards report Fn+F10/F11/F12 as the raw function key instead of
-- XF86Audio*; keep equivalent compositor bindings so controls work without QS.
hl.bind("F10", hl.dsp.exec_cmd(mediaKeys .. "volume-mute"), { locked = true })
hl.bind("F11", hl.dsp.exec_cmd(mediaKeys .. "volume-down"), { locked = true, repeating = true })
hl.bind("F12", hl.dsp.exec_cmd(mediaKeys .. "volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(mediaKeys .. "mic-mute"),    { locked = true })
-- Send Discord/Vesktop's native Voice & Video shortcuts to the app itself.
-- Num0 = Ctrl+Shift+M (mute microphone); Num1 = Ctrl+Shift+D (deafen).
local discordHotkey = "/home/zotvn/rice/bin/vesktop-hotkey "
local function bindDiscordHotkey(key, action, combo)
    local dispatcher = hl.dsp.exec_cmd(discordHotkey .. action)
    hl.bind(key, dispatcher, { locked = true, description = "Discord: " .. action .. " (" .. combo .. ")" })
end
bindDiscordHotkey("KP_0", "mic", "Ctrl+Shift+M")
bindDiscordHotkey("KP_Insert", "mic", "Ctrl+Shift+M") -- NumLock off
bindDiscordHotkey("KP_1", "deafen", "Ctrl+Shift+D")
bindDiscordHotkey("KP_End", "deafen", "Ctrl+Shift+D") -- NumLock off

hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(mediaKeys .. "media-toggle"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(mediaKeys .. "media-toggle"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(mediaKeys .. "media-next"),   { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(mediaKeys .. "media-prev"),   { locked = true })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(mediaKeys .. "brightness-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(mediaKeys .. "brightness-down"), { locked = true, repeating = true })

-------------------
---- UTILITIES ----
-------------------

-- Print = quick region select (slurp) → clipboard. No Satty, no file.
-- Super+Print = both monitors as one image, Satty editor, save under Pictures/Screenshots.
hl.bind("Print",               hl.dsp.exec_cmd("/home/zotvn/rice/bin/screenshot-clipboard.sh region"), { locked = true })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("/home/zotvn/rice/bin/screenshot-clipboard.sh edit"), { locked = true })

-- Theming and Wallpaper
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("/home/zotvn/rice/bin/hyprquickpaper"))
-- Wallpaper Engine (animated / Steam Workshop) picker
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("/home/zotvn/rice/bin/wectl pick"))

-- Clipboard handled above (qs-shell overlay). Do not also bind Noctalia clipboard.

-- Notifications
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(qsIpc .. "toggleMenu notif"))

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Focus on monitors (3/4 = phone/laptop headless when enabled)
hl.bind(mainMod .. " + 1", hl.dsp.focus({ monitor = MONITOR1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ monitor = MONITOR2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ monitor = MONITOR3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ monitor = MONITOR4 }))

-- Focus on workspace number
-- Absolute
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.focus({ workspace = i }))
end
-- Relative
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + CONTROL + " .. key, hl.dsp.focus({ workspace = "m~" .. i }))
end

-- Move to adjacent workspaces and next empty on a given monitor
-- hl.bind(mainMod .. " + CONTROL + Right",       hl.dsp.focus({ workspace = "m+1" }))
-- hl.bind(mainMod .. " + CONTROL + Left",        hl.dsp.focus({ workspace = "m-1" }))
-- hl.bind(mainMod .. " + CONTROL + Down",        hl.dsp.focus({ workspace = "emptym" }))

-- Scroll through existing workspaces & monitors
hl.bind(mainMod .. " + mouse_down",           hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + mouse_up",             hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + mouse_up",   hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m+1" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special())

---------------------------
---- HYPR SETTINGS --------
---------------------------

hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("/home/zotvn/rice/bin/hypr-settings"), { description = "Hyprland settings" })
