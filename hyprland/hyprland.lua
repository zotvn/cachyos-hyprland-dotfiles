-- CachyOS Hyprland Configuration

require("config.animations")
require("config.autostart")
require("config.colors")
require("config.decorations")
require("config.variables")
require("config.environment")
require("config.inputs")
require("config.overview")
-- windowrules before binds: Super+D arms __rice_arm_launcher_pin from windowrules.
require("config.windowrules")
require("config.binds")
require("config.misc")
require("config.monitors")
require("config.workspaces")
require("config.grid")
-- GUI overrides after everything else. pcall so a bad generated file cannot
-- break the session. ~/rice/bin/hypr-settings writes only this file.
pcall(require, "config.gui-settings")
-- Desktop themes are a separate appearance layer over the selected Config.
local desktop_theme = loadfile(os.getenv("HOME") .. "/.config/rice/themes/live/windows.lua")
if desktop_theme then desktop_theme() end

-- A config reload resets compositor values that perfctl applies at runtime.
hl.on("config.reloaded", function()
    hl.exec_cmd("/home/zotvn/rice/bin/perfctl tick")
end)
