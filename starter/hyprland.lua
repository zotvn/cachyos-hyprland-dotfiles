-- Portable starter, derived from zotvn's Hyprland 0.57 setup.
require("config.colors")
require("config.animations")
require("config.decorations")

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.config({
    general = { layout = "dwindle" },
    input = { kb_layout = "us", accel_profile = "flat" },
    cursor = { no_warps = true },
    dwindle = { preserve_split = true },
})

local plugin = os.getenv("HOME") .. "/.local/lib/libhyprscape.so"
local f = io.open(plugin, "rb")
if f then
    f:close()
    hl.plugin.load(plugin)
    local function configure_overview()
        local ok, overview = pcall(function() return hl.plugin.hyprscape end)
        if not ok or not overview then return end
        hl.config({ plugin = { hyprscape = {
            grid_columns = 3, show_empty = 1, trailing_workspace = 0,
            workspace_gap = 0.05, zoom = 0.3,
        } } })
    end
    configure_overview()
    hl.on("hyprland.start", configure_overview)
end

hl.bind("SUPER + G", function()
    local w = hl.get_active_window()
    hl.plugin.hyprscape.toggle(w and w.class == "gamescope" and "focused" or "cursor")
end)
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("kitty --class yazi -e yazi"))
hl.bind("SUPER + H", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind("SUPER + " .. direction, hl.dsp.focus({ direction = direction }))
end
for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true, default = i == 5 })
    hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.focus({ workspace = 5 }))
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
end)

-- One 3x3 grid, no wrapping. Extend the original grid.lua for multiple monitors.
local function target(direction)
    local ws = hl.get_active_workspace()
    if not ws or ws.id < 1 or ws.id > 9 then return nil end
    local n = ws.id - 1
    local col, row = n % 3, math.floor(n / 3)
    if direction == "left" and col > 0 then return ws.id - 1 end
    if direction == "right" and col < 2 then return ws.id + 1 end
    if direction == "up" and row > 0 then return ws.id - 3 end
    if direction == "down" and row < 2 then return ws.id + 3 end
end
for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind("SUPER + SHIFT + " .. direction, function()
        local ws = target(direction)
        if ws then hl.dispatch(hl.dsp.focus({ workspace = ws })) end
    end)
    hl.bind("SUPER + CTRL + " .. direction, function()
        local ws = target(direction)
        if ws then
            hl.dispatch(hl.dsp.window.move({ workspace = ws }))
            hl.dispatch(hl.dsp.focus({ workspace = ws }))
        end
    end)
end
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
