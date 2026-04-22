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

hl.on("hyprland.start", function()
    hl.dsp.exec_cmd("vicinae server")()
    hl.dsp.exec_cmd("qs -c noctalia-shell")()
    hl.dsp.exec_cmd("foot --server")()
    hl.dsp.exec_cmd("awww-daemon & waypaper --restore")()
    hl.dsp.exec_cmd("hypridle")()
    hl.dsp.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")()
end)
-- hl.dsp.exec_cmd("vicinae server")
-- hl.dsp.exec_cmd("qs -c noctalia-shell")
-- hl.dsp.exec_cmd("foot --server")
-- hl.dsp.exec_cmd("awww-daemon & waypaper --restore")
-- hl.dsp.exec_cmd("hypridle")
-- hl.dsp.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")


