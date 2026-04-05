#!/bin/bash
# touchscreen.sh - Toggle touchscreen on/off via sysfs bind/unbind
# Usage: touchscreen.sh [on|off]   (no arg = toggle)

DEVICE="i2c-GXTP7936:00"
DRIVER="/sys/bus/i2c/drivers/i2c_hid_acpi"

is_enabled() {
    [ -e "$DRIVER/$DEVICE" ]
}

enable() {
    echo "$DEVICE" | sudo tee "$DRIVER/bind" > /dev/null
    notify-send "Touchscreen" "Touchscreen on"
}

disable() {
    echo "$DEVICE" | sudo tee "$DRIVER/unbind" > /dev/null
    notify-send "Touchscreen" "Touchscreen off"
}

case "$1" in
    on)
        is_enabled || enable
        ;;
    off)
        is_enabled && disable
        ;;
    "")
        if is_enabled; then
            disable
        else
            enable
        fi
        ;;
    *)
        echo "Usage: $0 [on|off]"
        exit 1
        ;;
esac
