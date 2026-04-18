local s = require("settings")

-- Environment variables
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- libadwaita dark mode: bypass XDG portal (not available on Hyprland) and
-- read color-scheme directly from gsettings (set to prefer-dark via exec_once)
hl.env("ADW_DISABLE_PORTAL", "1")
-- Permissions
hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")

-- Autostart (run once on first launch)
hl.exec_once("vicinae server")
hl.exec_once("qs -c noctalia-shell")
hl.exec_once("foot --server")
hl.exec_once("awww-daemon & waypaper --restore")
hl.exec_once("hypridle")
hl.exec_once("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
