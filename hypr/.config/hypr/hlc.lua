-- hlc — Hyprland Lua config wrapper.
--
-- Provides:
--   hlc.config    — readable/writable mirror proxy for hl.config()
--   hlc.curve     — named bezier curve definitions
--   hlc.style     — animation style value objects
--   hlc.animation — per-leaf animation proxy with live state mirror
--
-- Usage:
--   hlc.config.general.gaps_in = 4
--   local gen = hlc.config.general
--   gen.gaps_out = 8
--   hlc.config.input.touchpad["tap-to-click"] = true   -- hyphenated keys
--   hlc.config({ general = { gaps_in = 4 } })           -- bulk apply

local M = {}

-- ─── internal utilities ──────────────────────────────────────────────────────

local function get_nested(t, path)
    for i = 1, #path do
        if type(t) ~= "table" then return nil end
        t = t[path[i]]
    end
    return t
end

local function set_nested(t, path, value)
    for i = 1, #path - 1 do
        local k = path[i]
        if type(t[k]) ~= "table" then t[k] = {} end
        t = t[k]
    end
    t[path[#path]] = value
end

local function deep_merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            deep_merge(dst[k], v)
        else
            dst[k] = v
        end
    end
end

-- Wraps `value` in nested single-key tables according to `path`.
-- wrap_path({"a","b"}, v) → { a = { b = v } }
-- wrap_path({}, v)        → v  (no-op for root)
local function wrap_path(path, value)
    local t = value
    for i = #path, 1, -1 do
        t = { [path[i]] = t }
    end
    return t
end

-- ─── config mirror ───────────────────────────────────────────────────────────
--
-- hlc.config mirrors every value set through it in a plain Lua table so that
-- values are readable back as ordinary Lua. Writes call hl.config() immediately.
--
-- Supported keys are the full set from meta/hl.meta.lua (HL.ConfigKey union).
-- Keys that contain hyphens (e.g. input.touchpad.tap-to-click) are accessed
-- with bracket notation: hlc.config.input.touchpad["tap-to-click"] = true
--
-- HL.ConfigKey sections:
--   animations, binds, cursor, debug, decoration(.blur, .glow, .shadow),
--   dwindle, ecosystem, experimental, general(.col, .snap), gestures,
--   group(.col, .groupbar(.col)), input(.tablet, .touchdevice, .touchpad,
--   .virtualkeyboard), layout, master, misc(.col), opengl, quirks, render,
--   scrolling, xwayland

local config_mirror = {}

local config_proxy_mt = {}

config_proxy_mt.__index = function(proxy, key)
    local path = rawget(proxy, "_path")
    local new_path = {}
    for _, v in ipairs(path) do new_path[#new_path + 1] = v end
    new_path[#new_path + 1] = key
    local mirrored = get_nested(config_mirror, new_path)
    -- Return the value directly for scalar leaves that were previously set.
    -- For tables (namespaces) or unset paths, return a sub-proxy so the chain
    -- can continue and assignments at any depth work correctly.
    if mirrored ~= nil and type(mirrored) ~= "table" then
        return mirrored
    end
    return setmetatable({ _path = new_path }, config_proxy_mt)
end

config_proxy_mt.__newindex = function(proxy, key, value)
    local path = rawget(proxy, "_path")
    local full_path = {}
    for _, v in ipairs(path) do full_path[#full_path + 1] = v end
    full_path[#full_path + 1] = key
    set_nested(config_mirror, full_path, value)
    hl.config(wrap_path(full_path, value))
end

-- hlc.config({ ... }) or hlc.config.section({ ... }) — bulk apply.
-- Merges into the mirror and calls hl.config() once.
config_proxy_mt.__call = function(proxy, tbl)
    if type(tbl) ~= "table" then
        error("hlc.config: expected a table", 2)
    end
    local path = rawget(proxy, "_path")
    -- Navigate/create the mirror sub-tree for this proxy's prefix.
    local node = config_mirror
    for _, seg in ipairs(path) do
        if type(node[seg]) ~= "table" then node[seg] = {} end
        node = node[seg]
    end
    deep_merge(node, tbl)
    hl.config(wrap_path(path, tbl))
end

config_proxy_mt.__tostring = function(proxy)
    local path = rawget(proxy, "_path")
    return "hlc.config[" .. (#path > 0 and table.concat(path, ".") or "root") .. "]"
end

M.config = setmetatable({ _path = {} }, config_proxy_mt)

-- ─── curve ───────────────────────────────────────────────────────────────────

local curve_mt = {
    __tostring = function(c) return rawget(c, "_name") end,
    __newindex = function() error("hlc curve is read-only", 2) end,
}

local curve_counter = 0

local function validate_point(p, label)
    if type(p) ~= "table" or type(p[1]) ~= "number" or type(p[2]) ~= "number" then
        error("hlc.curve: " .. label .. " must be {x, y}", 3)
    end
    for _, v in ipairs({ p[1], p[2] }) do
        if v < -1 or v > 2 then
            error("hlc.curve: " .. label .. " coordinates must be in [-1, 2]", 3)
        end
    end
end

--- hlc.curve({{x1,y1},{x2,y2}})          — anonymous (auto-named)
--- hlc.curve("name", {{x1,y1},{x2,y2}})  — explicit name
function M.curve(a, b)
    local name, points
    if type(a) == "string" then
        name, points = a, b
    else
        curve_counter = curve_counter + 1
        name = string.format("hlc_curve_%d", curve_counter)
        points = a
    end
    if type(points) ~= "table" or #points ~= 2 then
        error("hlc.curve: expected exactly two control points", 2)
    end
    validate_point(points[1], "point 1")
    validate_point(points[2], "point 2")
    hl.curve(name, { type = "bezier", points = points })
    return setmetatable({ _name = name, _points = points }, curve_mt)
end

local function resolve_curve(c)
    if c == nil then return "default" end
    if type(c) == "string" then return c end
    if getmetatable(c) == curve_mt then return rawget(c, "_name") end
    error("hlc: curve must be an hlc.curve() object or a bezier name string", 3)
end

-- ─── style ───────────────────────────────────────────────────────────────────

local style_mt = { __tostring = function(s) return rawget(s, "_str") end }

local function make_style(str, kind, extra)
    return setmetatable({ _str = str, _kind = kind, _extra = extra }, style_mt)
end

local function require_percent(fn, perc)
    if type(perc) ~= "number" or perc < 0 or perc > 100 then
        error("hlc.style." .. fn .. ": percentage must be a number in [0, 100]", 3)
    end
end

M.style = {
    popin = function(perc)
        if perc == nil then return make_style("popin", "popin") end
        require_percent("popin", perc)
        return make_style(string.format("popin %d%%", math.floor(perc)), "popin", perc)
    end,
    slide = function(perc)
        if perc == nil then return make_style("slide", "slide") end
        require_percent("slide", perc)
        return make_style(string.format("slide %d%%", math.floor(perc)), "slide", perc)
    end,
    slidevert = function() return make_style("slidevert", "slidevert") end,
    fade      = function() return make_style("fade",      "fade")      end,
    gnome     = function() return make_style("gnome",     "gnome")     end,
    gnomed    = function() return make_style("gnomed",    "gnomed")    end,
    loop      = function() return make_style("loop",      "loop")      end,
    once      = function() return make_style("once",      "once")      end,
}

local function resolve_style(s)
    if s == nil then return nil end
    if type(s) == "string" then return s end
    if getmetatable(s) == style_mt then return rawget(s, "_str") end
    error("hlc: style must be an hlc.style.* object or a string", 3)
end

-- ─── animation ───────────────────────────────────────────────────────────────

local VALID_LEAVES = {}
for _, leaf in ipairs({
    "global",
    "windows", "windowsIn", "windowsOut", "windowsMove",
    "layers",  "layersIn",  "layersOut",
    "fade",    "fadeIn",    "fadeOut",    "fadeSwitch", "fadeShadow",
    "fadeGlow","fadeDim",
    "fadeLayers",  "fadeLayersIn",  "fadeLayersOut",
    "fadePopups",  "fadePopupsIn",  "fadePopupsOut",  "fadeDpms",
    "border",  "borderangle",
    "workspaces",      "workspacesIn",      "workspacesOut",
    "specialWorkspace","specialWorkspaceIn","specialWorkspaceOut",
    "zoomFactor", "monitorAdded",
}) do VALID_LEAVES[leaf] = true end

local anim_state = {}

local function apply_animation(leaf)
    local s = anim_state[leaf]
    local spec = {
        leaf    = leaf,
        enabled = s.enabled,
        speed   = s.speed,
        bezier  = resolve_curve(s.curve),
    }
    local str = resolve_style(s.style)
    if str then spec.style = str end
    hl.animation(spec)
end

local function normalise_animation(leaf, spec)
    if type(spec) ~= "table" then
        error(string.format("hlc.animation.%s: expected a table", leaf), 3)
    end
    local enabled = spec.enabled
    if enabled == nil then enabled = true end
    local speed = spec.speed or 1
    if enabled and (type(speed) ~= "number" or speed <= 0) then
        error(string.format("hlc.animation.%s: speed must be > 0 when enabled", leaf), 3)
    end
    return { enabled = enabled, speed = speed, curve = spec.curve, style = spec.style }
end

local leaf_mt = {}

leaf_mt.__index = function(proxy, key)
    local s = anim_state[rawget(proxy, "_leaf")]
    return s and s[key] or nil
end

leaf_mt.__newindex = function(proxy, key, value)
    local leaf = rawget(proxy, "_leaf")
    local s = anim_state[leaf]
    if not s then
        s = { enabled = true, speed = 1 }
        anim_state[leaf] = s
    end
    s[key] = value
    apply_animation(leaf)
end

leaf_mt.__tostring = function(proxy)
    local leaf = rawget(proxy, "_leaf")
    local s = anim_state[leaf] or {}
    return string.format(
        "hlc.animation.%s{enabled=%s, speed=%s, curve=%s, style=%s}",
        leaf,
        tostring(s.enabled),
        tostring(s.speed),
        s.curve and tostring(s.curve) or "nil",
        s.style and tostring(s.style) or "nil"
    )
end

local leaf_cache = {}
local function leaf_proxy(leaf)
    local p = leaf_cache[leaf]
    if not p then
        p = setmetatable({ _leaf = leaf }, leaf_mt)
        leaf_cache[leaf] = p
    end
    return p
end

local animation_proxy = setmetatable({}, {
    __index = function(_, leaf)
        if not VALID_LEAVES[leaf] then
            error(string.format("hlc.animation: no such leaf %q", leaf), 2)
        end
        return leaf_proxy(leaf)
    end,
    __newindex = function(_, leaf, spec)
        if not VALID_LEAVES[leaf] then
            error(string.format("hlc.animation: no such leaf %q", leaf), 2)
        end
        anim_state[leaf] = normalise_animation(leaf, spec)
        apply_animation(leaf)
    end,
    -- hlc.animation{ global = {...}, windows = {...} }
    __call = function(self, specs)
        if type(specs) ~= "table" then
            error("hlc.animation(...): expected a table of {leaf = spec}", 2)
        end
        for leaf, spec in pairs(specs) do self[leaf] = spec end
    end,
})

M.animation = animation_proxy

-- ─── module export ───────────────────────────────────────────────────────────

return setmetatable({}, {
    __index = M,
    __newindex = function(_, k, v)
        if k == "animation" then
            animation_proxy(v)
            return
        end
        error(string.format("hlc: cannot assign to hlc.%s", tostring(k)), 2)
    end,
})
