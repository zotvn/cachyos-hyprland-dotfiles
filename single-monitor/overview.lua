local path = os.getenv("HOME") .. "/.local/lib/libhyprscape.so"
local file = io.open(path, "rb")
if file then
    file:close()
    hl.plugin.load(path)
    local function configure()
        local ok, overview = pcall(function() return hl.plugin.hyprscape end)
        if not ok or not overview then return end
        hl.config({ plugin = { hyprscape = {
            grid_columns = 3, show_empty = 1, trailing_workspace = 0,
            workspace_gap = 0.05, zoom = 0.3,
        } } })
    end
    configure()
    hl.on("hyprland.start", configure)
end
