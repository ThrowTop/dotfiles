local M = {}

-- Resolve symlinks so the path matches what launch.sh passed to quickshell -p
local function resolve(path)
    local h = io.popen("readlink -f '" .. path .. "' 2>/dev/null")
    if not h then
        return path
    end
    local result = h:read("*l")
    h:close()
    return (result and result ~= "") and result or path
end

local QS = resolve(settings.quickshell)

local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function ipc(target, func, ...)
    local cmd = "quickshell -p " .. shell_quote(QS) .. " ipc call " .. shell_quote(target) .. " " .. shell_quote(func)
    for _, v in ipairs({ ... }) do
        cmd = cmd .. " " .. shell_quote(v)
    end
    hl.exec_cmd(cmd)
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

function M.control_brightness_inc()
    ipc("controls", "brightnessIncrease")
end
function M.control_brightness_dec()
    ipc("controls", "brightnessDecrease")
end
function M.control_volume_inc()
    ipc("controls", "volumeIncrease")
end
function M.control_volume_dec()
    ipc("controls", "volumeDecrease")
end
function M.control_volume_toggle()
    ipc("controls", "volumeToggleMute")
end

function M.set_state(key, value)
    ipc("hyprState", "set", key, value and "true" or "false")
end

function M.toggle_state(key)
    ipc("hyprState", "toggle", key)
end

return M

