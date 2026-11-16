#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

NEW=$(realpath "$1")
OLD=$(noctalia msg wallpaper-get | tr -d "\r\n")

[ -n "$NEW" ] || exit 0
[ "$OLD" = "$NEW" ] && exit 0

echo "$NEW" > /tmp/wallfx-last.txt

if grep -Eq "^[[:space:]]*fill_mode[[:space:]]*=[[:space:]]*\"span\"" "$HOME/.local/state/noctalia/settings.toml" 2>/dev/null; then
    SPAN=true
else
    SPAN=false
fi

KIND=""
FIELD=""
LINE=""
read -r KIND FIELD LINE < <(wallfx elige "$NEW" 2>/dev/null | tail -n 1) || true

qs -p /home/pstrokaty/.config/quickshell-wallfx ipc call wallfx play "$OLD" "$NEW" "$KIND" "$FIELD" "$LINE" "$SPAN"
