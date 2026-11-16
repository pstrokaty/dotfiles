#!/usr/bin/env bash
DIR="${1:-$HOME/Obrazy/Wallpapers/UltraDual}"
OLD=$(noctalia msg wallpaper-get | tr -d "\n")
NEXT=$(find "$DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) ! -iname "*_fg.*" ! -path "$OLD" | shuf -n 1)
[ -n "$NEXT" ] && "$HOME/.config/quickshell-wallfx/set-wallpaper.sh" "$NEXT"
