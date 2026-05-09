local home = os.getenv("HOME")
local M = {
    mainMod = "SUPER",
    terminal = "kitty",
    browser = "brave",
    is_laptop = io.open("/sys/class/power_supply/BAT1") ~= nil,
    qs = home .. "/.config/HyprV/quickshell/scripts",
}

return M


