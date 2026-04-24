local hlc = require("hlc")
-- Capture the focused monitor with grim and open it in satty (ShareX-style).
-- Uses the Hyprland Lua API directly — no hyprctl/jq subprocess needed.
local function screenshot()
    local m = hl.get_active_monitor()

    if not m.name then
        hlc.notify("Monitor Not Found", { icon = "error" })
        return
    end

    hl.dsp.exec_cmd(
        string.format(
            "bash -c 'grim -o %s -t ppm - | satty --filename - --fullscreen --initial-tool crop --copy-command wl-copy --early-exit --actions-on-enter save-to-clipboard'",
            m.name
        )
    )()
end
return screenshot


