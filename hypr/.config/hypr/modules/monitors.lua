local s = require("settings")

if s.is_laptop then
    hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
else
    hl.monitor({ output = "DP-2",    mode = "1920x1080@240", position = "0x0",    scale = 1 })
    hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60",  position = "-1920x0", scale = 1 })
end
