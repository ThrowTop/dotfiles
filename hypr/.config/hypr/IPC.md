# Hyprland IPC — Lua config external interface

The `hypr` global table exposes config actions callable from outside Hyprland
via `hyprctl eval`.

## Usage

```sh
hyprctl eval 'hypr.<action>()'
```

## Actions

| Call | Effect |
|------|--------|
| `hypr.tilt_mode()` | Toggle intel_hid (tablet/tilt mode), keeps keyboard backlight level |
| `hypr.touchscreen()` | Toggle touchscreen (i2c bind/unbind) |
| `hypr.touchscreen('on')` | Force touchscreen on |
| `hypr.touchscreen('off')` | Force touchscreen off |
| `hypr.tap_to_click()` | Toggle touchpad tap-to-click |

## Examples

```sh
# Toggle tilt mode
hyprctl eval 'hypr.tilt_mode()'

# Toggle touchscreen
hyprctl eval 'hypr.touchscreen()'

# Force touchscreen on
hyprctl eval 'hypr.touchscreen("on")'

# Toggle tap-to-click
hyprctl eval 'hypr.tap_to_click()'
```

## Adding actions

Actions are defined in `modules/keybindings.lua` in the `hypr` table.
`hlc` and `hyprv` are available (globals).

```lua
hypr = {
    my_action = function()
        -- hlc.*, hyprv.osd(...), hl.*, etc.
    end,
}
```
