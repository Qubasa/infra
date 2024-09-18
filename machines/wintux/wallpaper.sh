#!/usr/bin/env bash

set -eoip

#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Command to check GNOME mode
MODE=$(gsettings get org.gnome.desktop.interface color-scheme)

# Select a theme based on GNOME mode
if [[ "$MODE" == "'prefer-dark'" ]]; then
    PALETTE="dracula"
    # Pick a random wallpaper from the directory for dark mode
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' \) | shuf -n 1)
    # Process the wallpaper with dipc for dark mode
    dipc "$PALETTE" "$WALLPAPER" -o /tmp/dark_wallpaper.png
    # Set the processed wallpaper for dark mode
    gsettings set org.gnome.desktop.background picture-uri-dark "file:///tmp/dark_wallpaper.png"
    
    echo "Dark mode wallpaper set with $PALETTE theme."

else
    PALETTE="solarized"
    # Pick a random wallpaper from the directory for light mode
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' \) | shuf -n 1)
    # Process the wallpaper with dipc for light mode
    dipc "$PALETTE" "$WALLPAPER" -o /tmp/light_wallpaper.png
    # Set the processed wallpaper for light mode
    gsettings set org.gnome.desktop.background picture-uri "file:///tmp/light_wallpaper.png"
    
    echo "Light mode wallpaper set with $PALETTE theme."
fi
