local screenshot = require("helpers/screenshot")
local tilt_mode = require("helpers/tilt_mode")
local touchscreen = require("helpers/touchscreen")
local bitwarden = require("helpers/bitwarden")
local hyprv = require("helpers/hyprv")

local battery_saver_enabled = false

local function set_battery_saver(enabled)
    battery_saver_enabled = enabled
    hlc.animations.enabled = not enabled
    hlc.decoration.blur.enabled = not enabled
    hlc.decoration.inactive_opacity = enabled and 1.0 or 0.9
    hyprv.set_state("batterySaver", enabled)
    hyprv.osd("Battery Saver", enabled and "On" or "Off", enabled and "#f9e2af" or "#a6e3a1", "0xF06C0")
end

_G.hypr = {
    tilt_mode = tilt_mode,
    touchscreen = touchscreen,
    battery_saver = function(state)
        if state == "on" then
            set_battery_saver(true)
        elseif state == "off" then
            set_battery_saver(false)
        else
            set_battery_saver(not battery_saver_enabled)
        end
    end,
    tap_to_click = function()
        hlc.input.touchpad.tap_to_click = not hlc.input.touchpad.tap_to_click
        local tcc = hlc.input.touchpad.tap_to_click
        hyprv.osd("Tap Click", tcc and "On" or "Off", tcc and "#a6e3a1" or "#f38ba8", "0xF052F")
        hyprv.toggle_state("tapToClick")
    end,
    push_state = function()
        local ts = io.open("/sys/bus/i2c/drivers/i2c_hid_acpi/i2c-GXTP7936:00") ~= nil
        hyprv.set_state("touchscreen", ts)
        local f = io.popen("lsmod | grep -c '^intel_hid'")
        local tilt = false
        if f then
            local n = tonumber(f:read("*l") or "0")
            f:close()
            tilt = (n or 0) == 0
        end
        hyprv.set_state("tiltMode", tilt)
        hyprv.set_state("tapToClick", hlc.input.touchpad.tap_to_click)
    end,
}
local mod = settings.main_mod
local qs_scripts = settings.qs

-- -------------------------
-- Applications
-- -------------------------
hl.bind(mod .. "Return", hl.dsp.exec_cmd(settings.terminal))
hl.bind(mod .. "E", hl.dsp.exec_cmd(settings.file_manager))
hl.bind(mod .. "B", hl.dsp.exec_cmd(settings.browser))
hl.bind("ALT + Space", hl.dsp.exec_cmd("vicinae toggle"))
hl.bind(mod .. "V", hl.dsp.exec_cmd("vicinae vicinae://launch/clipboard/history"))
hl.bind("Print", screenshot)
hl.bind(mod .. "Print", hl.dsp.exec_cmd("hyprpicker | wl-copy"))
hl.bind(mod .. "F5", touchscreen)
hl.bind("CTRL + SUPER + XF86TouchpadToggle", touchscreen)
hl.bind(mod .. "SHIFT + U", hl.dsp.exec_cmd("bash " .. qs_scripts .. "/reload.sh"))
hl.bind(mod .. "M", hl.dsp.exit())
hl.bind(mod .. "L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock --immediate-render"))

hl.bind(mod .. "P", bitwarden)

-- -------------------------
-- Window management
-- -------------------------
hl.bind(mod .. "Q", hl.dsp.window.close())
hl.bind(mod .. "C", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. "F", hl.dsp.window.fullscreen_state({ internal = 2, client = 0, action = "toggle" }))
hl.bind(mod .. "SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mod .. "SHIFT + P", hl.dsp.window.pseudo())

-- Focus (arrow keys)
hl.bind(mod .. "left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. "down", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. "up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. "right", hl.dsp.focus({ direction = "right" }))

-- Move windows (arrow keys)
hl.bind(mod .. "SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. "SHIFT + down", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. "SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. "SHIFT + right", hl.dsp.window.move({ direction = "right" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mod .. "mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

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

-- Resize submap (SUPER+R → arrow keys to resize, Escape to exit)
hl.define_submap("resize", function()
    local left = hl.dsp.window.resize({ x = -30, y = 0, relative = true })
    local down = hl.dsp.window.resize({ x = 0, y = 30, relative = true })
    local up = hl.dsp.window.resize({ x = 0, y = -30, relative = true })
    local right = hl.dsp.window.resize({ x = 30, y = 0, relative = true })

    hl.bind("left", left, { repeating = true })
    hl.bind("down", down, { repeating = true })
    hl.bind("up", up, { repeating = true })
    hl.bind("right", right, { repeating = true })

    hl.bind("Escape", hl.dsp.submap("reset"))
    hl.bind("catchall", hl.dsp.submap("reset"))
end)
hl.bind(mod .. "R", hl.dsp.submap("resize"))
-- -------------------------
-- Workspaces
-- -------------------------
if not settings.is_laptop then
    hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1" })
    hl.workspace_rule({ workspace = "2", monitor = "DP-2" })
end

local numpad_key = { "KP_End", "KP_Down", "KP_Next", "KP_Left", "KP_Begin", "KP_Right", "KP_Home", "KP_Up", "KP_Prior", "KP_Insert" }

for i = 1, 10 do
    local mod_i = i % 10
    hl.bind(mod .. mod_i, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. "SHIFT + " .. mod_i, hl.dsp.window.move({ workspace = tostring(i) }))

    hl.bind(mod .. numpad_key[i], hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. "SHIFT + " .. numpad_key[i], hl.dsp.window.move({ workspace = tostring(i) }))
end

-- -- Scroll through workspaces on current monitor
-- hl.bind(mod .. "Prior", hl.dsp.workspace("r+1"))
-- hl.bind(mod .. "Next", hl.workspace("r-1"))
-- hl.bind(mod .. "SHIFT + Prior", hl.dsp.window.move({ workspace = "r-1" }))
-- hl.bind(mod .. "SHIFT + Next", hl.dsp.window.move({ workspace = "r+1" }))
-- hl.bind(mod .. "mouse_down", hl.workspace("e+1"))
-- hl.bind(mod .. "mouse_up", hl.workspace("e-1"))

-- Special workspace (scratchpad)
-- hl.bind(mod .. "S", hl.workspace({ special = "magic" }))
-- hl.bind(mod .. "CTRL + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- -------------------------
-- Monitor focus / window move (desktop only)
-- -------------------------
if not settings.is_laptop then
    hl.bind("ALT + 1", hl.dsp.focus({ monitor = "HDMI-A-1" }))
    hl.bind("ALT + 2", hl.dsp.focus({ monitor = "DP-2" }))

    local function moveWindowToMonitor(monitorName)
        for _, mon in ipairs(hl.get_monitors()) do
            if mon.name == monitorName then
                local ws = mon.active_workspace
                if ws then
                    hlc.d.window.move({})
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
--
-- To find key codes: run `wev` or `libinput debug-events` in terminal
--
-- -------------------------
-- Media & function keys
-- -------------------------
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("loginctl lock-session"), { locked = true })

hl.bind("XF86AudioRaiseVolume", hyprv.control_volume_inc, { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hyprv.control_volume_dec, { locked = true, repeating = true })
hl.bind("XF86AudioMute", hyprv.control_volume_toggle, { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hyprv.control_brightness_inc, { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hyprv.control_brightness_dec, { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- hl.bind(mod .. "SHIFT + A", function()
--     hlc.animations.enabled = not hlc.animations.enabled
--     hlc.notify("animations: " .. (hlc.animations.enabled and "on" or "off"), 1500)
-- end)
--
-- hl.bind(mod .. "SHIFT + R", function()
--     local cur = hlc.decoration.rounding
--     hlc.decoration.rounding = cur == 0 and 19 or 0
--     hlc.notify("rounding: " .. hlc.decoration.rounding, 1500)
-- end)
--
-- hl.bind(mod .. "SHIFT + B", function()
--     hlc.decoration.blur.enabled = not hlc.decoration.blur.enabled
--     hlc.notify("blur: " .. (hlc.decoration.blur.enabled and "on" or "off"), 1500)
-- end)

hl.bind(mod .. "SHIFT + D", function()
    local on = hlc.decoration.inactive_opacity < 1.0
    hlc.decoration.inactive_opacity = on and 1.0 or 0.8
    hlc.notify("dim: " .. (on and "off" or "on"), 1500)
end)

hl.bind(mod .. "SHIFT + S", hypr.battery_saver)
hl.bind(mod .. "SHIFT + T", tilt_mode)

hl.bind("ALT+TAB", hl.dsp.window.cycle_next())
--
-- hlc.input.touchpad.tap_to_click = false
-- hlc.input.touchpad.tap_and_drag = false

hl.bind(mod .. "X", hypr.tap_to_click)


