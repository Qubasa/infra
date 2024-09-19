#!/usr/bin/env bash

set -eox pipefail

# Check for the correct number of arguments
if [[ "$#" -ne 3 ]]; then
    echo "Usage: $0 <dark_mode_folder> <light_mode_folder> <dipc_enabled>"
    echo " - <dark_mode_folder>: Path to the directory with dark mode wallpapers"
    echo " - <light_mode_folder>: Path to the directory with light mode wallpapers"
    echo " - <dipc_enabled>: 'true' to enable dipc processing, 'false' to disable"
    exit 1
fi

# Assign arguments to variables
DARK_WALLPAPER_DIR="$1"
LIGHT_WALLPAPER_DIR="$2"
DIPC_ENABLED="$3"

# Command to check GNOME mode
MODE=$(gsettings get org.gnome.desktop.interface color-scheme)

# Set default palettes if not set externally
DARK_PALETTE="${DARK_PALETTE:-dracula}"
LIGHT_PALETTE="${LIGHT_PALETTE:-solarized}"

# Function to set wallpapers
set_wallpaper() {
    local palette="$1"
    local wallpaper_dir="$2"
    local output_file="$3"
    local uri_setting="$4"

    # Pick a random wallpaper from the directory
    local wallpaper=$(find "$wallpaper_dir" -type f \( -iname '*.jpg' -o -iname '*.png' \) | shuf -n 1)

    if [[ "$DIPC_ENABLED" == "true" ]]; then
        # Process the wallpaper with dipc
        dipc "$palette" "$wallpaper" -o "$output_file"
    else
        # Directly copy the file if dipc is disabled
        cp "$wallpaper" "$output_file"
    fi

    # Set the wallpaper
    gsettings set org.gnome.desktop.background "$uri_setting" "file://$output_file"
}

if [[ "$MODE" == "'prefer-dark'" ]]; then
    PALETTE="$DARK_PALETTE"
    OUTPUT_FILE="/tmp/dark_wallpaper.png"
    URI_SETTING="picture-uri-dark"
    echo "Setting dark mode wallpaper with palette $PALETTE..."

    set_wallpaper "$PALETTE" "$DARK_WALLPAPER_DIR" "$OUTPUT_FILE" "$URI_SETTING"
else
    PALETTE="$LIGHT_PALETTE"
    OUTPUT_FILE="/tmp/light_wallpaper.png"
    URI_SETTING="picture-uri"
    echo "Setting light mode wallpaper with palette $PALETTE..."

    set_wallpaper "$PALETTE" "$LIGHT_WALLPAPER_DIR" "$OUTPUT_FILE" "$URI_SETTING"
fi

echo "Wallpaper updated successfully."
