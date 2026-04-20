---@class HLC.Curve

local M = {}

local curve_mt = {
    __tostring = function(c) return rawget(c, "_name") end,
    __newindex = function() error("hlc curve is read-only", 2) end,
}

local counter = 0

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

---@overload fun(points: number[][]): HLC.Curve
---@param name string
---@param points number[][]
---@return HLC.Curve
function M.new(name, points)
    if type(name) ~= "string" then
        points = name
        counter = counter + 1
        name = string.format("hlc_curve_%d", counter)
    end
    if type(points) ~= "table" or #points ~= 2 then
        error("hlc.curve: expected exactly two control points", 2)
    end
    validate_point(points[1], "point 1")
    validate_point(points[2], "point 2")

    hl.curve(name, { type = "bezier", points = points })
    return setmetatable({ _name = name, _points = points }, curve_mt)
end

function M.resolve(c)
    if c == nil then return "default" end
    if type(c) == "string" then return c end
    if getmetatable(c) == curve_mt then return rawget(c, "_name") end
    error("hlc: curve must be an hlc.curve(...) object or a bezier name string", 3)
end

return M
