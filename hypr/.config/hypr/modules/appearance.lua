local hlc = require("hlc")
local mod = require("settings").mainMod

hlc.config = {
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = { colors = { "rgb(B4BEFE)", "rgb(303030)", angle = 45 } },
            inactive_border = { colors = { "rgb(303030)", "rgb(B4BEFE)", angle = 35 } },
        },
        layout = "dwindle",
        resize_on_border = false,
        resize_corner = 3,
    },
    decoration = {
        rounding = 12,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.9,
        border_part_of_window = true,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = 0xee1a1a1a,
        },
        blur = {
            enabled = true,
            size = 16,
            passes = 2,
            ignore_opacity = true,
            new_optimizations = true,
            xray = false,
            noise = 0.0117,
            contrast = 0.8916,
            brightness = 0.8172,
            vibrancy = 0.1696,
            popups = false,
        },
    },
    animations = { enabled = true },
    master = { new_status = "master" },
    misc = { force_default_wallpaper = 0, disable_hyprland_logo = true },
}

local curves = {
    easeOutQuint = hlc.curve(0.23, 1, 0.32, 1),
    easeInOutCubic = hlc.curve(0.65, 0.05, 0.36, 1),
    linear = hlc.curve(0, 0, 1, 1),
    almostLinear = hlc.curve(0.5, 0.5, 0.75, 1),
    quick = hlc.curve(0.15, 0, 0.1, 1),
}

local popin87 = hlc.style.popin(87)
local slide = hlc.style.slide()
local fade = hlc.style.fade()

hlc.animation = {
    global = { speed = 10 },
    border = { speed = 5.39, curve = curves.easeOutQuint },
    windows = { speed = 4.79, curve = curves.easeOutQuint },
    windowsIn = { speed = 4.1, curve = curves.easeOutQuint, style = popin87 },
    windowsOut = { speed = 1.49, curve = curves.linear, style = popin87 },
    fadeIn = { speed = 1.73, curve = curves.almostLinear },
    fadeOut = { speed = 1.46, curve = curves.almostLinear },
    fade = { speed = 3.03, curve = curves.quick },
    layers = { speed = 3.81, curve = curves.easeOutQuint },
    layersIn = { speed = 4, curve = curves.easeOutQuint, style = fade },
    layersOut = { speed = 1.5, curve = curves.linear, style = fade },
    fadeLayersIn = { speed = 1.79, curve = curves.almostLinear },
    fadeLayersOut = { speed = 1.39, curve = curves.almostLinear },
    workspaces = { speed = 3.5, curve = curves.easeOutQuint, style = slide },
    workspacesIn = { speed = 3.5, curve = curves.easeOutQuint, style = slide },
    workspacesOut = { speed = 3.0, curve = curves.easeInOutCubic, style = slide },
    zoomFactor = { speed = 7, curve = curves.quick },
}


