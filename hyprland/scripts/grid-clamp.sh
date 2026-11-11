#!/usr/bin/env bash
# Окна с workspaces вне 1..15 вернуть в сетку (в активный стол, иначе в 8)
active=$(hyprctl activeworkspace -j | jq -r .id)
if [ "$active" -ge 1 ] 2>/dev/null && [ "$active" -le 15 ]; then
    target=$active
else
    target=8
fi
hyprctl clients -j | jq -r '.[] | select(.workspace.id > 15) | .address' |
while read -r addr; do
    hyprctl dispatch movetoworkspacesilent "$target,address:$addr" >/dev/null
done
