-- ============================================================
--  СЕТКА РАБОЧИХ СТОЛОВ 3x3 (9 штук), навигация без wrap around
-- ============================================================

-- >>> НАСТРОЙКИ <<<
local GRID_MONITOR = "DP-2"      -- твой основной монитор. Проверь: `hyprctl monitors`
local GRID_COLS    = 3
local GRID_ROWS    = 3
local GRID_SIZE    = GRID_COLS * GRID_ROWS   -- 9
local CENTER_WS    = 5           -- центр сетки 3x3
local MON1_BASE = 1
local MON2_BASE = 10
local MON3_BASE = 19  -- PHONE (on-demand headless)
local MON4_BASE = 28  -- LAPTOP (on-demand headless)
local mainMod = "SUPER"
local MON2 = "HDMI-A-1"   -- твой второй монитор, проверь через `hyprctl monitors`
local MON3 = "PHONE"
local MON4 = "LAPTOP"

-- ------------------------------------------------------------
-- 1. Постоянные рабочие столы 1..9 на основном мониторе
-- ------------------------------------------------------------
for i = 1, GRID_SIZE do
    local rule = { workspace = tostring(i), persistent = true, monitor = GRID_MONITOR }
    if i == CENTER_WS then rule.default = true end
    hl.workspace_rule(rule)
end

-- При старте — в центр сетки
hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.focus({ workspace = CENTER_WS }))
end)


-- Obsolete hyprscape option removed: this plugin is not loaded.



for i = 10, 18 do
    local rule = { workspace = tostring(i), persistent = true, monitor = MON2 }
    if i == 14 then rule.default = true end   -- центр сетки 10-18
    hl.workspace_rule(rule)
end

-- PHONE (19–27) / LAPTOP (28–36) grids are NOT persistent here.
-- Always-on rules parked those workspaces on HDMI when headless outputs
-- were gone (bar spam + broke SUPER+G / hyprscape). Applied on demand by
-- rice/bin/extra-display-grids when Extra displays starts.
-- Headless outputs are created after the initial config load. display-phone
-- reloads Hyprland after creating PHONE; only then register these persistent
-- workspace rules, so empty phone workspaces are instantiated on PHONE itself.
if hl.get_monitor(MON3) then
    for i = MON3_BASE, MON3_BASE + GRID_SIZE - 1 do
        local rule = { workspace = tostring(i), persistent = true, monitor = MON3 }
        if i == 23 then rule.default = true end
        hl.workspace_rule(rule)
    end
end

if hl.get_monitor(MON4) then
    for i = MON4_BASE, MON4_BASE + GRID_SIZE - 1 do
        local rule = { workspace = tostring(i), persistent = true, monitor = MON4 }
        if i == 32 then rule.default = true end
        hl.workspace_rule(rule)
    end
end

local function gridBase(ws)
    if ws >= MON4_BASE then return MON4_BASE end
    if ws >= MON3_BASE then return MON3_BASE end
    if ws >= MON2_BASE then return MON2_BASE end
    return MON1_BASE
end

-- ------------------------------------------------------------
-- 2. Математика сетки (без wrap around)
-- ------------------------------------------------------------
local function gridTarget(ws, direction)
    local base = gridBase(ws)
    local idx = ws - base                      -- 0..8 внутри своей сетки
    if idx < 0 or idx >= GRID_SIZE then return nil end
    local col = idx % GRID_COLS
    local row = math.floor(idx / GRID_COLS)

    if direction == "right" then
        if col >= GRID_COLS - 1 then return nil end
        return base + idx + 1
    elseif direction == "left" then
        if col <= 0 then return nil end
        return base + idx - 1
    elseif direction == "up" then
        if row <= 0 then return nil end
        return base + idx - GRID_COLS
    elseif direction == "down" then
        if row >= GRID_ROWS - 1 then return nil end
        return base + idx + GRID_COLS
    end
    return nil
end

local function notifyEdge()
    hl.dispatch(hl.dsp.exec_cmd("hyprctl notify 0 2000 \"rgb(5adecd)\" \"Край сетки\""))
end

-- Анимация слайда в сторону движения
local dirAnim = { up = "top", down = "bottom", left = "left", right = "right" }
local function setSlide(direction)
    -- Peak turns animations off. Re-enabling the slide here composites both
    -- workspaces and is the GPU spike on a workspace switch.
    local anim = hl.get_config("animations:enabled")
    if anim == false or anim == 0 then
        return
    end
    local a = dirAnim[direction]
    hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 2.71, bezier = "almostLinear", style = "slidefade " .. a })
    hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "slidefade " .. a })
end

-- Сброс анимации после перехода (чтобы клики по waybar не съезжали в последнюю сторону).
-- Использует тот же скрипт, что и оригинальный grid.lua
local function resetSlide()
    hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/scripts/hl-popin.sh"))
end

-- ------------------------------------------------------------
-- 3. Движение НАБЛЮДАТЕЛЯ (фокуса) по сетке
-- ------------------------------------------------------------
local function moveObserver(direction)
    local ws = hl.get_active_workspace().id
    local target = gridTarget(ws, direction)
    if not target then notifyEdge() return end
    setSlide(direction)
    hl.dispatch(hl.dsp.focus({ workspace = target }))
    resetSlide()
end

-- ------------------------------------------------------------
-- 4. Движение ОКНА (камера следует за окном)
-- ------------------------------------------------------------
local function moveWindow(direction)
    local ws = hl.get_active_workspace().id
    local target = gridTarget(ws, direction)
    if not target then notifyEdge() return end

    -- ВАЖНО: анимацию ставим ДО переноса окна.
    -- Перенос сфокусированного окна сам переключает workspace
    -- и запускает анимацию — она должна уже быть нашей.
    setSlide(direction)
    hl.dispatch(hl.dsp.window.move({ workspace = target }))
    hl.dispatch(hl.dsp.focus({ workspace = target }))  -- страховка, если авто-переход выключен
    resetSlide()
end

-- ------------------------------------------------------------
-- 5. БИНДЫ
-- ------------------------------------------------------------
-- SUPER + CTRL + стрелки  -> двигать ОКНО (камера следует)
hl.bind(mainMod .. " + CTRL + Up",    function() moveWindow("up")    end)
hl.bind(mainMod .. " + CTRL + Down",  function() moveWindow("down")  end)
hl.bind(mainMod .. " + CTRL + Left",  function() moveWindow("left")  end)
hl.bind(mainMod .. " + CTRL + Right", function() moveWindow("right") end)

-- SUPER + SHIFT + стрелки -> двигать НАБЛЮДАТЕЛЯ (фокус)
hl.bind(mainMod .. " + SHIFT + Up",    function() moveObserver("up")    end)
hl.bind(mainMod .. " + SHIFT + Down",  function() moveObserver("down")  end)
hl.bind(mainMod .. " + SHIFT + Left",  function() moveObserver("left")  end)
hl.bind(mainMod .. " + SHIFT + Right", function() moveObserver("right") end)

