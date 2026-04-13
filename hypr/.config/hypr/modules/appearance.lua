-- General & decoration
hl.config({
    general = {
        gaps_in          = 4,
        gaps_out         = 8,
        border_size      = 2,
        col              = {
            active_border   = { colors = { "rgb(F604F8)", "rgb(2F0065)", angle = 45 } },
            inactive_border = { colors = { "rgb(303030)", "rgb(B4BEFE)", angle = 35 } },
        },
        layout           = "dwindle",
        resize_on_border = false,
        resize_corner    = 3,
    },
    decoration = {
        rounding              = 12,
        rounding_power        = 2,
        active_opacity        = 1.0,
        inactive_opacity      = 0.9,
        border_part_of_window = true,
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },
        blur = {
            enabled           = true,
            size              = 16,
            passes            = 2,
            ignore_opacity    = true,
            new_optimizations = true,
            xray              = false,
            noise             = 0.0117,
            contrast          = 0.8916,
            brightness        = 0.8172,
            vibrancy          = 0.1696,
            popups            = false,
        },
    },
    animations = { enabled = true },
    dwindle = { pseudotile = true, preserve_split = true },
    master  = { new_status = "master" },
    misc    = { force_default_wallpaper = 0, disable_hyprland_logo = true },
})

-- Bezier curves
hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 }    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 }    } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 }       } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 }    } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 }     } })

-- Animations
hl.animation({ leaf = "global",         enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",         enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",        enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",      enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",     enabled = true, speed = 1.49, bezier = "linear",        style = "popin 87%" })
hl.animation({ leaf = "fadeIn",         enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",        enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",           enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",         enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",       enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",      enabled = true, speed = 1.5,  bezier = "linear",        style = "fade" })
hl.animation({ leaf = "fadeLayersIn",   enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut",  enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",     enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",   enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut",  enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",     enabled = true, speed = 7,    bezier = "quick" })
