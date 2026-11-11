#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ ${1:-} == --help || ${1:-} == -h ]]; then
    echo 'Usage: ./install-hyprscape.sh (build and install only the bundled plugin)'
    exit 0
fi
if (($#)); then echo 'Unexpected arguments. Use --help.' >&2; exit 2; fi
if [[ $(id -u) == 0 ]]; then echo 'Run as your desktop user, without sudo.' >&2; exit 1; fi
for tool in make g++ pkg-config; do
    command -v "$tool" >/dev/null || { echo "Missing $tool. Run ./install.sh --install-deps first." >&2; exit 1; }
done
version=$(pkg-config --modversion hyprland) || {
    echo 'Matching Hyprland development headers are missing (pkg-config hyprland).' >&2
    exit 1
}
if [[ $version != 0.57.* ]]; then
    echo "This plugin port supports Hyprland 0.57.x; found headers for $version. No files installed." >&2
    exit 1
fi
make -C "$repo_dir/hyprscape" check
# Old object files must never survive a compositor upgrade.
make -C "$repo_dir/hyprscape" clean
make -C "$repo_dir/hyprscape" -j2
mkdir -p -- "$HOME/.local/lib"
if [[ -e $HOME/.local/lib/libhyprscape.so || -L $HOME/.local/lib/libhyprscape.so ]]; then
    backup_dir=$(mktemp -d "$HOME/hyprscape-backup-$(date +%Y%m%d-%H%M%S)-XXXXXX")
    cp -a -- "$HOME/.local/lib/libhyprscape.so" "$backup_dir/libhyprscape.so"
    printf 'Previous plugin saved to %s\n' "$backup_dir"
fi
plugin_tmp=$(mktemp "$HOME/.local/lib/.libhyprscape-XXXXXX")
trap 'rm -f -- "$plugin_tmp"' EXIT
install -m755 -- "$repo_dir/hyprscape/libhyprscape.so" "$plugin_tmp"
mv -f -- "$plugin_tmp" "$HOME/.local/lib/libhyprscape.so"
printf '\nHyprscape installed: %s\n' "$HOME/.local/lib/libhyprscape.so"
echo 'Restart your Hyprland session to use this build. The included keybindings use Super+G.'
echo 'First installation? Run ./install.sh to add keybindings and plugin loading to your config.'
