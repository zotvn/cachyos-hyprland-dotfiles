hl.config({
    dwindle = {
        preserve_split = true,
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
    misc = {
        col = {
            splash = CACHYLGREEN,
        },
        -- Open new windows on the workspace you're looking at, not on a
        -- launch token that creates a workspace outside the 3x3 grids.
        initial_workspace_tracking = 0,
        middle_click_paste = false,
        enable_swallow = true,
        swallow_regex = "(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)",
        vrr = 3,
        -- Wake blanked monitors on any pointer / key activity (rice-idle DPMS).
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
    render = {
        direct_scanout = 2,
        -- HDR is user-controlled from the monitor UI; never enable it automatically.
        cm_auto_hdr = false,
    },
    xwayland = {
        force_zero_scaling = true
    },
})
