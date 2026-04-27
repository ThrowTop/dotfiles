local hlc = require("hlc")

local function screenshot()
    local m = hl.get_active_monitor()

    if not m or not m.name then
        hlc.notify("Monitor Not Found", { icon = "error" })
        return
    end

    hl.exec_cmd(
        string.format(
            "bash -c 'grim -o %s -t ppm - | satty --filename - --fullscreen --initial-tool crop --copy-command wl-copy --early-exit --actions-on-enter save-to-clipboard'",
            m.name
        )
    )
end
return screenshot


