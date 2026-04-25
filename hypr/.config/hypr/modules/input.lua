local hlc = require("hlc")

hlc.config({
    input = {
        touchpad = {
            tap_to_click = false,
            tap_and_drag = false,
        },
    },
})

hlc.config({
    input = {
        kb_layout = "us,se",
        kb_options = "grp:win_space_toggle",
        numlock_by_default = true,
        mouse_refocus = true,
        follow_mouse = 1,
        sensitivity = -0.3,
        accel_profile = "flat",
        scroll_method = "on_button_down",
        scroll_button = 274,
        scroll_button_lock = false,
        touchpad = {
            natural_scroll = true,
            drag_lock = false,
            disable_while_typing = true,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.device({
    enabled = true,
    name = "znt0001:00-14e5:650e-touchpad",
    disable_while_typing = true,
    sensitivity = -0.3,
    -- accel_profile = "flat",
    natural_scroll = true,
    -- ["tap-to-click"] = true,
})


