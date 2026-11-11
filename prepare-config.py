#!/usr/bin/env python3
"""Prepare the staged copy only; never edits the active config directly."""
import argparse
from pathlib import Path
import re
import shutil

MARKER = '-- BEGIN zotvn single-monitor keybindings'
END = '-- END zotvn single-monitor keybindings'


def prepare(staged, assets, default_config):
    main = staged / 'hyprland.lua'
    if (staged / 'hyprland.conf').exists():
        raise ValueError('Found hyprland.conf. This installer needs a Hyprland 0.57 Lua config. Migrate it before installing; your active files were not changed.')
    if main.exists():
        text = main.read_text()
    else:
        text = default_config.read_text()
    text = re.sub(r'\n?' + re.escape(MARKER) + r'.*?' + re.escape(END) + r'\n?', '\n', text, flags=re.DOTALL)
    destination = staged / 'friend'
    if destination.is_symlink():
        raise ValueError('The reserved hypr/friend directory is a symlink; move it aside before installing.')
    shutil.copytree(assets, destination, dirs_exist_ok=True)
    # Move conflicting default binds aside by loading ours last.
    text = text.rstrip() + '\n\n' + MARKER + '\nrequire("friend.overview")\nrequire("friend.grid")\nrequire("friend.keys")\n' + END + '\n'
    main.write_text(text)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('staged', type=Path)
    parser.add_argument('--assets', type=Path, default=Path(__file__).resolve().parent / 'single-monitor')
    parser.add_argument('--default-config', type=Path, default=Path('/usr/share/hypr/hyprland.lua'))
    args = parser.parse_args()
    try:
        prepare(args.staged, args.assets, args.default_config)
    except (ValueError, OSError) as error:
        parser.exit(1, f'{error}\n')
