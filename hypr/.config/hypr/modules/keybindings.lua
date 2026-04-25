local s = require("settings")
local hlc = require("hlc")

local screenshot = require("helpers/screenshot")
local tilt_mode = require("helpers/tilt_mode")
local touchscreen = require("helpers/touchscreen")

local mod = s.mainMod
local ipc = "qs -c noctalia-shell ipc call"

-- -------------------------
-- Applications
-- -------------------------
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(s.terminal))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(s.browser))
hl.bind("ALT + Space", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("vicinae vicinae://launch/clipboard/history"))
hl.bind("Print", screenshot)
hl.bind(mod .. " + Print", hl.dsp.exec_cmd("hyprpicker | wl-copy"))
hl.bind(mod .. " + F5", touchscreen)
hl.bind("CTRL + SUPER + XF86TouchpadToggle", touchscreen)
hl.bind(mod .. " + SHIFT + U", hl.dsp.exec_cmd("pkill qs; qs -c noctalia-shell"))
hl.bind(mod .. " + M", hl.dsp.exit())

-- Noctalia shell
hl.bind("XF86Launch1", hl.dsp.exec_cmd(ipc .. " settings open"))
hl.bind(mod .. " + F1", hl.dsp.exec_cmd(ipc .. " settings open"))

-- -------------------------
-- Window management
-- -------------------------
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + C", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen_state({ internal = 2, client = 0, action = "toggle" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + P", hl.dsp.window.pseudo())

-- Focus (hjkl)
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))

-- Move windows (hjkl)
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Notify on submap change
local submap_notif = nil
hl.on("keybinds.submap", function(name)
    if submap_notif and submap_notif:is_alive() then
        submap_notif:dismiss()
    end
    if name ~= "" then
        submap_notif = hl.notification.create({
            text = "mode: " .. name,
            timeout = 999999,
            icon = "hint",
        })
    end
end)

-- Resize submap (SUPER+R → hjkl to resize, Escape to exit)
hl.define_submap("resize", function()
    local left = hl.dsp.window.resize({ x = -30, y = 0, relative = true })
    local down = hl.dsp.window.resize({ x = 0, y = 30, relative = true })
    local up = hl.dsp.window.resize({ x = 0, y = -30, relative = true })
    local right = hl.dsp.window.resize({ x = 30, y = 0, relative = true })

    hl.bind("H", left, { repeating = true })
    hl.bind("J", down, { repeating = true })
    hl.bind("K", up, { repeating = true })
    hl.bind("L", right, { repeating = true })
    hl.bind("left", left, { repeating = true })
    hl.bind("down", down, { repeating = true })
    hl.bind("up", up, { repeating = true })
    hl.bind("right", right, { repeating = true })

    hl.bind("Escape", hl.dsp.submap("reset"))
    hl.bind(mod .. " + R", hl.dsp.submap("reset"))
    hl.bind("catchall", hl.dsp.submap("reset"))
end)
hl.bind(mod .. " + R", hl.dsp.submap("resize"))
-- -------------------------
-- Workspaces
-- -------------------------
if not s.is_laptop then
    hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1" })
    hl.workspace_rule({ workspace = "2", monitor = "DP-2" })
end

for i = 1, 10 do
    local bi = i % 10 -- 0 becomes worspace 10
    hl.bind(mod .. " + " .. bi, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. bi, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- -- Scroll through workspaces on current monitor
-- hl.bind(mod .. " + Prior", hl.dsp.workspace("r+1"))
-- hl.bind(mod .. " + Next", hl.workspace("r-1"))
-- hl.bind(mod .. " + SHIFT + Prior", hl.dsp.window.move({ workspace = "r-1" }))
-- hl.bind(mod .. " + SHIFT + Next", hl.dsp.window.move({ workspace = "r+1" }))
-- hl.bind(mod .. " + mouse_down", hl.workspace("e+1"))
-- hl.bind(mod .. " + mouse_up", hl.workspace("e-1"))

-- Special workspace (scratchpad)
-- hl.bind(mod .. " + S", hl.workspace({ special = "magic" }))
-- hl.bind(mod .. " + CTRL + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- -------------------------
-- Monitor focus / window move (desktop only)
-- -------------------------
if not s.is_laptop then
    hl.bind("ALT + 1", hl.dsp.focus({ monitor = "HDMI-A-1" }))
    hl.bind("ALT + 2", hl.dsp.focus({ monitor = "DP-2" }))

    local function moveWindowToMonitor(monitorName)
        for _, mon in ipairs(hl.get_monitors()) do
            if mon.name == monitorName then
                local ws = mon.active_workspace
                if ws then
                    hl.dsp.window.move({})()
                end
                return
            end
        end
    end

    hl.bind("ALT + SHIFT + 1", function()
        moveWindowToMonitor("HDMI-A-1")
    end)
    hl.bind("ALT + SHIFT + 2", function()
        moveWindowToMonitor("DP-2")
    end)
end

-- XF86 keys currently bound:
-- XF86AudioRaiseVolume, XF86AudioLowerVolume, XF86AudioMute
-- XF86AudioMicMute, XF86AudioNext, XF86AudioPause, XF86AudioPlay
-- XF86AudioPrev, XF86MonBrightnessUp, XF86MonBrightnessDown
-- XF86Launch1 (Noctalia settings)
--
-- To find key codes: run `wev` or `libinput debug-events` in terminal
--
-- -------------------------
-- Media & function keys
-- -------------------------
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind(mod .. " + SHIFT + A", function()
    hlc.animations.enabled = not hlc.animations.enabled
    hlc.notify("animations: " .. (hlc.animations.enabled and "on" or "off"), 1500)
end)

hl.bind(mod .. " + SHIFT + R", function()
    local cur = hlc.decoration.rounding
    hlc.decoration.rounding = cur == 0 and 8 or 0
    hlc.notify("rounding: " .. hlc.decoration.rounding, 1500)
end)

hl.bind(mod .. " + SHIFT + B", function()
    hlc.decoration.blur.enabled = not hlc.decoration.blur.enabled
    hlc.notify("blur: " .. (hlc.decoration.blur.enabled and "on" or "off"), 1500)
end)

hl.bind(mod .. " + SHIFT + D", function()
    local on = hlc.decoration.inactive_opacity < 1.0
    hlc.decoration.inactive_opacity = on and 1.0 or 0.8
    hlc.notify("dim: " .. (on and "off" or "on"), 1500)
end)

hl.bind(mod .. " + SHIFT + T", tilt_mode)

hl.bind("ALT+TAB", hl.dsp.window.cycle_next())
--
-- hlc.input.touchpad.tap_to_click = false
-- hlc.input.touchpad.tap_and_drag = false

hl.bind(mod .. "+ x", function()
    local tcc = hlc.input.touchpad.tap_to_click
    hlc.input.touchpad.tap_to_click = not hlc.input.touchpad.tap_to_click
    hlc.notify("TTC = " .. tostring(tcc))
end)


