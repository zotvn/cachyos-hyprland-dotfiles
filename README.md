# CachyOS: zotvn's Hyprland dotfiles + custom Hyprscape

Private sharing snapshot, **2026-11-11**. Includes the current local Hyprscape changes, including the Hyprland 0.57 port, grid overview, pointer handling and focus fixes. Those changes were uncommitted in the original working tree when this bundle was made.

## What's here

| Path | Contents |
| --- | --- |
| `hyprland/` | Exact active Hyprland configuration: main Lua file, every current Lua module, scripts, monitor/overview/performance profiles, rice Config JSON files, portal config |
| `hyprscape/` | Full tracked plugin source with local modifications, license, assets, build files, packaging and nested test config |
| `starter/` | Portable starter using the original colors, decorations and animations, a single 3×3 workspace grid, Super+G overview and ordinary app/media bindings |
| `install.sh` | Builds the plugin and installs only the portable starter, preserving the previous config and plugin in a dated backup |
| `SOURCE-MANIFEST.json` | SHA-256 hashes of copied source/config files and source version identifiers |

Compiled libraries, object files, Git history, editor backups, old config backups and transient lock files are excluded. Build the plugin on the target computer: Hyprland plugins must match the compositor build exactly.

## Getting the files

The repository is private. The owner must invite your GitHub account at **Settings → Collaborators → Add people**. After accepting, authenticate GitHub CLI and clone:

```bash
gh auth login
gh repo clone zotvn/cachyos-hyprland-dotfiles
cd cachyos-hyprland-dotfiles
```

Alternatively use GitHub's **Code → Download ZIP** after accepting the invite. The owner can also send the provided ZIP directly, which does not require GitHub access.

## Install the starter on CachyOS

This snapshot targets **Hyprland 0.57.x with Lua configs**. It was built on `hyprland 0.57.0-1.1` (compositor commit `0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`). A different release series needs a plugin port and may need config changes. The installer checks the header version before writing configs. Do not bypass the version check.

Install the build tools and starter applications using your normal CachyOS package workflow. For the matching package set:

```bash
sudo pacman -Syu --needed hyprland base-devel pkgconf lua git kitty rofi yazi wireplumber hyprpolkitagent xdg-desktop-portal-hyprland
pkg-config --modversion hyprland
./install.sh
```

Run `install.sh` as your normal desktop user, **without sudo**. Hyprland development headers and their pkg-config dependencies must be installed and match the compositor you will run. The installer builds before writing anything into your configuration, backs up an existing `~/.config/hypr` (or `$XDG_CONFIG_HOME/hypr`) and `~/.local/lib/libhyprscape.so`, and prints the backup location. It does not install packages, reload a running session, or manage network/VPN settings.

Log out and choose **Hyprland** in your login screen. A fresh starter has no bar, wallpaper manager, notification daemon or settings GUI. The initial keyboard layout is US; change `input.kb_layout` to `"us,ru"` and add `kb_options = "grp:alt_shift_toggle,caps:none"` if wanted. All monitors get preferred mode and automatic positioning; the nine starter workspaces form one grid shared by the session. Per-monitor grids are in the original snapshot for adaptation.

### Starter shortcuts

| Shortcut | Action |
| --- | --- |
| Super+Enter | Kitty terminal |
| Super+H | Rofi application launcher |
| Super+E | Yazi in Kitty |
| Super+G | Hyprscape overview on the cursor's monitor (Gamescope uses focused monitor) |
| Super+Q / Super+F / Super+Space | Close / fullscreen / float |
| Super+arrow | Focus adjacent window |
| Super+Shift+arrow | Navigate the 3×3 workspace grid, without wrapping |
| Super+Ctrl+arrow | Move window through the grid |
| Super+1…9 / Super+Shift+1…9 | Select workspace / move window |
| Super+left/right mouse drag | Move / resize window |
| Volume and microphone keys | WirePlumber audio controls |

### Restore the previous configuration

Use the exact backup directory printed by the installer. From a terminal or TTY, set `backup` to that directory and run:

```bash
backup="$HOME/hyprland-backup-YYYYMMDD-HHMMSS-XXXXXX"
config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
mv -- "$config_root/hypr" "$config_root/hypr.starter-saved-$(date +%s)"
if [ -e "$backup/previous-hypr" ] || [ -L "$backup/previous-hypr" ]; then
    cp -a -- "$backup/previous-hypr" "$config_root/hypr"
fi
# If a previous plugin was saved, restore it by atomic rename:
if [ -f "$backup/libhyprscape.so" ]; then
    cp -- "$backup/libhyprscape.so" "$HOME/.local/lib/libhyprscape.so.restore"
    mv -f -- "$HOME/.local/lib/libhyprscape.so.restore" "$HOME/.local/lib/libhyprscape.so"
fi
```

Then log out and back in. If there was no previous plugin, the newly installed library can be removed after leaving the session.

## Using the full original configuration

`hyprland/` is a faithful configuration snapshot, so it preserves the original absolute paths, app choices and hardware settings. It is intended for review and adaptation; `install.sh` deliberately installs the starter.

Before using the full snapshot:

1. Replace `/home/zotvn` throughout the copied config with your own home path. Build the bundled source into `~/rice/hyprscape` if keeping the original overview path, or change `config/overview.lua` to your plugin location.
2. Adapt `config/variables.lua`, `monitors.lua`, `workspaces.lua`, `grid.lua`, `windowrules.lua`, plus monitor profile JSON. The original setup uses DP-2, HDMI-A-1, optional PHONE/LAPTOP outputs and workspace grids 1–9 / 10–18 / 19–27 / 28–36.
3. Review `config/environment.lua`: the original enables NVIDIA-related variables, which should suit your own GPU before use. The keyboard layout is US/Russian.
4. Review `config/autostart.lua`, `binds.lua`, `cursor-shake.lua` and the reload handler in `hyprland.lua`. The custom `~/rice/bin` programs, qs-shell, Hex launcher, wallpapers, LED services, streaming displays, cursor plugin, browser wrappers and separate theme files are outside the requested Hyprland/Hyprscape bundle. Their bindings and autostarts need those projects or your replacements. A complete visual desktop clone requires those additional components.
5. `grid.lua` refers to `~/.config/hypr/scripts/hl-popin.sh`, which is already absent on the source machine. Remove that call or supply your own animation reset script. The included `grid-clamp.sh` is a legacy helper and uses an older workspace range; it is not used by the starter.

## Rebuilding Hyprscape

After any Hyprland update within the supported series, rebuild against the matching headers and start a new session:

```bash
make -C hyprscape clean
make -C hyprscape -j2
plugin_tmp=$(mktemp "$HOME/.local/lib/.libhyprscape-XXXXXX")
install -m755 hyprscape/libhyprscape.so "$plugin_tmp"
mv -f "$plugin_tmp" "$HOME/.local/lib/libhyprscape.so"
```

The top-level instructions here describe this local 0.57 port. Some compatibility tables and upstream installation links in `hyprscape/README.md`, packaging and Nix files still describe upstream 0.56 or fetch upstream source. Use the **bundled Makefile and source** for this snapshot; upstream `hyprpm add` commands do not install these local fixes.

## Provenance and license

Validation performed on the source machine: clean plugin build against installed 0.57.0 headers; all Lua/JSON/shell syntax; copied-file SHA-256 checks; installer exercised in an isolated temporary home with existing config and plugin backup sentinels; starter accepted by `Hyprland --verify-config` both with and without a built plugin present. A graphical session using the starter has not been launched. The starter applies overview settings only after the plugin is registered, avoiding first-pass unknown-plugin-key errors.

Hyprscape is based on [cybergaz/hyprscape](https://github.com/cybergaz/hyprscape), with zotvn's local modifications over base commit `1ec84050efccbb04e36ea02772dd5ca37ea1bc43`. Its BSD-3-Clause license is preserved at [`hyprscape/LICENSE`](hyprscape/LICENSE). The current dotfiles and selected config JSON files are included as a configuration snapshot; no extra license is asserted for them.
