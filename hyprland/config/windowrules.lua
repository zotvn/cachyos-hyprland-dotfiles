-- Window rules wiki https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Let applications position transient menus. Centering every floating window
-- also centered Steam/Electron dropdowns; explicit dialog rules below suffice.

-- Picture-in-Picture
hl.window_rule({
    match             = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float             = true,
    keep_aspect_ratio = true,
    size              = { "max(monitor_w, monitor_h)*0.25", "min(monitor_w, monitor_h)*0.25" },
    pin               = true,
})



-- Gaming
local gamingApps = "^(steam_app.*|gamescope)$"

-- Games open on the current workspace; only the Steam client is pinned to 2.
hl.window_rule({ match = { xdg_tag = "^(.*game.*)$" }, fullscreen_state = 2, content = "game", sync_fullscreen = true })
hl.window_rule({ match = { class = "^(steam)$", initial_title = "^(Steam)$" }, workspace = "2 silent", no_initial_focus = true })
hl.window_rule({ match = { class = "^(steam)$", title = "^(Launching\\.{3})$" }, float = true, center = true })
hl.window_rule({
    match = {
        class         = gamingApps,
        title         = "^(.+)$",
        initial_title = "negative:^(.*\\\\home\\\\.*)$",
    },
    content          = "game",
    decorate         = false,
    fullscreen_state = 2,
    size             = { "monitor_w", "monitor_h" },
    sync_fullscreen  = true,
})
hl.window_rule({
    match = {
        class         = "^(steam_app.*)$",
        initial_title = "^$",
    },
    center           = true,
    float            = true,
    fullscreen       = false,
    fullscreen_state = 0,
})

-- Steam games (and anything else) sometimes map onto a workspace id past
-- the 3x3 grids. Put those on the workspace that is actually on screen.
local function workspace_in_grid(id)
    -- DP-2: 1-9, HDMI: 10-18, PHONE: 19-27, LAPTOP: 28-36
    return type(id) == "number"
        and ((id >= 1 and id <= 9)
            or (id >= 10 and id <= 18)
            or (id >= 19 and id <= 27)
            or (id >= 28 and id <= 36))
end

local function window_class(w)
    return string.lower(tostring(w.class or w.initial_class or ""))
end

local function leave_on_its_workspace(w)
    local class = window_class(w)
    if class == "vesktop" or class == "discord" then
        return true
    end
    if class == "steam" then
        local title = tostring(w.initial_title or w.title or "")
        if title == "Steam" then
            return true
        end
    end
    return false
end

local function window_is_spawned_game(w)
    if w.content_type == "game" then
        return true
    end
    local class = window_class(w)
    return class:match("^steam_app") or class:match("gamescope") or class:match("%.exe$") ~= nil
end

local function active_grid_workspace()
    local active = hl.get_active_workspace()
    if active and workspace_in_grid(active.id) then
        return active.id
    end
    local last = hl.get_last_workspace()
    if last and workspace_in_grid(last.id) then
        return last.id
    end
    local mon = hl.get_active_monitor()
    if mon then
        if mon.name == "HDMI-A-1" then return 14 end
        if mon.name == "PHONE" then return 23 end
        if mon.name == "LAPTOP" then return 32 end
    end
    return 5
end

-- Hex launcher pin: ONE class-hinted parking slot, Lua-only (no Hyprland
-- workspace rule). Keybinds / overlays must never be redirected.
-- Arm via: rice-arm-launcher-pin <workspace> <class>
-- That calls hyprctl eval __rice_arm_launcher_pin. No file poller.
local LAUNCHER_PIN_TTL_MS = 20000

local function normalize_class_hint(hint)
    if hint == nil then
        return ""
    end
    return string.lower(tostring(hint)):gsub("%.desktop$", ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function class_matches_hint(class, hint)
    if not hint or hint == "" or class == "" then
        return false
    end
    if class == hint then
        return true
    end
    if class:find(hint, 1, true) or hint:find(class, 1, true) then
        return true
    end
    local compact = hint:gsub("%-browser$", ""):gsub("%-bin$", ""):gsub("^org%.", "")
    return compact ~= "" and (class:find(compact, 1, true) or compact:find(class, 1, true)) ~= nil
end

local function clear_any_legacy_pin_rule()
    -- Neutralize any leftover rice-launcher-pin rule from older sessions.
    hl.window_rule({
        name = "rice-launcher-pin",
        match = { class = "^__rice_launcher_pin_disarmed__$" },
    })
end

local function clear_silent_launcher_rule()
    hl.window_rule({
        name = "rice-launcher-pin-silent",
        match = { class = "^__rice_launcher_pin_disarmed__$" },
    })
end

local function install_silent_launcher_rule(workspace_id, class)
    -- window.open_early fires before static rules are evaluated. Match the
    -- actual class, not a fuzzy desktop hint, so unrelated launches stay put.
    local regex_special = { ["\\"] = true, ["."] = true, ["^"] = true,
        ["$"] = true, ["|"] = true, ["?"] = true, ["*"] = true,
        ["+"] = true, ["("] = true, [")"] = true, ["["] = true,
        ["]"] = true, ["{"] = true, ["}"] = true }
    local exact_class = class:gsub(".", function(ch)
        return regex_special[ch] and ("\\" .. ch) or ch
    end)
    hl.window_rule({
        name = "rice-launcher-pin-silent",
        match = { class = "^" .. exact_class .. "$" },
        workspace = tostring(workspace_id) .. " silent",
        no_initial_focus = true,
    })
end

local function disarm_launcher_pin()
    _G.__rice_launcher_pin = nil
    _G.__rice_launcher_pending_park = nil
    clear_any_legacy_pin_rule()
    clear_silent_launcher_rule()
    os.remove((os.getenv("HOME") or "/home/zotvn") .. "/.local/state/rice/launcher-workspace-v2.json")
end

local function arm_launcher_pin(workspace_id, class_hint)
    local hint = normalize_class_hint(class_hint)
    -- Class is mandatory — unclassed pins were stealing Super+Return / Super+W / etc.
    if type(workspace_id) ~= "number" or not workspace_in_grid(workspace_id) or hint == "" then
        return
    end
    clear_any_legacy_pin_rule()
    clear_silent_launcher_rule()
    _G.__rice_launcher_pending_park = nil
    local pin = {
        workspace = workspace_id,
        class = hint,
        expires = os.time() + math.floor(LAUNCHER_PIN_TTL_MS / 1000),
    }
    _G.__rice_launcher_pin = pin
    hl.timer(function()
        local cur = _G.__rice_launcher_pin
        if cur == pin then
            _G.__rice_launcher_pin = nil
        end
        local pending = _G.__rice_launcher_pending_park
        if pending and pending.pin == pin then
            _G.__rice_launcher_pending_park = nil
            clear_silent_launcher_rule()
        end
    end, { timeout = LAUNCHER_PIN_TTL_MS, type = "oneshot" })
end

local function consume_launcher_pin(w)
    local pin = _G.__rice_launcher_pin
    if type(pin) ~= "table" then
        return false
    end
    if pin.expires and pin.expires < os.time() then
        _G.__rice_launcher_pin = nil
        return false
    end
    if type(w) ~= "userdata" or leave_on_its_workspace(w) or window_is_spawned_game(w) then
        return false
    end
    local class = window_class(w)
    if class == "" or not class_matches_hint(class, pin.class) then
        return false
    end
    _G.__rice_launcher_pin = nil
    install_silent_launcher_rule(pin.workspace, tostring(w.class or w.initial_class or class))
    _G.__rice_launcher_pending_park = {
        pin = pin,
        address = tostring(w.address or ""),
        workspace = pin.workspace,
    }
    return true
end

local function finalize_launcher_pin(w)
    local pending = _G.__rice_launcher_pending_park
    if not pending or type(w) ~= "userdata" or tostring(w.address or "") ~= pending.address then
        return false
    end
    _G.__rice_launcher_pending_park = nil
    clear_silent_launcher_rule()
    local ws = w.workspace
    if not ws or ws.id ~= pending.workspace then
        -- Fallback for a class that changed between open_early and open.
        hl.dispatch(hl.dsp.window.move({ window = w, workspace = pending.workspace, follow = false }))
    end
    return true
end

_G.__rice_arm_launcher_pin = arm_launcher_pin
_G.__rice_disarm_launcher_pin = disarm_launcher_pin
_G.__rice_consume_launcher_pin = consume_launcher_pin

-- Always clear legacy catch-all rule on load.
clear_any_legacy_pin_rule()
disarm_launcher_pin()

-- Pin requests arrive via `hyprctl eval` from rice-arm-launcher-pin.
-- Do not poll the request file: a 150ms timer ran for the whole session.

-- Keep games on the workspace where they were launched. Only repair a game
-- that Hyprland placed outside the configured 1–36 grid, and do so silently.
-- Moving/focusing every game whose workspace differs from the current one made
-- late-mapping games steal focus after the user had already switched away.
_G.__rice_place_spawn_on_active = function(w)
    if finalize_launcher_pin(w) then
        return true
    end
    if type(_G.__rice_consume_launcher_pin) == "function" and _G.__rice_consume_launcher_pin(w) then
        return true
    end
    if type(w) ~= "userdata" or leave_on_its_workspace(w) then
        return false
    end
    if not window_is_spawned_game(w) then
        return false
    end
    local ws = w.workspace
    local id = ws and ws.id
    if workspace_in_grid(id) then
        return false
    end
    local target = active_grid_workspace()
    hl.dispatch(hl.dsp.window.move({ window = w, workspace = target, follow = false }))
    return true
end

-- A small set of explicit keybind launches may take focus, but only if the
-- user is still on the workspace where they pressed the key. All other new
-- windows stay covered by the global no_initial_focus rule below.
_G.__rice_keylaunch_focus = function(w)
    local request = _G.__rice_pending_keylaunch_focus
    if not request or type(w) ~= "userdata" then return false end
    local class = window_class(w)
    if not request.classes[class] then return false end
    _G.__rice_pending_keylaunch_focus = nil
    local active = hl.get_active_workspace()
    local ws = w.workspace
    if not active or not ws or active.id ~= request.workspace or ws.id ~= request.workspace then
        return false
    end
    hl.dispatch(hl.dsp.focus({ window = w }))
    return true
end

if not _G.__rice_spawn_on_active then
    _G.__rice_spawn_on_active = true
    hl.on("window.open_early", function(w)
        if type(_G.__rice_consume_launcher_pin) == "function" then
            _G.__rice_consume_launcher_pin(w)
        end
    end)
    hl.on("window.open", function(w)
        if type(_G.__rice_keylaunch_focus) == "function" then
            _G.__rice_keylaunch_focus(w)
        end
        if type(_G.__rice_place_spawn_on_active) == "function" then
            _G.__rice_place_spawn_on_active(w)
        end
    end)
end


-- Apps
hl.window_rule({ match = { class = "^(.*\\.exe)$", float = true }, monitor = PRIMARY_MONITOR, center = true, fullscreen_state = 0 })
hl.window_rule({ match = { class = "^(.*[Ll]auncher.*)$" }, float = true, monitor = PRIMARY_MONITOR })
hl.window_rule({ match = { class = "^(vesktop|discord)$" }, monitor = PRIMARY_MONITOR, no_initial_focus = true })
-- New windows do not steal focus unless a matching keybind launch explicitly
-- requests it and the user remains on the launch workspace.
hl.window_rule({ match = { class = ".*" }, no_initial_focus = true })
-- DaVinci Resolve: Project Manager stays a centered float; main UI fills the monitor
-- (global suppress_event=maximize blocks maximize=true).
hl.window_rule({
    match = { class = "^(resolve)$", title = "^(Project Manager|resolve)$" },
    float = true,
    center = true,
})
hl.window_rule({
    match = { class = "^(resolve)$", title = "negative:^(Project Manager|resolve)$" },
    float = false,
    size = { "monitor_w", "monitor_h" },
})
hl.window_rule({ match = { class = "^(.*[Cc]alc.*)$" }, float = true, size = { "max(monitor_w, monitor_h)*0.17", "min(monitor_w, monitor_h)*0.43" } })
hl.window_rule({ match = { class = "^(org\\.kde\\.keditfiletype)$" }, float = true })
hl.window_rule({ match = { class = "^(org\\.kde\\.ark)$" }, size = { "max(monitor_w, monitor_h)*0.40", "min(monitor_w, monitor_h)*0.40" } })
hl.window_rule({ match = { class = "^(.*satty.*)$", title = "^(Satty)$" }, min_size = { "max(monitor_w, monitor_h)*0.35", "min(monitor_w, monitor_h)*0.35" }, float = true })
hl.window_rule({ match = { class = "^(dev\\.)?(noctalia\\.Noctalia(\\.Settings)?)$" }, float = true, size = { "monitor_w*0.70", "monitor_h*0.70" } })
hl.window_rule({
    match = {
        class = "^(org\\.kde\\.dolphin)$",
        title = "negative:^(Moving.*|Create New.*|Extract.*|Compress.*|Copying.*|Progress.*|Configure.*|Properties.*|Choose\\sApplication.*)$",
    },
    float = true,
    size = { "max(monitor_w, monitor_h)*0.50", "min(monitor_w, monitor_h)*0.55" },
    move = {
        "max(20, min(cursor_x - (window_w*0.50), monitor_w - window_w + 20))", -- X axis clamping
        "max(20, min(cursor_y - 50, monitor_h - window_h + 20))" -- Y axis clamping
    },
})

-- Opacity Overrides
local terminals = "^(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)$"

-- Zen needs compositor opacity just under 1 so Hyprland applies blur to
-- Transparent Zen's client-side alpha. A 1.0 override marks the window opaque
-- and kills that effect. 0.99999 is visually identical to 1.0.
-- Zen can map after the user has left the launching workspace. Keep that
-- delayed window from pulling focus back across workspaces.
hl.window_rule({ match = { class = "^(zen)$" }, opacity = "0.99999 override", no_initial_focus = true })
hl.window_rule({ match = { class = terminals }, opacity = "1.0 override" }) -- Override opacity in favor of terminal settings for opacity. If your terminal doesn't support transparency, you can remove this rule.
hl.window_rule({ match = { class = "^(mpv|org.kde.haruna|.*plex.*|org\\.kde\\.gwenview|.*vlc.*)$" }, opacity = "1.0 override" })

-- Settings opens as a centered floating window; its own pages handle scrolling.
hl.window_rule({
    match = { class = "^(rice\\.hypr\\.settings)$" },
    float = true,
    center = true,
    size = { "monitor_w*0.76", "monitor_h*0.78" },
})

-- JARVIS window pet (tiny hologram perched on focused window)
hl.window_rule({
    match = { class = "^(rice\\.jarvis\\.buddy)$" },
    float = true,
    center = false,
    size = { "88", "96" },
    opacity = "1.0 override",
})

-- Codex's transparent full-screen cloud-pet overlay was picking up the global
-- compositor blur and blurring the whole desktop behind the small pet.
-- Keep the app's own CSS effects, but disable Hyprland blur/shadow for its windows.
hl.window_rule({
    name = "chatgpt-codex-no-desktop-blur",
    match = { class = "^(Chatgpt|ChatGPT|chatgpt|Codex|codex)$" },
    no_blur = true,
    no_shadow = true,
})

-- JARVIS voice/chat popups from noctalia bar
hl.window_rule({
    match = { class = "^(jarvis-voice|jarvis-chat)$" },
    float = true,
    center = true,
    size = { "max(520, monitor_w*0.32)", "max(360, monitor_h*0.38)" },
})

-- Float Utility Windows
local floatApps = {
    { class = "^(kvantummanager|qt[56]ct|nwg-look)$" },
    { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-applet|nm-connection-editor)$" },
    { title = "^(Winetricks.*|Protontricks.*)$" },
}
for _, m in ipairs(floatApps) do hl.window_rule({ match = m, float = true }) end

-- Float Common Modals
local modalMatches = {
    { title = "^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress)$" },
    { initial_title = "^(Open File)$" },
    { class = "^([Xx]dg-desktop-portal-gtk)$" },
    { title = "^(File Upload|Choose wallpaper|Library)(.*)$" },
    { class = "^(.*dialog.*)$" },
    { title = "^(.*dialog.*)$" },
    { class = "^(hyprland-share-picker)$"},
}
for _, m in ipairs(modalMatches) do hl.window_rule({ match = m, float = true }) end

-- Ignore maximize requests from all apps. You'll probably like this.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

---------------------------
---- HEX LAUNCHER ---------
---------------------------

-- Blur is safe because shell.qml now unmaps the layer immediately on close
-- instead of keeping the resident surface mapped through its outro.
hl.layer_rule({
    name = "hex-launcher-blur",
    match = { namespace = "^hex-launcher$" },
    blur = true,
    ignore_alpha = 0.55,
})

-- qs-shell top bars (glass/HUD variants rely on layer blur)
hl.layer_rule({
    name = "qs-shell-blur",
    match = { namespace = "^qs-shell$" },
    blur = true,
    ignore_alpha = 0.45,
})

-- Let Hyprland handle desktop shortcuts while nested Gamescope has focus.
hl.window_rule({ name = "gamescope-desktop-shortcuts", match = { class = "^gamescope$" }, no_shortcuts_inhibit = true })
