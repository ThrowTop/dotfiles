local home = os.getenv("HOME")
local quickshell = home .. "/.config/HyprV/quickshell"

local function exists(path)
    local file = io.open(path)
    if file then
        file:close()
        return true
    end
    return false
end

local M = {
    home = home,
    main_mod = "SUPER + ",
    terminal = "kitty",
    file_manager = "thunar",
    browser = "brave",
    is_laptop = exists("/sys/class/power_supply/BAT1"),
    quickshell = quickshell,
    qs = quickshell .. "/scripts",
}

_G.settings = M


