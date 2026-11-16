-- Look and feel configuration

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 8,
        border_size = 2,
        extend_border_grab_area = 10,
        resize_on_border = true,
        col = {
            active_border = {
                colors = { CACHYLGREEN, CACHYDGREEN },
                angle = 45,
            },
            inactive_border = CACHYGRAY,
        },
    },
    group = {
        col = {
            border_active = CACHYLBLUE,
            border_inactive = CACHYGRAY,
            border_locked_active = CACHYDBLUE,
            border_locked_inactive = CACHYGRAY,
        },
        groupbar = {
            col = {
                active = CACHYLGREEN,
                inactive = CACHYGRAY,
                locked_active = CACHYDBLUE,
                locked_inactive = CACHYGRAY,
            },
        },
    },
    decoration = {
        dim_special = 0.3,
        rounding = 10,
        active_opacity = 0.95,
        inactive_opacity = 0.85,
        fullscreen_opacity = 1,
        blur = {
            size = 5,
            passes = 4,
            special = true,
        },
    },
})

hl.config({
    plugin = {
        scrolloverview = {
            gesture_distance = 300,
            scale = 0.5,
            workspace_gap = 50,
            layout = "vertical",     -- "horizontal", "vertical" lub "auto"
            wallpaper = 2,            -- 0: globalnie, 1: per-workspace, 2: oba
            wallpaper_layer = "auto",
            blur = true,
            cross_monitor_drag = true, -- Przeciąganie okien między monitorami w widoku
            shadow = {
                enabled = true,
                range = 50,
            },
        },
    },
})
