#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying dotfiles with GNU Stow..."
stow -v -t "$HOME" -d "$DOTFILES_DIR" .

echo "Enabling user systemd services and timers..."
systemctl --user daemon-reload
systemctl --user enable --now noctwall.service systemd-tmpfiles-clean.timer

echo "Done! Review pkglist-native.txt and pkglist-aur.txt for package dependencies."
