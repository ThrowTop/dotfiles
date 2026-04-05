#!/bin/bash
# Region screenshot → annotate in satty → copy to clipboard
# Keybinds: Super+Shift+S, Print

grim -t ppm - | satty \
    -f - \
    --fullscreen \
    --initial-tool crop \
    --copy-command wl-copy \
    --early-exit \
    --actions-on-enter save-to-clipboard
