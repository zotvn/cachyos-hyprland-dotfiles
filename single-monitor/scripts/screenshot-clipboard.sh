#!/bin/bash
# Screenshots for Hyprland.
#   region  Print         — freeze → select anywhere → clipboard (no editor)
#   edit    Super+Print   — both monitors, Satty editor, save under Pictures/Screenshots
set -euo pipefail

# Prefer /tmp when writable; else fall back (Chromium/other apps may leave /tmp as 755).
if ! touch /tmp/.rice-shot-probe 2>/dev/null; then
  export TMPDIR="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/rice-shot-tmp"
  mkdir -p "$TMPDIR"
else
  rm -f /tmp/.rice-shot-probe
fi

pictures="${XDG_PICTURES_DIR:-}"
if [[ -z "$pictures" ]] && command -v xdg-user-dir >/dev/null; then
  pictures="$(xdg-user-dir PICTURES)"
fi
pictures="${pictures:-$HOME/Pictures}"
outdir="$pictures/Screenshots"
mkdir -p "$outdir"

mode="${1:-region}"
if [[ "$mode" == "region" || "$mode" == "focused" ]]; then
  tmp="$(mktemp --suffix=.png "${TMPDIR:-/tmp}/rice-shot-XXXXXX")"
  freeze_pid=""
  cleanup() {
    if [[ -n "${freeze_pid}" ]]; then
      kill "$freeze_pid" 2>/dev/null || true
      wait "$freeze_pid" 2>/dev/null || true
    fi
    rm -f "$tmp"
  }
  trap cleanup EXIT

  # Freeze all outputs first so notifications stay in the captured frame while
  # the user selects an area. Do not restrict this to the focused output:
  # toasts are intentionally routed to the secondary monitor.
  hyprpicker -r -z >/dev/null 2>&1 &
  freeze_pid=$!
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if kill -0 "$freeze_pid" 2>/dev/null; then
      break
    fi
    sleep 0.02
  done
  sleep 0.1

  # Select anywhere on the frozen desktop. Esc → quiet exit.
  geom="$(slurp -b '#00000066' -c '#ffffffee' -d 2>/dev/null)" || exit 0
  [[ -n "$geom" ]] || exit 0

  # grim accepts slurp's layout-space geometry and captures the selected
  # output, including the secondary display where notifications live.
  grim -g "$geom" -t png "$tmp"
  wl-copy --type image/png < "$tmp"
  exit 0
fi

tmp="$(mktemp --suffix=.png "${TMPDIR:-/tmp}/rice-shot-XXXXXX")"
cleanup() { rm -f "$tmp"; }
trap cleanup EXIT

grim -c -t png "$tmp"
satty \
  --filename "$tmp" \
  --fullscreen all \
  --floating-hack \
  --initial-tool crop \
  --copy-command "wl-copy --type image/png" \
  --output-filename "$outdir/screenshot-%Y-%m-%d_%H-%M-%S.png" \
  --actions-on-enter save-to-file \
  --actions-on-escape exit \
  --no-window-decoration \
  || true
