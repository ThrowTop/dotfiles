-- Full config still lives in hyprland.conf (used by stable session)

local mainMod  = "SUPER"
local terminal = "foot"
local browser  = "brave"
local hscripts = os.getenv("HOME") .. "/.config/hypr/scripts"


local is_laptop = io.open("/sys/class/power_supply/BAT1") ~= nil

local debug = true


local function d(str)
    if debug then
        hl.exec_cmd(string.format("notify-send %q", str))
    end
end
d("hyprland lua loaded")


-- -------------------------
-- MONITORS
-- -------------------------
if is_laptop then
    hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
else
    hl.monitor({ output = "DP-2", mode = "1920x1080@240", position = "0x0", scale = 1 })
    hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "-1920x0", scale = 1 })
end

-- -------------------------
-- ENVIRONMENT VARIABLES
-- -------------------------
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("QT_QPA_PLATFORMTHEME", "hyprland")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- -------------------------
-- PERMISSIONS
-- -------------------------
hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")

-- -------------------------
-- AUTOSTART
-- -------------------------
hl.exec_once("vicinae server")
hl.exec_once("qs -c noctalia-shell")
hl.exec_once("foot --server")
hl.exec_once("hyprpaper & waypaper --restore")
hl.exec_once("hypridle")
hl.exec_once("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
-- -------------------------
-- LOOK AND FEEL
-- -------------------------
hl.config({
    general = {
        gaps_in          = 4,
        gaps_out         = 8,
        border_size      = 2,
        col              = {
            active_border   = { colors = { "rgb(F604F8)", "rgb(2F0065)", angle = 45 } },
            inactive_border = { colors = { "rgb(303030)", "rgb(B4BEFE)", angle = 35 } },
        },
        layout           = "dwindle",
        resize_on_border = false,
        resize_corner    = 3,
    },
})

hl.config({
    decoration = {
        rounding              = 12,
        rounding_power        = 2,
        active_opacity        = 1.0,
        inactive_opacity      = 0.9,
        border_part_of_window = true,
        shadow                = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },
        blur                  = {
            enabled           = true,
            size              = 16,
            passes            = 2,
            ignore_opacity    = true,
            new_optimizations = true,
            xray              = false,
            noise             = 0.0117,
            contrast          = 0.8916,
            brightness        = 0.8172,
            vibrancy          = 0.1696,
            popups            = false,
        },
    },
})
hl.config({
    animations = { enabled = true },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

hl.config({
    dwindle = { pseudotile = true, preserve_split = true },
    master  = { new_status = "master" },
    misc    = { force_default_wallpaper = 0, disable_hyprland_logo = true },
})

-- -------------------------
-- INPUT
-- -------------------------
hl.config({
    input = {
        kb_layout          = "us,se",
        kb_options         = "grp:win_space_toggle",
        numlock_by_default = true,
        mouse_refocus      = false,
        follow_mouse       = 1,
        sensitivity        = -0.3,
        accel_profile      = "flat",
        scroll_method      = "on_button_down",
        scroll_button      = 274,
        scroll_button_lock = false,

        touchpad           = {
            natural_scroll       = true,
            drag_lock            = false,
            disable_while_typing = true,
            scroll_factor        = 0.5,
        },
    },
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- hl.device({
--     name                 = "znt0001:00-14e5:650e-touchpad",
--     sensitivity          = 0.3,
--     disable_while_typing = false,
-- })

-- -------------------------
-- KEYBINDINGS
-- -------------------------

-- Applications
hl.bind(mainMod .. " + Return", hl.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.exec_cmd("thunar"))
hl.bind(mainMod .. " + B", hl.exec_cmd(browser))
hl.bind("ALT + Space", hl.exec_cmd("vicinae toggle"))
hl.bind(mainMod .. " + V", hl.exec_cmd("vicinae vicinae://launch/clipboard/history"))
hl.bind("Print", hl.exec_cmd(hscripts .. "/screenshot.sh"))
hl.bind(mainMod .. " + Print", hl.exec_cmd("hyprpicker | wl-copy"))
hl.bind(mainMod .. " + T", hl.exec_cmd(hscripts .. "/touchscreen.sh"))
hl.bind(mainMod .. " + SHIFT + U", hl.exec_cmd("pkill qs; qs -c noctalia-shell"))
hl.bind(mainMod .. " + M", hl.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.exit()'"))

hl.exec_cmd("notify-send test")

-- Noctalia
local ipc = "qs -c noctalia-shell ipc call"
hl.bind("XF86Launch1", hl.exec_cmd(ipc .. " settings open"))
hl.bind(mainMod .. " + F1", hl.exec_cmd(ipc .. " settings open"))

-- Window management
hl.bind(mainMod .. " + Q", hl.window.close())
hl.bind(mainMod .. " + C", hl.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.window.fullscreen_state({ internal = 2, client = 0 }))
hl.bind(mainMod .. " + SHIFT + F", hl.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + P", hl.window.pseudo())

-- Focus (hjkl)
hl.bind(mainMod .. " + H", hl.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.focus({ direction = "right" }))

-- Move windows (hjkl)
hl.bind(mainMod .. " + SHIFT + H", hl.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J", hl.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + K", hl.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + L", hl.window.move({ direction = "right" }))


if not is_laptop then
    hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1" })
    hl.workspace_rule({ workspace = "2", monitor = "DP-2" })
end

for i = 1, 10 do
    local bi = i % 10
    hl.bind(mainMod .. " + " .. bi, hl.workspace(i))
    hl.bind(mainMod .. " + SHIFT + " .. bi, hl.window.move({ workspace = tostring(i) }))
end


-- Scroll through workspaces on current monitor
hl.bind(mainMod .. " + Prior", hl.workspace("r+1"))
hl.bind(mainMod .. " + Next", hl.workspace("r-1"))
hl.bind(mainMod .. " + SHIFT + Prior", hl.window.move({ workspace = "r-1" }))
hl.bind(mainMod .. " + SHIFT + Next", hl.window.move({ workspace = "r+1" }))

-- Monitor focus (left = HDMI-A-1, right/main = DP-2)
hl.bind("ALT + 1", hl.focus({ monitor = "HDMI-A-1" }))
hl.bind("ALT + 2", hl.focus({ monitor = "DP-2" }))

-- Move active window to a monitor's current workspace
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

hl.bind(mainMod .. " + mouse_down", hl.workspace("e+1"))
hl.bind(mainMod .. " + mouse_up", hl.workspace("e-1"))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.workspace({ special = "magic" }))
hl.bind(mainMod .. " + CTRL + S", hl.window.move({ workspace = "special:magic" }))

-- Mouse: drag / resize
hl.bind(mainMod .. " + mouse:272", hl.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.window.resize(), { mouse = true })

-- Media & function keys
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

-- -------------------------
-- LAYER RULES
-- -------------------------
hl.layer_rule({
    name         = "vicinae-blur",
    match        = { namespace = "vicinae" },
    blur         = true,
    ignore_alpha = 0,
})

hl.layer_rule({
    name = "vicinae-no-animation",
    match = { namespace = "vicinae" },
    no_anim = true,
})

-- -------------------------
-- WINDOW RULES
-- -------------------------
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name     = "fix-xwayland-drags",
    match    = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    float = true,
    move  = "20 monitor_h-120",
})

hl.window_rule({
    name      = "bitwarden-scratchpad",
    match     = { class = "^(Bitwarden)$" },
    float     = true,
    size      = "400 600",
    move      = "100%-420 40",
    workspace = "special:bitwarden silent",
})

hl.window_rule({
    name      = "satty-instant",
    match     = { class = "^(satty|com%.gabm%.satty)$" },
    float     = true,
    no_anim   = true,
    no_blur   = true,
    no_shadow = true,
    rounding  = 0,
})

hl.window_rule({
    name   = "thunar-float",
    match  = { class = "^(thunar|Thunar)$", title = "^(File Operation Progress).*$" },
    float  = true,
    size   = "600 300",
    center = true,
})

hl.window_rule({
    name              = "pip-float",
    match             = { title = "^(Picture-in-Picture)$" },
    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
    size              = "640 360",
    move              = "100%-660 100%-380",
})

hl.window_rule({
    match     = { class = "^(rustdesk)$" },
    workspace = "9 silent",
})

hl.window_rule({
    name  = "steam-float",
    match = { class = "^(steam)$", title = "^(Steam Settings|Friends List).*$" },
    float = true,
})

hl.window_rule({
    name   = "pavucontrol-float",
    match  = { class = "^(pavucontrol)$" },
    float  = true,
    size   = "800 500",
    center = true,
})

hl.window_rule({
    name   = "calculator-float",
    match  = { class = "^(gnome-calculator|qalculate-gtk|speedcrunch)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name     = "screenshare-indicator",
    match    = { title = "^(Firefox — Sharing Indicator|.*Sharing Indicator.*)$" },
    float    = true,
    move     = "0 0",
    pin      = true,
    no_focus = true,
})
