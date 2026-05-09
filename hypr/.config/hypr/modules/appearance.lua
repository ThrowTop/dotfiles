local hlc = require("hlc")

hlc.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 1,
        col = {
            active_border = { colors = { "rgb(8e90cb)", angle = 45 } },
            inactive_border = { colors = { "rgb(303030)", "rgb(8e90cb)", angle = 35 } },
        },
        layout = "dwindle",
        resize_on_border = false,
        resize_corner = 3,
    },
    decoration = {
        rounding = 19,
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
    spring = hlc.spring(1, 140, 18), -- smooth, slightly faster than before
    fluid = hlc.spring(1, 25, 5), -- softer spring for workspace slides
    ease = hlc.bezier(0.23, 1, 0.32, 1), -- easeOutQuint for exits/fades
    quick = hlc.bezier(0.15, 0, 0.1, 1),
    linear = hlc.bezier(0, 0, 1, 1),
}

local popin87 = hlc.style.popin(87)
local slide = hlc.style.slide()
local fade = hlc.style.fade()
local gnomed = hlc.style.gnomed()

hlc.animation = {
    global = { speed = 10 },
    border = { speed = 5, curve = curves.ease },

    -- windows (valid styles: slide, popin, gnomed)
    windows = hlc.anim(4.5, curves.spring),
    windowsIn = hlc.anim(4.5, curves.spring, popin87),
    windowsOut = hlc.anim(1.5, curves.ease, gnomed),
    windowsMove = hlc.anim(4.5, curves.spring),

    -- layers (bars, overlays) — match window feel
    layers = hlc.anim(4.5, curves.spring, slide),
    layersIn = hlc.anim(4.5, curves.spring, fade),
    layersOut = hlc.anim(1.5, curves.ease, fade),
    fadeLayersIn = { speed = 2, curve = curves.ease },
    fadeLayersOut = { speed = 1.5, curve = curves.ease },

    -- workspaces — fluid spring slide
    workspaces = hlc.anim(3.5, curves.fluid, slide),
    workspacesIn = hlc.anim(3.5, curves.fluid, slide),
    workspacesOut = hlc.anim(3.0, curves.fluid, slide),

    -- fades
    fade = { speed = 3, curve = curves.quick },
    fadeIn = { speed = 2, curve = curves.ease },
    fadeOut = { speed = 1.5, curve = curves.ease },

    zoomFactor = { speed = 6, curve = curves.spring },
}


