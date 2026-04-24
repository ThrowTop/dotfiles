local DEVICE = "i2c-GXTP7936:00"
local DRIVER = "/sys/bus/i2c/drivers/i2c_hid_acpi"

local function is_enabled()
    return io.open(DRIVER .. "/" .. DEVICE) ~= nil
end

local function enable()
    hl.dsp.exec_cmd("bash -c 'echo " .. DEVICE .. " | sudo tee " .. DRIVER .. "/bind > /dev/null'")()
    hl.notification.create({ text = "Touchscreen on", timeout = 1500, icon = "ok" })
end

local function disable()
    hl.dsp.exec_cmd("bash -c 'echo " .. DEVICE .. " | sudo tee " .. DRIVER .. "/unbind > /dev/null'")()
    hl.notification.create({ text = "Touchscreen off", timeout = 1500, icon = "ok" })
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
