-- -------------------------
-- Layer rules
-- -------------------------
hl.layer_rule({
    name         = "vicinae-blur",
    match        = { namespace = "vicinae" },
    blur         = true,
    ignore_alpha = 0,
})

hl.layer_rule({
    name    = "vicinae-no-animation",
    match   = { namespace = "vicinae" },
    no_anim = true,
})

-- -------------------------
-- Window rules
-- -------------------------
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name     = "fix-xwayland-drags",
    match    = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    float = true,
    move  = "20 monitor_h-120",
})

hl.window_rule({
    name      = "bitwarden-scratchpad",
    match     = { class = "^(Bitwarden)$" },
    float     = true,
    size      = "400 600",
    move      = "100%-420 40",
    workspace = "special:bitwarden silent",
})

hl.window_rule({
    name      = "satty-instant",
    match     = { class = "^(satty|com%.gabm%.satty)$" },
    float     = true,
    no_anim   = true,
    no_blur   = true,
    no_shadow = true,
    rounding  = 0,
})

hl.window_rule({
    name   = "thunar-float",
    match  = { class = "^(thunar|Thunar)$", title = "^(File Operation Progress).*$" },
    float  = true,
    size   = "600 300",
    center = true,
})

hl.window_rule({
    name              = "pip-float",
    match             = { title = "^(Picture-in-Picture)$" },
    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
    size              = "640 360",
    move              = "100%-660 100%-380",
})

hl.window_rule({
    match     = { class = "^(rustdesk)$" },
    workspace = "9 silent",
})

hl.window_rule({
    name  = "steam-float",
    match = { class = "^(steam)$", title = "^(Steam Settings|Friends List).*$" },
    float = true,
})

hl.window_rule({
    name   = "pavucontrol-float",
    match  = { class = "^(pavucontrol)$" },
    float  = true,
    size   = "800 500",
    center = true,
})

hl.window_rule({
    name   = "calculator-float",
    match  = { class = "^(gnome-calculator|qalculate-gtk|speedcrunch)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name     = "screenshare-indicator",
    match    = { title = "^(Firefox — Sharing Indicator|.*Sharing Indicator.*)$" },
    float    = true,
    move     = "0 0",
    pin      = true,
    no_focus = true,
})
