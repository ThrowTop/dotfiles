
local w, h = 600, 600
local x_gap = 20 -- gap from right edge
local y_top = 68 -- offset from top to clear the quickshell bar (58px) + gap

hl.window_rule({
    name = "bitwarden-float",
    match = { class = "^(Bitwarden)$" },
    float = true,
    size = w .. " " .. h,
    move = "100%-" .. (w + x_gap) .. " " .. y_top,
    animation = "slide right",
})

return function()
    local wins = hl.get_windows({ class = "Bitwarden" })
    if #wins == 0 then
        hlc.d.exec_cmd("bitwarden-desktop")
        return
    end
    local win = wins[1]
    local addr = "address:" .. win.address
    if win.pinned then
        hlc.d.window.pin({ action = "disable", window = addr })
        hlc.d.window.move({ workspace = "special:bitwarden", follow = false, window = addr })
    else
        local ws = hl.get_active_workspace()
        if not ws then
            return
        end
        local mon = ws.monitor
        hlc.d.window.move({ workspace = ws.id, follow = false, window = addr })
        hlc.d.window.resize({ x = w, y = h, window = addr })
        if mon then
            hlc.d.window.move({ x = mon.width - w - x_gap, y = y_top, window = addr })
        end
        hlc.d.window.pin({ action = "enable", window = addr })
        hlc.d.focus({ window = addr })
    end
end


