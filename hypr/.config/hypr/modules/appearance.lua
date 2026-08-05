hlc.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 1,
        col = {
            active_border = { colors = { "rgb(8789C1)", angle = 45 } },
            inactive_border = { colors = { "rgba(FeF0Fb30)", angle = 45 } },
        },
        layout = "dwindle",
        resize_on_border = false,
        resize_corner = 3,
    },
    decoration = {
        rounding = 19,
        rounding_power = 3.5,
        active_opacity = 1.0,
        inactive_opacity = 0.9,
        border_part_of_window = true,
        shadow = {
            enabled = false,
            range = 4,
            render_power = 3,
            color = 0xee1a1a1a,
        },
        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            ignore_opacity = true,
            new_optimizations = true,
            xray = false,
            noise = 0.0117,
            contrast = 0.8916,
            brightness = 1.28172,
            vibrancy = 0.1696,
            popups = false,
        },
    },
    animations = { enabled = true },
    master = { new_status = "master" },
    misc = { force_default_wallpaper = 0, disable_hyprland_logo = true },
})

local curves = {
    spring = hlc.spring(1, 140, 24), -- high damping: snappy start, minimal overshoot
    fluid = hlc.spring(1, 25, 5), -- softer spring for workspace slides
    ease = hlc.bezier(0.23, 1, 0.32, 1), -- easeOutQuint for exits/fades
    quick = hlc.bezier(0.15, 0, 0.1, 1),
    linear = hlc.bezier(0, 0, 1, 1),
    outCubic = hlc.bezier(0.33, 1, 0.68, 1), -- matches HyprV DynamicIsland expansion (210ms OutCubic)
    easeOutExpo = hlc.bezier(1.16, 1, 0.3, 1), -- very aggressive decel, snappiest feel
    easeOutBack = hlc.bezier(0.34, 1.26, 0.64, 1), -- slight overshoot, springy without a real spring
    easeOutBackSubtle = hlc.bezier(0.34, 1.06, 0.64, 1), -- barely-there overshoot for workspace slide
    easeOutQuart = hlc.bezier(0.25, 1, 0.5, 1), -- between outCubic and easeOutExpo
}

local popin92 = hlc.style.popin(92)
local slide = hlc.style.slide()
local fade = hlc.style.fade()
local gnomed = hlc.style.gnomed()

hlc.animation = {
    global = hlc.anim(10, curves.linear),
    monitorAdded = { enabled = false },

    -- border: snappy focus highlight
    border = hlc.anim(2.5, curves.outCubic),

    -- windows
    windows = hlc.anim(4.5, curves.outCubic),
    windowsIn = hlc.anim(4.5, curves.outCubic, popin92),
    windowsOut = hlc.anim(2.0, curves.ease, gnomed),
    windowsMove = hlc.anim(4.5, curves.easeOutBack),

    -- layers (bars, overlays)
    layers = hlc.anim(4.5, curves.outCubic, slide),
    layersIn = hlc.anim(4.0, curves.easeOutExpo, slide),
    layersOut = hlc.anim(1.5, curves.ease, fade),
    fadeLayersIn = hlc.anim(3, curves.easeOutExpo),
    fadeLayersOut = hlc.anim(2, curves.ease),

    -- workspaces — inertia with a barely-there overshoot
    workspaces = hlc.anim(3.5, curves.easeOutBackSubtle, slide),
    workspacesIn = hlc.anim(3.5, curves.easeOutBackSubtle, slide),
    workspacesOut = hlc.anim(3.0, curves.easeOutBackSubtle, slide),

    -- fades — fast and decisive
    fade = hlc.anim(4, curves.easeOutExpo),
    fadeIn = hlc.anim(3, curves.easeOutExpo),
    fadeOut = hlc.anim(2, curves.ease),

    -- overview zoom — lands with a slight pop
    zoomFactor = hlc.anim(5, curves.easeOutBack),
}


