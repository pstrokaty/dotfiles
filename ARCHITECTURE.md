# System Architecture & Hard Constraints

## Environment
- **OS / Shell:** CachyOS (Arch Linux), Fish shell (Fisher + Tide).
- **Compositor:** Hyprland (modular Lua configuration in `~/.config/hypr/config/*.lua` using `hl.*` wrappers). GUI overrides managed by HyprMod reside exclusively in `hyprland-gui.conf` — never overwrite `.lua` modules from automated tools.
- **Desktop Shell:** Noctalia v5 (native Wayland/OpenGL ES shell configured via `~/.config/noctalia/config.toml` and `~/.local/state/noctalia/settings.toml`).
- **Hardware / Display:** NVIDIA RTX 3060 (12 GB VRAM), dual monitors (`DP-2`, `DP-3`) configured with `fill_mode = "span"`.

## Strict Rules (Do NOT Violate)
1. **No `awww`:** `awww` and `awww-daemon` are completely removed. All wallpaper queries and updates MUST use Noctalia IPC:
   - Get: `noctalia msg wallpaper-get`
   - Set: `noctalia msg wallpaper-set <path>`
2. **Existing Python Venv Only:** Never create new virtual environments or use `onnxruntime-openvino`. Always use `~/.config/hypr/scripts/venv/bin/python` (configured with `rembg`, `onnxruntime-gpu` / `CUDAExecutionProvider`, `opencv-python-headless`, `numpy`, `pillow`).
3. **Isolated Quickshell Runtime:** Noctalia v5 does not run on Quickshell. Custom QML/GLSL wallpaper transitions run in a separate micro-instance at `~/.config/quickshell-wallfx/` (`WlrLayer.Bottom`).
4. **English-Only Codebase:** All code, comments, logs, and `notify-send` messages in `~/.local/bin/wallfx` and `~/.config/quickshell-wallfx/` must be in English (remove any `tr(es, en)` helpers).

## Key Paths & Components
- `~/.local/bin/wallfx` — Python generator for Dijkstra contagion maps and `birefnet-general-lite` outline masks cached in `~/.cache/wallfx/`.
- `~/.config/quickshell-wallfx/shell.qml` — Entry point (`ShellRoot`) hosting `WallpaperFx` and the ported `WallpaperPicker` carousel.
- `~/.config/quickshell-wallfx/WallpaperFx.qml` — `WlrLayer.Bottom` overlay handling `IpcHandler` (`target: "wallfx"`) and multi-monitor `spanRect` projection.
- `~/.config/quickshell-wallfx/shaders/wallfx.frag` — GLSL 440 fragment shader with `vec4 spanRect;` at the end of `std140` `buf`, compiled to `wallfx.v16.frag.qsb` via `/usr/lib/qt6/bin/qsb`.
- `~/.config/quickshell-wallfx/set-wallpaper.sh` — Orchestrates `noctalia msg wallpaper-get`, `wallfx elige`, and `qs -p ~/.config/quickshell-wallfx ipc call wallfx play ...`.

## Validation Commands
- Lua syntax: `luac -p ~/.config/hypr/config/*.lua`
- QML check: `qmllint ~/.config/quickshell-wallfx/*.qml`
- Shader compiler: `/usr/lib/qt6/bin/qsb`

## OpenRGB Synchronization Path
- **Noctalia Palette:** Changes in the Noctalia theme colors are detected by systemd.path.
- **systemd.path:** Monitors changes to `~/.config/kitty/themes/noctalia.conf`.
- **g213-sync-colors:** Reads the new colors and updates the OpenRGB profile `NoctaliaSync.json`.
- **openrgb --server:** Loads the updated profile using the OpenRGB SDK.
