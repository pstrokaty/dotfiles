-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--    output    = "",
--    mode      = "preferred",
--    position  = "auto",
--    scale     = "auto",
-- })

hl.monitor({
    output   = MONITOR1,
    mode     = "3440x1440@144",
    position = "0x0",
    scale    = 1,
    bitdepth = 10,
    vrr      = 0,
})

hl.monitor({
    output   = MONITOR2,
    mode     = "1920x1080@179.82",
    position = "3440x0",
    scale    = 1,
    bitdepth = 8,
    vrr      = 0,
})
