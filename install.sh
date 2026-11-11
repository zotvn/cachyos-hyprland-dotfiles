#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install_deps=false
for arg in "$@"; do
    case $arg in
        --install-deps) install_deps=true ;;
        -h|--help)
            echo 'Usage: ./install.sh [--install-deps]'
            echo 'Installs Hyprscape and zotvn single-monitor keybinds into your existing Lua config.'
            echo 'Use --install-deps to install required CachyOS packages with Pacman.'
            exit 0 ;;
        *) echo "Unknown option: $arg (use --help)" >&2; exit 2 ;;
    esac
done
if [[ $(id -u) == 0 ]]; then
    echo 'Run this as your desktop user, without sudo.' >&2
    exit 1
fi
required=(python3 luac kitty rofi yazi wpctl make g++ pkg-config nvim btop playerctl brightnessctl grim slurp wl-copy hyprpicker satty gnome-calculator xdg-open)
missing=()
for tool in "${required[@]}"; do
    command -v "$tool" >/dev/null || missing+=("$tool")
done
if ((${#missing[@]})) && ! $install_deps; then
    printf 'Missing commands: %s\n' "${missing[*]}"
    if [[ -t 0 ]]; then
        read -r -p 'Install required CachyOS packages now? [y/N] ' answer
        [[ $answer == [yY] || $answer == [yY][eE][sS] ]] && install_deps=true
    fi
    if ! $install_deps; then
        echo 'Run ./install.sh --install-deps to install packages and continue.' >&2
        exit 1
    fi
fi
if $install_deps; then
    command -v pacman >/dev/null || { echo 'Automatic packages require CachyOS/Arch (pacman).' >&2; exit 1; }
    sudo pacman -Syu --needed hyprland base-devel pkgconf python lua kitty rofi yazi wireplumber neovim btop playerctl brightnessctl grim slurp wl-clipboard hyprpicker satty gnome-calculator xdg-utils
fi
for tool in "${required[@]}"; do
    command -v "$tool" >/dev/null || { echo "Still missing: $tool" >&2; exit 1; }
done
config_root=${XDG_CONFIG_HOME:-$HOME/.config}
mkdir -p -- "$config_root"
staged=$(mktemp -d "$config_root/.hypr-friend-XXXXXX")
trap '[[ -z ${staged:-} ]] || rm -rf -- "$staged"' EXIT
if [[ -e $config_root/hypr ]]; then
    cp -aL -- "$config_root/hypr/." "$staged/"
fi
python3 "$repo_dir/prepare-config.py" "$staged"
while IFS= read -r -d '' file; do luac -p "$file"; done < <(find "$staged" -name '*.lua' -print0)
bash "$repo_dir/install-hyprscape.sh"
backup_dir=$(mktemp -d "$HOME/hyprland-backup-$(date +%Y%m%d-%H%M%S)-XXXXXX")
if [[ -e $config_root/hypr || -L $config_root/hypr ]]; then
    mv -- "$config_root/hypr" "$backup_dir/previous-hypr"
fi
if ! mv -- "$staged" "$config_root/hypr"; then
    if [[ -e $backup_dir/previous-hypr || -L $backup_dir/previous-hypr ]]; then
        mv -- "$backup_dir/previous-hypr" "$config_root/hypr"
    fi
    exit 1
fi
staged=''
printf '\nInstalled! Config backup: %s\n' "$backup_dir"
echo 'Log out and choose Hyprland. Super+Enter = terminal; Super+H = apps; Super+G = overview.'
echo 'Super+Shift+arrows = navigate the 3x3 grid; Super+Ctrl+arrows = move a window.'
echo 'Rebuild just the plugin after updates: ./install-hyprscape.sh'
