local hlc = require("hlc")
local s = require("settings")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "")
-- libadwaita dark mode: bypass XDG portal and read color-scheme directly
-- from gsettings (set to prefer-dark via exec_once below)
hl.env("ADW_DISABLE_PORTAL", "1")

hl.permission({ binary = "/usr/(bin|local/bin)/grim", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/(lib|libexec|lib65)/xdg-desktop-portal-hyprland", type = "screencopy", mode = "allow" })

hl.on("hyprland.start", function()
    hlc.d.exec_cmd("hyprlock")
    hlc.d.exec_cmd("vicinae server")
    hlc.d.exec_cmd("qs -c noctalia-shell")
    hlc.d.exec_cmd("awww-daemon & waypaper --restore")
    hlc.d.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
end)


