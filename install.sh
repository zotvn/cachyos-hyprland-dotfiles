#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if (( $# != 0 )); then
    echo "Usage: ./install.sh (installs the portable starter only)" >&2
    exit 2
fi
if [[ $(id -u) == 0 ]]; then
    echo "Run this as your desktop user, without sudo." >&2
    exit 1
fi
version=$(pkg-config --modversion hyprland)
if [[ $version != 0.57.* ]]; then
    echo "This local port requires Hyprland 0.57.x headers; found $version." >&2
    exit 1
fi
for tool in make g++ luac kitty rofi yazi; do
    command -v "$tool" >/dev/null || { echo "Missing command: $tool" >&2; exit 1; }
done
while IFS= read -r -d '' file; do luac -p "$file"; done < <(find "$repo_dir/starter" -name '*.lua' -print0)
make -C "$repo_dir/hyprscape" check
make -C "$repo_dir/hyprscape" -j2
config_root=${XDG_CONFIG_HOME:-$HOME/.config}
backup_dir=$(mktemp -d "$HOME/hyprland-backup-$(date +%Y%m%d-%H%M%S)-XXXXXX")
if [[ -e $config_root/hypr || -L $config_root/hypr ]]; then
    cp -a -- "$config_root/hypr" "$backup_dir/hypr"
fi
if [[ -e $HOME/.local/lib/libhyprscape.so ]]; then
    cp -a -- "$HOME/.local/lib/libhyprscape.so" "$backup_dir/libhyprscape.so"
fi
# Stage a separate directory so stale hyprland.conf files cannot win over Lua.
mkdir -p -- "$config_root" "$HOME/.local/lib"
staged=$(mktemp -d "$config_root/.hypr-starter-XXXXXX")
cp -a -- "$repo_dir/starter/." "$staged/"
if [[ -e $config_root/hypr || -L $config_root/hypr ]]; then
    mv -- "$config_root/hypr" "$backup_dir/previous-hypr"
fi
mv -- "$staged" "$config_root/hypr"
# Rename the library atomically, avoiding truncation of any mapped old library.
plugin_tmp=$(mktemp "$HOME/.local/lib/.libhyprscape-XXXXXX")
install -m755 -- "$repo_dir/hyprscape/libhyprscape.so" "$plugin_tmp"
mv -f -- "$plugin_tmp" "$HOME/.local/lib/libhyprscape.so"
printf 'Starter installed. Backup: %s\nLog out and select Hyprland to use it. No automatic session reload was performed.\n' "$backup_dir"
