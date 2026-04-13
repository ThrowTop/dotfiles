local s          = require("settings")
local screenshot = require("helpers/screenshot")

local mod        = s.mainMod
local ipc        = "qs -c noctalia-shell ipc call"

-- -------------------------
-- Applications
-- -------------------------
hl.bind(mod .. " + Return", hl.exec_cmd(s.terminal))
hl.bind(mod .. " + E", hl.exec_cmd("thunar"))
hl.bind(mod .. " + B", hl.exec_cmd(s.browser))
hl.bind("ALT + Space", hl.exec_cmd("vicinae toggle"))
hl.bind(mod .. " + V", hl.exec_cmd("vicinae vicinae://launch/clipboard/history"))
hl.bind("Print", screenshot)
hl.bind(mod .. " + Print", hl.exec_cmd("hyprpicker | wl-copy"))
hl.bind(mod .. " + T", hl.exec_cmd(s.hscripts .. "/touchscreen.sh"))
hl.bind(mod .. " + SHIFT + U", hl.exec_cmd("pkill qs; qs -c noctalia-shell"))
hl.bind(mod .. " + M", hl.exec_cmd(
    "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.exit()'"
))

-- Noctalia shell
hl.bind("XF86Launch1", hl.exec_cmd(ipc .. " settings open"))
hl.bind(mod .. " + F1", hl.exec_cmd(ipc .. " settings open"))

-- -------------------------
-- Window management
-- -------------------------
hl.bind(mod .. " + Q", hl.window.close())
hl.bind(mod .. " + C", hl.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", hl.window.fullscreen_state({ internal = 2, client = 0 }))
hl.bind(mod .. " + SHIFT + F", hl.window.fullscreen())
hl.bind(mod .. " + SHIFT + P", hl.window.pseudo())

-- Focus (hjkl)
hl.bind(mod .. " + H", hl.focus({ direction = "left" }))
hl.bind(mod .. " + J", hl.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.focus({ direction = "up" }))
hl.bind(mod .. " + L", hl.focus({ direction = "right" }))

-- Move windows (hjkl)
hl.bind(mod .. " + SHIFT + H", hl.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + J", hl.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + K", hl.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + L", hl.window.move({ direction = "right" }))

-- Mouse: drag / resize
hl.bind(mod .. " + mouse:272", hl.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.window.resize(), { mouse = true })

-- -------------------------
-- Workspaces
-- -------------------------
if not s.is_laptop then
    hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1" })
    hl.workspace_rule({ workspace = "2", monitor = "DP-2" })
end

for i = 1, 10 do
    local bi = i % 10 -- 0 becomes worspace 10
    hl.bind(mod .. " + " .. bi, hl.workspace(i))
    hl.bind(mod .. " + SHIFT + " .. bi, hl.window.move({ workspace = tostring(i) }))
end

-- Scroll through workspaces on current monitor
hl.bind(mod .. " + Prior", hl.workspace("r+1"))
hl.bind(mod .. " + Next", hl.workspace("r-1"))
hl.bind(mod .. " + SHIFT + Prior", hl.window.move({ workspace = "r-1" }))
hl.bind(mod .. " + SHIFT + Next", hl.window.move({ workspace = "r+1" }))
hl.bind(mod .. " + mouse_down", hl.workspace("e+1"))
hl.bind(mod .. " + mouse_up", hl.workspace("e-1"))

-- Special workspace (scratchpad)
hl.bind(mod .. " + S", hl.workspace({ special = "magic" }))
hl.bind(mod .. " + CTRL + S", hl.window.move({ workspace = "special:magic" }))

-- -------------------------
-- Monitor focus / window move (desktop only)
-- -------------------------
if not s.is_laptop then
    hl.bind("ALT + 1", hl.focus({ monitor = "HDMI-A-1" }))
    hl.bind("ALT + 2", hl.focus({ monitor = "DP-2" }))

    local function moveWindowToMonitor(monitorName)
        for _, mon in ipairs(hl.get_monitors()) do
            if mon.name == monitorName then
                local ws = mon.active_workspace
                if ws then
                    hl.window.move({ workspace = tostring(ws.id) })()
                end
                return
            end
        end
    end

    hl.bind("ALT + SHIFT + 1", function() moveWindowToMonitor("HDMI-A-1") end)
    hl.bind("ALT + SHIFT + 2", function() moveWindowToMonitor("DP-2") end)
end

-- -------------------------
-- Media & function keys
-- -------------------------
hl.bind("XF86AudioRaiseVolume", hl.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.exec_cmd("playerctl previous"), { locked = true })
