---@class HLC.Style

---@class HLC.StyleFactory
---@field popin     fun(perc?: number): HLC.Style
---@field slide     fun(perc?: number): HLC.Style
---@field slidevert fun(): HLC.Style
---@field fade      fun(): HLC.Style
---@field gnome     fun(): HLC.Style
---@field gnomed    fun(): HLC.Style
---@field loop      fun(): HLC.Style
---@field once      fun(): HLC.Style

local M = {}

local style_mt = { __tostring = function(s) return rawget(s, "_str") end }

local function make(str, kind, extra)
    return setmetatable({ _str = str, _kind = kind, _extra = extra }, style_mt)
end

local function require_percent(fn, perc)
    if type(perc) ~= "number" or perc < 0 or perc > 100 then
        error("hlc.style." .. fn .. ": percentage must be a number in [0, 100]", 3)
    end
end

---@type HLC.StyleFactory
M.factory = {
    popin = function(perc)
        if perc == nil then return make("popin", "popin") end
        require_percent("popin", perc)
        return make(string.format("popin %d%%", math.floor(perc)), "popin", perc)
    end,
    slide = function(perc)
        if perc == nil then return make("slide", "slide") end
        require_percent("slide", perc)
        return make(string.format("slide %d%%", math.floor(perc)), "slide", perc)
    end,
    slidevert = function() return make("slidevert", "slidevert") end,
    fade      = function() return make("fade", "fade") end,
    gnome     = function() return make("gnome", "gnome") end,
    gnomed    = function() return make("gnomed", "gnomed") end,
    loop      = function() return make("loop", "loop") end,
    once      = function() return make("once", "once") end,
}

function M.resolve(s)
    if s == nil then return nil end
    if type(s) == "string" then return s end
    if getmetatable(s) == style_mt then return rawget(s, "_str") end
    error("hlc: style must be an hlc.style.* object", 3)
end

return M
