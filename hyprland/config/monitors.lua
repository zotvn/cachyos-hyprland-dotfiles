-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = "MONITOR1",
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })

hl.monitor({
    output    = "DP-2",          -- Монитор, который поддерживает 165 Гц
    mode      = "1920x1080@165", -- Жестко ставим 165 Гц
    position  = "0x0",           -- Делаем его ГЛАВНЫМ монитором (слева)
    scale     = 1,
    bitdepth  = 10,
    -- Keep the display in SDR; profile reloads must not re-enable HDR.
    cm        = "srgb",
})

-- Второй монитор (Dell) на 60 Гц
hl.monitor({
    output    = "HDMI-A-1",
    mode      = "1920x1080@60",  -- Максимум для этого монитора
    position  = "-1920x0",        -- Ставим его СЛЕВА от основного
    scale     = 1,
})

-- Phone / laptop as extra displays are created on demand (not always-on):
--   display-phone on|off   → Galaxy A26 2340×1080 landscape, workspaces 19–27
--   display-laptop on|off  → 1920×1080, workspaces 28–36
-- Position via display-layout. Stream: sunshine-phone / sunshine-laptop.
