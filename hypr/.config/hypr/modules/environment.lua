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

hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

hl.on("hyprland.start", function()
    -- hl.exec_cmd("hyprlock")
    hl.exec_cmd("bash -c 'sleep 0.5; exec hyprlock'")
    hl.exec_cmd("vicinae server")
    hl.exec_cmd("wl-clip-persist --selection both")
    hl.exec_cmd("swaync")
    hl.exec_cmd("bash " .. settings.qs .. "/launch.sh")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
    hl.exec_cmd("bash -c 'echo i2c-GXTP7936:00 | sudo tee /sys/bus/i2c/drivers/i2c_hid_acpi/unbind > /dev/null 2>&1'")
end)


