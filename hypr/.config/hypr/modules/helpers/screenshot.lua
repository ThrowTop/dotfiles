-- Capture the focused monitor with grim and open it in satty (ShareX-style).
-- Uses the Hyprland Lua API directly — no hyprctl/jq subprocess needed.
local function screenshot()
    local monitor_name

    for _, mon in ipairs(hl.get_monitors()) do
        if mon.focused then
            monitor_name = mon.name
            break
        end
    end

    if not monitor_name then
        return
    end

    hl.dsp.exec_cmd(
        string.format(
            "bash -c 'grim -o %s -t ppm - | satty --filename - --fullscreen --initial-tool crop --copy-command wl-copy --early-exit --actions-on-enter save-to-clipboard'",
            monitor_name
        )
    )()
end
return screenshot


