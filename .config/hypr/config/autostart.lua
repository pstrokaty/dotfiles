-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    hl.exec_cmd("bash -c 'dbus-update-activation-environment --systemd --all && systemctl --user start graphical-session.target'")
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("xhost +SI:localuser:root")
    hl.exec_cmd("bash -c 'sleep 10 && $HOME/.local/bin/g213-sync-colors'")
    hl.exec_cmd("udiskie &")
end)
