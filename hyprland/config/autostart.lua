-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    -- Listener only. -w hide keeps the window closed; config still applies
    -- when the G703 reconnects.
    hl.exec_cmd("solaar -w hide")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    -- Flatpak / system auth prompts (GUI password dialog).
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    -- Static wallpaper daemon for hyprquickpaper (Super+Shift+W).
    hl.exec_cmd("sh -c 'rm -f \"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}\"/wayland-*-awww-daemon.sock; pgrep -x awww-daemon >/dev/null || awww-daemon >/dev/null 2>&1 &'")
    -- rice: noctalia parked — configs kept; restore with: hl.exec_cmd("noctalia")
    -- hl.exec_cmd("noctalia")
    hl.exec_cmd("/home/zotvn/rice/bin/qs-shell")
    hl.exec_cmd("xhost +SI:localuser:root")
    hl.exec_cmd("/home/zotvn/rice/bin/vesktop")
    hl.exec_cmd("/home/zotvn/rice/bin/steam-library-only")
    hl.exec_cmd("python3 /home/zotvn/rice/leds/ledctl.py boot")
    -- roomlightd is rice-roomlight.service (systemd --user)
    -- Hyprscape is loaded synchronously by config.overview before options/binds.
    hl.exec_cmd("python3 /home/zotvn/rice/bin/zen-hover-focus")
    -- Never start a session stuck in Peak/Beauty; also clears the WE pause flag.
    hl.exec_cmd("/home/zotvn/rice/bin/perfctl restore")
    -- Restore Wallpaper Engine scene if it was active last session.
    hl.exec_cmd("sh -c 'sleep 4 && /home/zotvn/rice/bin/wectl restore'")
    -- Keep login focused on the center cell after background apps start.
    hl.exec_cmd("sh -c 'sleep 3 && hyprctl dispatch workspace 5 && hyprctl dispatch focusmonitor DP-2'")
    -- Spotify (Spicetify) on workspace 6 (silent): nudge play so MusicViz binds MPRIS.
    hl.exec_cmd("systemctl --user start rice-spotify-lyricsd.service")
    hl.exec_cmd("sh -c 'sleep 6 && /home/zotvn/rice/bin/spotify-boot'")
    -- Hub reminders (next-boot + timed). graphical-session.target is often inactive here.
    hl.exec_cmd("systemctl --user start rice-reminders.service")
    hl.exec_cmd("systemctl --user start rice-idle.service rice-bluelight.service")
    -- graphical-session.target can be inactive; start clipboard history explicitly.
    hl.exec_cmd("systemctl --user start rice-clipboard.service")
    -- Phone link: KDE Connect daemon (notifications / files / clipboard).
    hl.exec_cmd("kdeconnectd")
    hl.exec_cmd("systemctl --user start rice-kdeconnect-notifs.service")
    -- qs-shell already suppresses toasts on the fullscreen monitor.
    -- rice-notif-monitor-route only talked to parked Noctalia. Left disabled.
    -- Sunshine only needed when using phone/laptop as extra displays; enable via
    -- systemctl --user enable --now app-dev.lizardbyte.app.Sunshine.service
end)

hl.window_rule({
    name = "vesktop-monitor",
    match = { class = "^(vesktop)$" },
    workspace = "14",
})

hl.window_rule({
    name = "steam",
    match = { class = "^(steam)$", initial_title = "^(Steam)$" },
    workspace = "2 silent",
    no_initial_focus = true,
})

hl.window_rule({
    name = "spotify",
    match = { class = "^(spotify)$" },
    workspace = "6 silent",
    no_initial_focus = true,
})

-- Keep old Yandex windows parked if still launched manually.
hl.window_rule({
    name = "yandex-music",
    match = { class = "^(YandexMusic)$" },
    workspace = "6 silent",
    no_initial_focus = true,
})
