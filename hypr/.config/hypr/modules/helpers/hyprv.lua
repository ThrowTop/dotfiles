local hlc = require("hlc")
local M = {}

-- Resolve symlinks so the path matches what launch.sh passed to quickshell -p
local function resolve(path)
    local h = io.popen("readlink -f '" .. path .. "' 2>/dev/null")
    if not h then return path end
    local result = h:read("*l")
    h:close()
    return (result and result ~= "") and result or path
end

local QS = resolve(os.getenv("HOME") .. "/.config/HyprV/quickshell")

local function ipc(target, func, ...)
    local cmd = "quickshell -p " .. QS .. " ipc call " .. target .. " " .. func
    for _, v in ipairs({...}) do
        cmd = cmd .. ' "' .. tostring(v) .. '"'
    end
    hlc.d.exec_cmd("bash -c '" .. cmd .. "'")
end

-- OSD: show a sidetext notification in the Dynamic Island.
-- icon: Nerd Font codepoint as hex string, e.g. "0xF052F"
-- duration: optional milliseconds (default 1500)
function M.osd(label, right, accent, icon, duration)
    ipc("osd", "trigger", label, right, accent, tostring(icon), duration or "")
end

-- Control panel popup
function M.control_panel_toggle()
    ipc("controlPanel", "toggle")
end

-- Quick-adjust popups
function M.show_brightness()  ipc("quickAdjust", "showBrightness") end
function M.show_volume()      ipc("quickAdjust", "showVolume") end
function M.brightness_inc()   ipc("quickAdjust", "showBrightnessIncrease") end
function M.brightness_dec()   ipc("quickAdjust", "showBrightnessDecrease") end

return M
