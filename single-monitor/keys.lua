-- zotvn's keybindings adapted to a single-monitor 3x3 grid.
local mainMod = "SUPER"
local function bind(key, action, options)
    hl.unbind(key)
    return hl.bind(key, action, options)
end
local root = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/friend"
local function quote(value) return "'" .. value:gsub("'", "'\\''") .. "'" end
local function exec(command) return hl.dsp.exec_cmd(command) end
local function optional(program, arguments)
    local path = os.getenv("HOME") .. "/rice/bin/" .. program
    return exec("if [ -x " .. quote(path) .. " ]; then " .. quote(path) .. " " .. (arguments or "") ..
        "; else hyprctl notify 0 3500 'rgb(ffbb66)' " .. quote(program .. " needs the separate rice desktop tools") .. "; fi")
end
bind("SUPER + G", function()
    local ok, overview = pcall(function() return hl.plugin.hyprscape end)
    if not ok or not overview then
        hl.exec_cmd("hyprctl notify 0 4000 'rgb(ffbb66)' 'Run install-hyprscape.sh from the dotfiles folder, then restart Hyprland'")
        return
    end
    local w = hl.get_active_window()
    overview.toggle(w and w.class == "gamescope" and "focused" or "cursor")
end)
bind("SUPER + Escape", exec("hyprctl kill"))
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
bind(mainMod .. " + Q", function()
    local w = hl.get_active_window()
    if window_is_game(w) then
        return
    end
    hl.dispatch(hl.dsp.window.close())
end)
-- Float active window as centered 16:9 pip; press again to tile back.
-- Any floating window (incl. fullscreen float) tiles on second press — not only PiP size.
-- Lua DSP only — raw `hyprctl dispatch` is intercepted by this Hyprland build and fails.
bind(mainMod .. " + Space", function()
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

bind(mainMod .. " + Left",  function() focus_follow("left") end)
bind(mainMod .. " + Right", function() focus_follow("right") end)
bind(mainMod .. " + Up",    function() focus_follow("up") end)
bind(mainMod .. " + Down",  function() focus_follow("down") end)
bind("ALT + Tab",           hl.dsp.window.cycle_next())
bind(mainMod .. " + Tab",   hl.dsp.window.cycle_next())


bind("SUPER + F", hl.dsp.window.fullscreen())
bind("SUPER + J", hl.dsp.layout("togglesplit"))
bind("SUPER + SHIFT + Q", exec("python3 " .. quote(root .. "/scripts/hypr-kill-under-cursor")))
bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
bind("SUPER + Return", exec("kitty"))
bind("SUPER + E", exec("kitty --class yazi -e yazi"))
bind("SUPER + T", exec("kitty -e nvim"))
bind("SUPER + W", exec("if command -v zen-browser >/dev/null; then zen-browser; else xdg-open https://duckduckgo.com; fi"))
bind("CONTROL + SHIFT + Escape", exec("kitty -e btop"))
bind("XF86Calculator", exec("gnome-calculator"))
bind("SUPER + H", exec("rofi -show drun"))
-- Keep the launcher shortcut useful without the separate Hex launcher project.
bind("SUPER + D", exec("if [ -x \"$HOME/rice/bin/hex-launcher\" ]; then \"$HOME/rice/bin/hex-launcher\"; else rofi -show drun; fi"))
bind("SUPER + M", optional("music"))
bind("SUPER + Z", optional("hypr-settings"))
bind("SUPER + comma", optional("hypr-settings"))
bind("SUPER + SHIFT + W", optional("hyprquickpaper"))
bind("SUPER + CTRL + W", optional("wectl", "pick"))
for _, pair in ipairs({ { "SUPER + X", "toggleMenu hub" }, { "SUPER + period", "emoji" }, { "SUPER + A", "toggleMenu notif" } }) do
    local command = "if command -v qs >/dev/null && [ -f \"$HOME/rice/qs-shell/shell.qml\" ]; then qs -p \"$HOME/rice/qs-shell\" ipc call qsshell " .. pair[2] ..
        "; else hyprctl notify 0 3500 'rgb(ffbb66)' 'This shortcut needs the separate qs-shell desktop'; fi"
    bind(pair[1], exec(command))
end
bind("SUPER + V", optional("rice-clipboard", "open"))
for _, key in ipairs({ "KP_0", "KP_Insert" }) do bind(key, optional("vesktop-hotkey", "mic"), { locked = true }) end
for _, key in ipairs({ "KP_1", "KP_End" }) do bind(key, optional("vesktop-hotkey", "deafen"), { locked = true }) end
for i = 1, 9 do
    bind("SUPER + ALT + " .. i, hl.dsp.focus({ workspace = i }))
    bind("SUPER + CONTROL + " .. i, hl.dsp.focus({ workspace = i }))
    bind("SUPER + SHIFT + CONTROL + " .. i, hl.dsp.window.move({ workspace = i }))
end
for _, modifier in ipairs({ "", "CONTROL + " }) do
    bind("SUPER + " .. modifier .. "mouse_up", hl.dsp.focus({ workspace = "m+1" }))
    bind("SUPER + " .. modifier .. "mouse_down", hl.dsp.focus({ workspace = "m-1" }))
end
bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))
bind("SUPER + S", hl.dsp.workspace.toggle_special())
local volume_up = exec("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+; wpctl set-mute @DEFAULT_AUDIO_SINK@ 0")
local volume_down = exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
local mute = exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
for _, key in ipairs({ "XF86AudioRaiseVolume", "F12" }) do bind(key, volume_up, { locked = true, repeating = true }) end
for _, key in ipairs({ "XF86AudioLowerVolume", "F11" }) do bind(key, volume_down, { locked = true, repeating = true }) end
for _, key in ipairs({ "XF86AudioMute", "F10" }) do bind(key, mute, { locked = true }) end
bind("XF86AudioMicMute", exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
bind("XF86AudioPlay", exec("playerctl play-pause"), { locked = true })
bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
bind("XF86AudioNext", exec("playerctl next"), { locked = true })
bind("XF86AudioPrev", exec("playerctl previous"), { locked = true })
bind("XF86MonBrightnessUp", exec("brightnessctl set 5%+"), { locked = true, repeating = true })
bind("XF86MonBrightnessDown", exec("brightnessctl set 5%-"), { locked = true, repeating = true })
bind("Print", exec("bash " .. quote(root .. "/scripts/screenshot-clipboard.sh") .. " region"), { locked = true })
bind("SUPER + Print", exec("bash " .. quote(root .. "/scripts/screenshot-clipboard.sh") .. " edit"), { locked = true })
