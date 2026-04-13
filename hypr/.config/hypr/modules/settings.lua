local M = {
    mainMod   = "SUPER",
    terminal  = "foot",
    browser   = "brave",
    hscripts  = os.getenv("HOME") .. "/.config/hypr/scripts",
    is_laptop = io.open("/sys/class/power_supply/BAT1") ~= nil,
    debug     = true,
}

function M.d(str)
    if M.debug then
        hl.exec_cmd(string.format("notify-send %q", str))
    end
end

return M
