-- Nested Hyprland used only to exercise hyprscape. Deliberately minimal.

hl.plugin.load("@PLUGIN@")
hl.monitor({ output = "WAYLAND-1", mode = "960x540", position = "0x0", scale = 1 })
for i = 1, 9 do
    hl.workspace_rule({workspace = tostring(i), persistent = true, monitor = "WAYLAND-1", default = i == 5})
end
hl.config({plugin = {hyprscape = {grid_columns = 3, show_empty = 1, trailing_workspace = 0}}})

hl.config({
    general = {
        layout = "scrolling",
        gaps_in = 4,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = "rgba(0066ffcc)",
            inactive_border = "rgba(444444aa)",
        },
    },
    scrolling = { column_width = 0.5 },
    decoration = { rounding = 8 },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
    },
    animations = { enabled = true },
    debug = { disable_logs = false },
})

-- Same workspace animation style as the real session, so the alpha/offset compensation is
-- actually exercised rather than trivially satisfied.
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "default", style = "slidefadevert 15%" })

hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + C", hl.dsp.window.close())
hl.bind("SUPER + M", hl.dsp.exit())

hl.bind("SUPER + U", function() hl.plugin.hyprscape.toggle("all") end)
hl.bind("SUPER + L", hl.dsp.layout("focus r"))
hl.bind("SUPER + H", hl.dsp.layout("focus l"))

for i = 1, 5 do
    hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.focus({ workspace = 5 }))
    hl.exec_cmd("kitty --class hyprscape-test --title OverviewTest")
end)
