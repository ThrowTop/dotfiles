local M = {
    mainMod = "SUPER",
    terminal = "kitty",
    browser = "brave",
    hscripts = os.getenv("HOME") .. "/.config/hypr/scripts",
    is_laptop = io.open("/sys/class/power_supply/BAT1") ~= nil,
}

return M


