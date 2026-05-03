local hlc = require("hlc")
local mod = require("settings").mainMod

hlc.config({
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
})

local curves = {
    easeOutQuint = hlc.bezier(0.23, 1, 0.32, 1),
    easeInOutCubic = hlc.bezier(0.65, 0.05, 0.36, 1),
    linear = hlc.bezier(0, 0, 1, 1),
    almostLinear = hlc.bezier(0.5, 0.5, 0.75, 1),
    quick = hlc.bezier(0.15, 0, 0.1, 1),
    -- spring: snappy with slight natural overshoot, good for windows
    snap = hlc.spring(1, 20, 4),
    fluid = hlc.spring(4, 40, 12),
}

local popin87 = hlc.style.popin(87)
local slide = hlc.style.slide()
local fade = hlc.style.fade()

-- hlc.anim(speed, curve?, style?) is just a table factory, identical to writing
-- { speed = ..., curve = ..., style = ... } by hand. use whichever reads better.
-- curve can also be a raw string referencing a curve by its Hyprland name,
-- e.g. curve = "linear" or curve = "myease" for a curve registered elsewhere.
hlc.animation = {
    global = { speed = 10 },
    border = { speed = 5.39, curve = curves.easeOutQuint },
    windows    = hlc.anim(4.79, curves.snap),
    windowsIn  = hlc.anim(4.1,  curves.snap,   popin87),
    windowsOut = { speed = 1.49, curve = "linear", style = popin87 },
    fadeIn  = { speed = 1.73, curve = curves.almostLinear },
    fadeOut = { speed = 1.46, curve = curves.almostLinear },
    fade    = { speed = 3.03, curve = curves.quick },
    layers    = hlc.anim(3.81, curves.snap),
    layersIn  = hlc.anim(4,    curves.snap,   fade),
    layersOut = hlc.anim(1.5,  curves.linear, fade),
    fadeLayersIn  = { speed = 1.79, curve = curves.almostLinear },
    fadeLayersOut = { speed = 1.39, curve = curves.almostLinear },
    workspaces    = hlc.anim(3.5, curves.fluid, slide),
    workspacesIn  = hlc.anim(3.5, curves.fluid, slide),
    workspacesOut = hlc.anim(3.0, curves.fluid, slide),
    zoomFactor = { speed = 7, curve = curves.quick },
}


