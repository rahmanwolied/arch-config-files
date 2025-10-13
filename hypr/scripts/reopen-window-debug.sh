#!/bin/bash
# Debug script to reopen last closed window with logging

DEBUG_LOG="/tmp/hypr_reopen_debug.log"
CMD_FILE="/tmp/hypr_last_closed_window"

echo "=== $(date) ===" >> "$DEBUG_LOG"

# Check if the file exists
if [[ ! -f "$CMD_FILE" ]]; then
    echo "ERROR: No window command file found at $CMD_FILE" >> "$DEBUG_LOG"
    notify-send "No window to restore" "No previously closed window found"
    exit 1
fi

# Read the command
CMD=$(cat "$CMD_FILE" 2>/dev/null)

if [[ -z "$CMD" ]]; then
    echo "ERROR: Command file is empty" >> "$DEBUG_LOG"
    notify-send "No window to restore" "Command file is empty"
    exit 1
fi

# Log what we're about to execute
echo "Command to execute: $CMD" >> "$DEBUG_LOG"
echo "Command length: ${#CMD} characters" >> "$DEBUG_LOG"
echo "" >> "$DEBUG_LOG"

# Show notification with the command (for immediate visual feedback)
notify-send "Reopening Window" "Executing: $CMD"

# Execute the command
echo "Executing command..." >> "$DEBUG_LOG"
eval "$CMD" 2>&1 | tee -a "$DEBUG_LOG"
EXIT_CODE=$?

echo "Exit code: $EXIT_CODE" >> "$DEBUG_LOG"
echo "==================" >> "$DEBUG_LOG"
echo "" >> "$DEBUG_LOG"

if [[ $EXIT_CODE -ne 0 ]]; then
    notify-send "Error reopening window" "Command failed with exit code $EXIT_CODE"
fi



