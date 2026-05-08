local hlc = require("hlc")

-- shared curves
local ease = hlc.bezier(0.23, 1, 0.32, 1)
local linear = hlc.bezier(0, 0, 1, 1)
local snap = hlc.spring(1, 200, 18)

-- styles
local popin = hlc.style.popin()
local popin87 = hlc.style.popin(87)
local slide = hlc.style.slide(w)
local slide50 = hlc.style.slide(50)
local slidevert = hlc.style.slidevert()
local fade = hlc.style.fade()
local gnomed = hlc.style.gnomed()
local slidefade = hlc.style.slidefade()
local slidefadevert = hlc.style.slidefadevert()
local loop = hlc.style.loop()
local once = hlc.style.once()

-- windows: slide, popin, gnomed
hlc.animation = {
    windows = hlc.anim(4, snap, slide),
    windowsIn = hlc.anim(4, snap, popin87),
    windowsOut = hlc.anim(2, ease, gnomed),
    windowsMove = hlc.anim(3, snap, popin),
}

-- layers: slide, popin, fade
hlc.animation = {
    layers = hlc.anim(4, snap, slide),
    layersIn = hlc.anim(4, snap, popin),
    layersOut = hlc.anim(2, ease, fade),
}

-- workspaces: slide, slidevert, fade, slidefade, slidefadevert
hlc.animation = {
    workspaces = hlc.anim(4, ease, slide),
    workspacesIn = hlc.anim(4, ease, slidevert),
    workspacesOut = hlc.anim(3, ease, fade),
    specialWorkspace = hlc.anim(4, ease, slidefade),
    specialWorkspaceIn = hlc.anim(4, ease, slidefadevert),
    specialWorkspaceOut = hlc.anim(3, ease, slide50),
}

-- borderangle: once, loop
hlc.animation = {
    border = hlc.anim(5, ease),
    borderangle = hlc.anim(8, linear, loop),
}

-- fade leaves (no styles)
hlc.animation = {
    fade = hlc.anim(3, ease),
    fadeIn = hlc.anim(2, ease),
    fadeOut = hlc.anim(2, ease),
    fadeSwitch = hlc.anim(2, ease),
    fadeShadow = hlc.anim(2, ease),
    fadeDim = hlc.anim(2, ease),
    fadeLayers = hlc.anim(2, ease),
    fadeLayersIn = hlc.anim(2, ease),
    fadeLayersOut = hlc.anim(2, ease),
    fadePopups = hlc.anim(2, ease),
    fadePopupsIn = hlc.anim(2, ease),
    fadePopupsOut = hlc.anim(2, ease),
    fadeDpms = hlc.anim(2, ease),
}

-- misc leaves
hlc.animation = {
    global = { speed = 10 },
    zoomFactor = hlc.anim(7, ease),
    monitorAdded = hlc.anim(4, ease),
}

hlc.notify("test.lua loaded")

-- ============================================================
-- INVALID COMBINATIONS — hlc tracking test
-- each block tests a different category of "wrong"
-- ============================================================

-- [1] unknown leaf name — hlc should error (VALID_LEAVES check)
-- hlc.animation.fakeLeaf = hlc.anim(4, ease)

-- [2] unknown leaf via batch assign — same guard, different path
-- hlc.animation = { notALeaf = hlc.anim(4, ease) }

-- [3] style that no longer exists in hlc (gnome was removed)
-- hlc.animation.windowsIn = hlc.anim(4, ease, hlc.style.gnome())

-- [4] wrong-category style on a leaf — NOT caught by hlc or Hyprland
-- accepted because AnimationManager::styleValidInConfigVar() uses
-- style.starts_with("slide") for window leaves, so "slidefade" passes.
-- intended to allow parameterized "slide 50%" variants, not a real accept.
-- hlc.animation.windowsIn = hlc.anim(4, ease, slidefade)

-- hl.curve("ease", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
-- [5] wrong-category style on a leaf — caught by HYPRLAND, not hlc
-- errors at hlc.lua:475 hl.animation("workspaces"): unknown style
-- hlc.animation.workspaces = hlc.anim(4, ease, gnomed)

-- [6] loop/once on windows — only valid for borderangle, hlc won't catch it
-- hlc.animation.windowsIn = hlc.anim(4, ease, loop)

-- [7] popin with out-of-range percentage — hlc DOES catch this (require_percent)
-- hlc.style.popin(150) -- error: percentage must be in [0, 100]
-- hlc.style.slide(-5) -- error: percentage must be in [0, 100]

-- [8] speed = 0 while enabled — hlc DOES catch this (speed must be > 0)
-- hlc.animation.windows = { speed = 0 }

-- [9] raw string style — hlc passes through, caught by HYPRLAND at runtime
-- hlc.animation.windowsIn = hlc.anim(4, ease, "totallyMadeUp")


