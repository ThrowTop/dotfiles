---@alias HLC.AnimationLeaf
---| "global"
---| "windows" | "windowsIn" | "windowsOut" | "windowsMove"
---| "layers" | "layersIn" | "layersOut"
---| "fade" | "fadeIn" | "fadeOut" | "fadeSwitch" | "fadeShadow" | "fadeGlow" | "fadeDim"
---| "fadeLayers" | "fadeLayersIn" | "fadeLayersOut"
---| "fadePopups" | "fadePopupsIn" | "fadePopupsOut" | "fadeDpms"
---| "border" | "borderangle"
---| "workspaces" | "workspacesIn" | "workspacesOut"
---| "specialWorkspace" | "specialWorkspaceIn" | "specialWorkspaceOut"
---| "zoomFactor" | "monitorAdded"

---@class HLC.AnimationSpec
---@field enabled? boolean
---@field speed?   number
---@field curve?   HLC.Curve|string
---@field style?   HLC.Style|string

---@class HLC.Animations
---@field global?              HLC.AnimationSpec
---@field windows?             HLC.AnimationSpec
---@field windowsIn?           HLC.AnimationSpec
---@field windowsOut?          HLC.AnimationSpec
---@field windowsMove?         HLC.AnimationSpec
---@field layers?              HLC.AnimationSpec
---@field layersIn?            HLC.AnimationSpec
---@field layersOut?           HLC.AnimationSpec
---@field fade?                HLC.AnimationSpec
---@field fadeIn?              HLC.AnimationSpec
---@field fadeOut?             HLC.AnimationSpec
---@field fadeSwitch?          HLC.AnimationSpec
---@field fadeShadow?          HLC.AnimationSpec
---@field fadeGlow?            HLC.AnimationSpec
---@field fadeDim?             HLC.AnimationSpec
---@field fadeLayers?          HLC.AnimationSpec
---@field fadeLayersIn?        HLC.AnimationSpec
---@field fadeLayersOut?       HLC.AnimationSpec
---@field fadePopups?          HLC.AnimationSpec
---@field fadePopupsIn?        HLC.AnimationSpec
---@field fadePopupsOut?       HLC.AnimationSpec
---@field fadeDpms?            HLC.AnimationSpec
---@field border?              HLC.AnimationSpec
---@field borderangle?         HLC.AnimationSpec
---@field workspaces?          HLC.AnimationSpec
---@field workspacesIn?        HLC.AnimationSpec
---@field workspacesOut?       HLC.AnimationSpec
---@field specialWorkspace?    HLC.AnimationSpec
---@field specialWorkspaceIn?  HLC.AnimationSpec
---@field specialWorkspaceOut? HLC.AnimationSpec
---@field zoomFactor?          HLC.AnimationSpec
---@field monitorAdded?        HLC.AnimationSpec

local curve = require("hlc.curve")
local style = require("hlc.style")

local VALID_LEAVES = {}
for _, leaf in ipairs({
    "global", "windows", "windowsIn", "windowsOut", "windowsMove",
    "layers", "layersIn", "layersOut",
    "fade", "fadeIn", "fadeOut", "fadeSwitch", "fadeShadow", "fadeGlow",
    "fadeDim", "fadeLayers", "fadeLayersIn", "fadeLayersOut",
    "fadePopups", "fadePopupsIn", "fadePopupsOut", "fadeDpms",
    "border", "borderangle",
    "workspaces", "workspacesIn", "workspacesOut",
    "specialWorkspace", "specialWorkspaceIn", "specialWorkspaceOut",
    "zoomFactor", "monitorAdded",
}) do VALID_LEAVES[leaf] = true end

local state = {}

local function apply(leaf)
    local s = state[leaf]
    local spec = {
        leaf    = leaf,
        enabled = s.enabled,
        speed   = s.speed,
        bezier  = curve.resolve(s.curve),
    }
    local str = style.resolve(s.style)
    if str then spec.style = str end
    hl.animation(spec)
end

local function normalise(leaf, spec)
    if type(spec) ~= "table" then
        error(string.format("hlc.animation.%s: expected a table", leaf), 3)
    end
    local enabled = spec.enabled; if enabled == nil then enabled = true end
    local speed = spec.speed or 1
    if enabled and (type(speed) ~= "number" or speed <= 0) then
        error(string.format("hlc.animation.%s: speed must be > 0 when enabled", leaf), 3)
    end
    return { enabled = enabled, speed = speed, curve = spec.curve, style = spec.style }
end

local leaf_mt = {}

leaf_mt.__index = function(proxy, key)
    local s = state[rawget(proxy, "_leaf")]
    return s and s[key] or nil
end

leaf_mt.__newindex = function(proxy, key, value)
    local leaf = rawget(proxy, "_leaf")
    local s = state[leaf]
    if not s then
        s = { enabled = true, speed = 1 }
        state[leaf] = s
    end
    s[key] = value
    apply(leaf)
end

leaf_mt.__tostring = function(proxy)
    local leaf = rawget(proxy, "_leaf")
    local s = state[leaf] or {}
    return string.format(
        "hlc.animation.%s{enabled=%s, speed=%s, curve=%s, style=%s}",
        leaf, tostring(s.enabled), tostring(s.speed),
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

local proxy = setmetatable({}, {
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
        state[leaf] = normalise(leaf, spec)
        apply(leaf)
    end,
    __call = function(self, specs)
        if type(specs) ~= "table" then
            error("hlc.animation(...): expected a table of {leaf = spec}", 2)
        end
        for leaf, spec in pairs(specs) do self[leaf] = spec end
    end,
})

return proxy
