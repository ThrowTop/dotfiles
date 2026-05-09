local hlc = require("hlc")
local hyprv = require("helpers/hyprv")

local DEVICE = "i2c-GXTP7936:00"
local DRIVER = "/sys/bus/i2c/drivers/i2c_hid_acpi"

local function is_enabled()
    return io.open(DRIVER .. "/" .. DEVICE) ~= nil
end

local function enable()
    hlc.d.exec_cmd("bash -c 'echo " .. DEVICE .. " | sudo tee " .. DRIVER .. "/bind > /dev/null'")
    hyprv.osd("Touchscreen", "On", "#a6e3a1", "0xF11FF")
end

local function disable()
    hlc.d.exec_cmd("bash -c 'echo " .. DEVICE .. " | sudo tee " .. DRIVER .. "/unbind > /dev/null'")
    hyprv.osd("Touchscreen", "Off", "#f38ba8", "0xF11FF")
end

return function(state)
    if state == "on" then
        if not is_enabled() then enable() end
    elseif state == "off" then
        if is_enabled() then disable() end
    else
        if is_enabled() then disable() else enable() end
    end
end
