local workspace, window = { id = 5 }, nil
local bindings, actions, rules = {}, {}, {}
local function action(kind)
    return function(value) return { kind = kind, value = value } end
end
hl = {
    bind = function(key, value) bindings[key] = value end,
    unbind = function(key) bindings[key] = nil end,
    workspace_rule = function(rule) rules[#rules + 1] = rule end,
    get_active_workspace = function() return workspace end,
    get_active_window = function() return window end,
    get_config = function() return false end,
    curve = function() end, animation = function() end, exec_cmd = function() end,
    dispatch = function(value) actions[#actions + 1] = value end,
    plugin = {},
    dsp = {
        focus = action("focus"), exec_cmd = action("exec"), layout = action("layout"),
        cursor = { move = action("cursor") },
        workspace = { toggle_special = action("special") },
        window = {
            move = action("move"), close = action("close"),
            fullscreen_state = action("fullscreen_state"), fullscreen = action("fullscreen"),
            float = action("float"), resize = action("resize"), center = action("center"),
            drag = action("drag"), cycle_next = action("cycle"),
        },
    },
}
local function press(key)
    actions = {}
    local binding = assert(bindings[key], key)
    if type(binding) == "function" then binding() else hl.dispatch(binding) end
    return actions
end
dofile("single-monitor/grid.lua")
dofile("single-monitor/keys.lua")
assert(#rules == 9 and rules[5].default == true)
assert(press("SUPER + SHIFT + left")[1].value.workspace == 4)
local moved = press("SUPER + CTRL + down")
assert(moved[1].kind == "move" and moved[1].value.workspace == 8)
assert(moved[2].kind == "focus" and moved[2].value.workspace == 8)
workspace.id = 1
assert(#press("SUPER + SHIFT + left") == 0)
assert(#press("SUPER + CTRL + up") == 0)
assert(press("SUPER + ALT + 9")[1].value.workspace == 9)
assert(press("SUPER + SHIFT + CONTROL + 4")[1].value.workspace == 4)
window = { class = "steam_app_123", content_type = "game" }
assert(#press("SUPER + Q") == 0)
window = { class = "kitty", size = { x = 800, y = 600 }, floating = false }
assert(press("SUPER + Q")[1].kind == "close")
local floating = press("SUPER + Space")
assert(floating[2].kind == "resize" and floating[2].value.x == 640 and floating[2].value.y == 360)
local toggled
hl.plugin.hyprscape = { toggle = function(mode) toggled = mode end }
window.class = "gamescope"
press("SUPER + G")
assert(toggled == "focused")
window.class = "kitty"
press("SUPER + G")
assert(toggled == "cursor")
assert(not bindings["SUPER + SHIFT + 2"])
assert(not bindings["SUPER + KP_Add"])
print("Single-monitor keys passed: 3x3 bounds, window moves, original numeric shortcuts, game-safe close, PiP, overview mode.")
