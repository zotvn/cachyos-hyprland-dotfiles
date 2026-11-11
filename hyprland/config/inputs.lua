-- Input configuration

hl.config({
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle,caps:none", -- или grp:caps_toggle
        -- kb_options = "caps:none",
    -- kb_variant = "",
    -- kb_model = "",
        -- sensitivity = -0.25,
        accel_profile = "flat",
    },
    cursor = {
        -- Dock clicks focus a window without dragging the pointer.
        -- Super+arrows move the cursor themselves after focusing.
        no_warps = true,
        -- Soft cursors lag and blink out between monitors. Keep hardware.
        no_hardware_cursors = false,
    },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left",       action = "float" })

-- Use one cursor startup handler. The theme layer overrides the base cursor
-- only while the preset's Sandevistan effect is active.
local theme_cursor = loadfile(os.getenv("HOME") .. "/.config/rice/themes/live/cursor.lua")
if not theme_cursor or not theme_cursor() then
    pcall(require, "config.cursor-settings")
end
-- Shake cursor to find (dynamic-cursors plugin); empty unless enabled in Settings → Cursor.
pcall(require, "config.cursor-shake")

