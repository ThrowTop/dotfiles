-- Entry point — load all modules in order.
package.path = os.getenv("HOME") .. "/.config/hypr/modules/?.lua;" .. package.path

local s = require("settings")
s.d("Hyprland Config Reloaded")

-- require("example")
require("monitors")
require("environment")
require("appearance")
require("input")
require("rules")

require("keybindings")


