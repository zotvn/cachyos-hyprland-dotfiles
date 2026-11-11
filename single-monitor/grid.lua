-- One 3x3 grid. No fixed connector names or second-monitor rules.
for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true, default = i == 5 })
end
hl.curve("friendSlide", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
local function target(direction)
    local workspace = hl.get_active_workspace()
    if not workspace or workspace.id < 1 or workspace.id > 9 then return nil end
    local n = workspace.id - 1
    local col, row = n % 3, math.floor(n / 3)
    if direction == "left" and col > 0 then return workspace.id - 1 end
    if direction == "right" and col < 2 then return workspace.id + 1 end
    if direction == "up" and row > 0 then return workspace.id - 3 end
    if direction == "down" and row < 2 then return workspace.id + 3 end
end
local styles = { up = "top", down = "bottom", left = "left", right = "right" }
local function slide(direction)
    local enabled = hl.get_config("animations.enabled")
    if enabled == false or enabled == 0 then return end
    hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2.71, bezier = "friendSlide", style = "slidefade " .. styles[direction] })
    hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "friendSlide", style = "slidefade " .. styles[direction] })
end
for _, direction in ipairs({ "left", "right", "up", "down" }) do
    local observer = "SUPER + SHIFT + " .. direction
    local move = "SUPER + CTRL + " .. direction
    hl.unbind(observer)
    hl.unbind(move)
    hl.bind(observer, function()
        local workspace = target(direction)
        if workspace then
            slide(direction)
            hl.dispatch(hl.dsp.focus({ workspace = workspace }))
        end
    end)
    hl.bind(move, function()
        local workspace = target(direction)
        if workspace then
            slide(direction)
            hl.dispatch(hl.dsp.window.move({ workspace = workspace }))
            hl.dispatch(hl.dsp.focus({ workspace = workspace }))
        end
    end)
end
