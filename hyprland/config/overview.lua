-- Load before setting plugin options so startup/reload cannot race registration.
hl.plugin.load('/home/zotvn/rice/hyprscape/libhyprscape.so')
hl.config({ plugin = { hyprscape = {
    grid_columns = 3,
    show_empty = 1,
    trailing_workspace = 0,
    workspace_gap = 0.05,
    zoom = 0.3,
} } })
