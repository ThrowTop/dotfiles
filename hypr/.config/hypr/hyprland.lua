-- Entry point — load all modules in order.
package.path = os.getenv("HOME") .. "/.config/hypr/modules/?.lua;" .. package.path

local s = require("settings")
s.d("hyprland lua loaded")

require("monitors")
require("environment")
require("appearance")
require("input")
require("keybindings")
require("rules")
