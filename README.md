# Hyprscape + zotvn keybindings for CachyOS

A single installer for **one monitor**: build the locally patched Hyprscape plugin and add zotvn's keybindings and 3×3 workspace grid to your Hyprland Lua config.

## Install

```bash
sudo pacman -Syu --needed git
git clone https://github.com/zotvn/cachyos-hyprland-dotfiles.git
cd cachyos-hyprland-dotfiles
./install.sh --install-deps
```

Run as your desktop user, without putting `sudo` before the script. `--install-deps` runs Pacman with sudo for build tools and the apps used by the included shortcuts. Pacman shows its transaction before installing. If these packages are already installed, just run `./install.sh`.

The script:

1. Copies your existing config into a staging directory and adds a small include block to `hyprland.lua`. With no config, it starts from CachyOS's installed default Lua config.
2. Installs keybinding modules under `~/.config/hypr/friend/` (or `$XDG_CONFIG_HOME/hypr/friend/`). Your existing appearance, input and monitor settings are retained. Matching shortcuts are replaced with zotvn's bindings.
3. Clean-builds Hyprscape against your installed headers, saves any old plugin, and atomically installs `~/.local/lib/libhyprscape.so`.
4. Saves your previous config under a unique `~/hyprland-backup-…/previous-hypr` directory before activating the staged config. Plugin backups are under `~/hyprscape-backup-…/`. Both paths are printed.

Log out and select **Hyprland** to use the new plugin and bindings. There is no setup wizard or automatic desktop reload. Running the script again updates its modules without duplicating the include block.

**Requires Hyprland 0.57.x and matching development headers.** The bundled plugin refuses other series. After updating Hyprland within that series, rebuild the plugin and restart the session; old running compositors cannot use a plugin built for a newer build. If your config is still `hyprland.conf`, migrate to the 0.57 Lua config first; the installer stops before changing your active config.

## Your shortcuts

| Shortcut | Action |
| --- | --- |
| Super+G | Hyprscape overview under the pointer; Gamescope uses focused monitor |
| Super+Shift+arrows | Navigate the 3×3 grid, without wrapping |
| Super+Ctrl+arrows | Move the active window through the grid and follow it |
| Super+Alt+1…9 or Super+Ctrl+1…9 | Select workspace 1…9 |
| Super+Ctrl+Shift+1…9 | Move window to workspace 1…9 |
| Super+arrows | Focus adjacent window and move the pointer onto it |
| Alt+Tab / Super+Tab | Cycle windows |
| Super+Q | Close window, with the original game protection |
| Super+Shift+Q | Force-close the window under the pointer |
| Super+Escape | Interactive window kill |
| Super+Space | Float as centered 640×360 PiP, or tile it again |
| Super+F / Super+J | Fullscreen / toggle split |
| Super+mouse drag, left/right | Move / resize |
| Super+Enter / Super+E | Kitty / Yazi in Kitty |
| Super+T / Ctrl+Shift+Escape | Neovim in Kitty / btop in Kitty |
| Super+W | Zen if installed, otherwise system browser at DuckDuckGo |
| Super+H / Super+D | Rofi; Super+D uses Hex if separately installed |
| Super+S / Super+Shift+S | Toggle scratchpad / move window to scratchpad |
| Print / Super+Print | Region to clipboard / screenshot editor |
| Volume keys or F10/F11/F12 | Mute / lower / raise volume |
| Mic-mute, media and brightness keys | System default input/output and standard media controls |

The grid is workspaces **1–9**, with 5 as its center. Multi-monitor movement and phone-only zoom shortcuts are omitted. Volume/media controls use ordinary WirePlumber, Playerctl and brightnessctl; there are no personal Bluetooth-device or monitor-brightness integrations.

The original desktop also has separate programs behind Super+M, Super+Z/comma, Super+X, Super+period, Super+A, Super+V, wallpaper shortcuts and keypad Discord mute/deafen. These bindings are retained, but show a notice if the corresponding `~/rice/bin` tool or qs-shell is absent. This bundle installs Hyprscape and keybindings; it does not install the full settings GUI, qs-shell, Hex, music, wallpaper or streaming projects. The unmodified original bindings remain in `hyprland/config/binds.lua` for reference.

## Rebuild just Hyprscape

```bash
./install-hyprscape.sh
```

This rebuilds from clean objects and backs up/replaces the plugin without changing your config. Use the top-level script for this local port; upstream links in the preserved `hyprscape/README.md`, packaging and Nix files may fetch a different version.

## Restore

Set `backup` to the directory printed by the installer:

```bash
backup="$HOME/hyprland-backup-YYYYMMDD-HHMMSS-XXXXXX"
config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
mv -- "$config_root/hypr" "$config_root/hypr.bindings-saved-$(date +%s)"
if [ -e "$backup/previous-hypr" ] || [ -L "$backup/previous-hypr" ]; then
    mv -- "$backup/previous-hypr" "$config_root/hypr"
fi
```

After leaving the session, restore any previous plugin from its separately printed `hyprscape-backup` directory using a temporary copy plus rename. If no config or plugin existed before, there is no previous file to restore.

## Source and checks

`hyprland/` contains the original 2026-11-11 dotfile snapshot; `hyprscape/` contains full tracked plugin source with the local 0.57 port and grid/pointer/focus fixes. `starter/` preserves the earlier optional standalone starter. The installer uses `single-monitor/` and leaves those snapshots unchanged. `SOURCE-MANIFEST.json` records copied-file hashes. Generated libraries/objects, stale backups, locks and original Git history are excluded.

```bash
python3 -m unittest discover -s tests
lua tests/keybinds_spec.lua
```

Checks cover preserving existing config, repeated installation, refusing legacy config, single-monitor navigation boundaries, game-safe close, PiP and overview selection. The plugin is clean-built and the installer exercised in an isolated temporary home; the resulting Lua config is checked with `Hyprland --verify-config`. The graphical session on the friend's hardware is not tested here.

Hyprscape is based on [cybergaz/hyprscape](https://github.com/cybergaz/hyprscape), with local modifications over base commit `1ec84050efccbb04e36ea02772dd5ca37ea1bc43`. Its [BSD-3-Clause license](hyprscape/LICENSE) is preserved. No extra license is asserted for the original dotfile snapshot.
