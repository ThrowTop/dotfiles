local M = {
    mainMod = "SUPER",
    terminal = "kitty",
    browser = "brave",
    is_laptop = io.open("/sys/class/power_supply/BAT1") ~= nil,
}

return M


