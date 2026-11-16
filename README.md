# PstroSTATION Dotfiles & Noctalia WallFX

Personal CachyOS / Arch Linux desktop configuration built around **Hyprland** (Lua configuration via `hyprlang-lua`), **Noctalia Shell**, and a unified **Quickshell WallFX** shader transition & parallelogram wallpaper picker daemon.

## Key Components

- **Noctalia WallFX (`~/.config/quickshell-wallfx` & `~/.local/bin/wallfx`)**:
  - Unified single-process Quickshell runtime combining GLSL shader wallpaper transitions (`contagio`, `perfil`, `cristal`) with an interactive parallelogram wallpaper carousel (`SUPER + ALT + Up/Left/Right/Down`).
  - Zero-flicker IPC integration directly with Noctalia Shell (`noctalia msg wallpaper-set`) without `swww`/`awww`.
  - Managed as a resilient `systemd --user` service (`quickshell-wallfx.service`).
- **Dynamic Color Synchronization**:
  - **Kitty & Fish (`Tide v6`)**: 16-color terminal palette dynamically inherited from Noctalia themes.
  - **Spotify (`Spicetify`)**: Automated theme re-application via Pacman hook and live CSS variable injection (`noctalia.js`).
  - **Logitech G213 (`OpenRGB`)**: 5-zone keyboard lighting synchronized via dedicated `NoctaliaSync` JSON profile.
- **Local AI Developer Workflow (`Ollama` + `gemini-cli`)**:
  - Custom `Qwen` Modelfiles (`qwen-coder`, `qwen-commit`, `qwen-diag`) with `num_ctx 8192` and Fish helper functions (`aider-fx`, `gcam`, `diag`).
  - Read-only `bubblewrap` sandbox wrapper (`gemini-ro`) for safe repository auditing.
- **System Maintenance**:
  - Automated `paccache.timer`, `200M` `systemd-journald` cap, 30-day `user-tmpfiles.d` rotation for `~/.cache/wallfx/`, and Pacman post-transaction export of `pkglist-native.txt` and `pkglist-aur.txt`.

## Quick Install

    git clone https://github.com/pstrokaty/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ./install.sh

## Credits & License

- WallFX transition shaders, edge-map generator (`wallfx`), and parallelogram carousel (`WallpaperPicker.qml`) are adapted and ported from [**pocket-dots**](https://github.com/diegomalagrida/pocket-dots) by **Diego Malagrida**.
- Licensed under the **GNU General Public License v3.0** (`LICENSE`).
