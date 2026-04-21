local hlc = require("hlc")
local s = require("settings")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- libadwaita dark mode: bypass XDG portal and read color-scheme directly
-- from gsettings (set to prefer-dark via exec_once below)
hl.env("ADW_DISABLE_PORTAL", "1")

hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")

hlc.exec_once(
    "vicinae server",
    "qs -c noctalia-shell",
    "foot --server",
    "awww-daemon & waypaper --restore",
    "hypridle",
    "gsettings set org.gnome.desktop.interface color-scheme prefer-dark"
)


