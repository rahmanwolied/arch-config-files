#!/bin/bash
# Script to close a window and track it for reopening

# Enable debug mode by setting: DEBUG=1
DEBUG=${DEBUG:-0}
DEBUG_LOG="/tmp/hypr_close_debug.log"

# Get the active window info
ACTIVE_WINDOW=$(hyprctl activewindow -j)
WINDOW_CLASS=$(echo "$ACTIVE_WINDOW" | jq -r '.class')
WINDOW_TITLE=$(echo "$ACTIVE_WINDOW" | jq -r '.title')
INITIAL_CLASS=$(echo "$ACTIVE_WINDOW" | jq -r '.initialClass')

# Debug logging
if [[ "$DEBUG" == "1" ]]; then
    echo "=== $(date) ===" >> "$DEBUG_LOG"
    echo "Full window info:" >> "$DEBUG_LOG"
    echo "$ACTIVE_WINDOW" | jq '.' >> "$DEBUG_LOG"
    echo "" >> "$DEBUG_LOG"
    echo "Parsed values:" >> "$DEBUG_LOG"
    echo "  WINDOW_CLASS: $WINDOW_CLASS" >> "$DEBUG_LOG"
    echo "  WINDOW_TITLE: $WINDOW_TITLE" >> "$DEBUG_LOG"
    echo "  INITIAL_CLASS: $INITIAL_CLASS" >> "$DEBUG_LOG"
    echo "" >> "$DEBUG_LOG"
fi

# Try to determine the executable/command
if [[ "$WINDOW_CLASS" == "Cursor" ]]; then
    CMD="/opt/cursor.appimage"
elif [[ "$WINDOW_CLASS" == "spotify" ]]; then
    CMD="spotify"
elif [[ "$WINDOW_CLASS" == "signal" ]]; then
    CMD="signal-desktop"
elif [[ "$WINDOW_CLASS" == "obsidian" ]]; then
    CMD="obsidian"
elif [[ "$WINDOW_CLASS" == "nautilus" ]]; then
    CMD="nautilus"
elif [[ "$WINDOW_CLASS" =~ ^Alacritty|kitty|foot$ ]]; then
    CMD="$TERMINAL"
elif [[ "$WINDOW_CLASS" == "chromium" ]] || [[ "$WINDOW_CLASS" == "chromium-browser" ]]; then
    # Regular Chromium browser window (not a web app)
    CMD="omarchy-launch-browser"
elif [[ "$WINDOW_CLASS" =~ ^chrome- ]]; then
    # Handle Chrome/Chromium web apps - they have pattern: chrome-DOMAIN__-Default
    # Match based on actual class patterns from debug output
    case "$WINDOW_CLASS" in
        *"chatgpt.com"*)
            CMD='omarchy-launch-or-focus-webapp ChatGPT "https://chatgpt.com"'
            ;;
        *"web.whatsapp.com"*)
            CMD='omarchy-launch-or-focus-webapp WhatsApp "https://web.whatsapp.com/"'
            ;;
        *"youtube.com"*)
            CMD='omarchy-launch-or-focus-webapp YouTube "https://youtube.com/"'
            ;;
        *"claude.com"*)
            CMD='omarchy-launch-or-focus-webapp Claude "https://claude.com"'
            ;;
        *"mail.google.com"*)
            CMD='omarchy-launch-or-focus-webapp Email "https://mail.google.com/mail"'
            ;;
        *"x.com"*|*"twitter.com"*)
            CMD='omarchy-launch-or-focus-webapp X "https://x.com/"'
            ;;
        *"messages.google.com"*)
            CMD='omarchy-launch-or-focus-webapp "Google Messages" "https://messages.google.com/web/conversations"'
            ;;
        *)
            # Unknown chrome web app, just launch browser
            CMD="omarchy-launch-browser"
            ;;
    esac

else
    # Fallback: try to get the command from the window PID
    WINDOW_PID=$(echo "$ACTIVE_WINDOW" | jq -r '.pid')
    CMD=$(ps -p "$WINDOW_PID" -o comm= 2>/dev/null || echo "")
fi

# Save the command to a temp file
if [[ -n "$CMD" ]]; then
    echo "$CMD" > /tmp/hypr_last_closed_window
    
    # Debug logging
    if [[ "$DEBUG" == "1" ]]; then
        echo "Saved command: $CMD" >> "$DEBUG_LOG"
        echo "==================" >> "$DEBUG_LOG"
        echo "" >> "$DEBUG_LOG"
    fi
fi

# Close the window
hyprctl dispatch killactive

