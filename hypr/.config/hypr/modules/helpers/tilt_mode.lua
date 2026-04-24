local BACKLIGHT = "/sys/class/leds/samsung-galaxybook::kbd_backlight/brightness"
local STOPFILE = "/tmp/tilt-stop"

local function refresh_stop()
    -- loop polls for this file and exits itself
    local f = io.open(STOPFILE, "w")
    if f then
        f:close()
    end
end

local function refresh_start()
    local level = "3"
    local f = io.open(BACKLIGHT, "r")
    if f then
        level = f:read("*l") or "3"
        f:close()
    end
    io.open(STOPFILE, "w"):close() -- ensure clean state
    hl.dsp.exec_cmd(string.format("bash -c 'rm -f %s; while [ ! -f %s ]; do echo %s > %s 2>/dev/null; sleep 1.5; done'", STOPFILE, STOPFILE, level, BACKLIGHT))()
end

local function hid_loaded()
    local f = io.popen("lsmod | grep -c '^intel_hid'")
    if not f then
        return false
    end
    local n = tonumber(f:read("*l") or "0")
    f:close()
    return (n or 0) > 0
end

return function()
    if hid_loaded() then
        hl.dsp.exec_cmd("sudo modprobe -r intel_hid")()
        refresh_stop()
        refresh_start()
        hl.notification.create({ text = "Tilt mode ON", timeout = 3000, icon = "ok" })
    else
        refresh_stop()
        hl.dsp.exec_cmd("sudo modprobe intel_hid")()
        hl.notification.create({ text = "Tilt mode OFF", timeout = 3000, icon = "ok" })
    end
end


