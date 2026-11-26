#!/usr/bin/env bash
# Infinite Desktop's Lua config, with a fake Hyprland (tests/rice-infinite.lua): the two screen modes, a new window on
# the second screen and turning it off. Needs lua (Arch: lua; Debian: lua5.4); skipped when it is not there.
set -Euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v lua >/dev/null || { echo "lua is not installed: skipped"; exit 0; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
HOME="$tmp" XDG_RUNTIME_DIR="$tmp" lua "$root/tests/rice-infinite.lua" "$root/lua/rice-infinite.lua"
# and as 0.56+: the pointer itself (no input group) and the warp at the edge of the screen
HOME="$tmp" XDG_RUNTIME_DIR="$tmp" RI_TEST_POLL=1 lua "$root/tests/rice-infinite.lua" "$root/lua/rice-infinite.lua"
# rice-infinite daemon: 0.56+ (the marker) only the push at the edge, 0.55 (no marker) the whole mouse
mkdir -p "$tmp/.local/bin"
printf '#!/bin/sh\nprintf "%%s" "$*" > "$HOME/args"\n' > "$tmp/.local/bin/rice-canvasd"
chmod +x "$tmp/.local/bin/rice-canvasd"
try_daemon() {  # $@: the words after rice-infinite
  rm -f "$tmp/args"
  HOME="$tmp" XDG_RUNTIME_DIR="$tmp" HYPRLAND_INSTANCE_SIGNATURE=sig "$root/bin/rice-infinite" "$@" >/dev/null 2>&1 || true
  for _ in $(seq 50); do [ -f "$tmp/args" ] && break; sleep 0.02; done
  cat "$tmp/args" 2>/dev/null
}
printf sig > "$tmp/rice-infinite.poll"
[ "$(try_daemon daemon)" = "--push-only" ] && echo "ok - 0.56+: the daemon only pushes at the edge" \
  || { echo "not ok - 0.56+: the daemon only pushes at the edge"; exit 1; }
[ -z "$(try_daemon daemon full)" ] && echo "ok - full asks for the whole mouse too" \
  || { echo "not ok - full asks for the whole mouse too"; exit 1; }
rm -f "$tmp/rice-infinite.poll"
[ -z "$(try_daemon daemon)" ] && echo "ok - 0.55: the daemon moves the canvas itself" \
  || { echo "not ok - 0.55: the daemon moves the canvas itself"; exit 1; }
