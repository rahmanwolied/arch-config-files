#!/bin/bash
# View debug logs for close and reopen scripts

CLOSE_LOG="/tmp/hypr_close_debug.log"
REOPEN_LOG="/tmp/hypr_reopen_debug.log"
CMD_FILE="/tmp/hypr_last_closed_window"

echo "========================================"
echo "HYPRLAND WINDOW TRACKING DEBUG LOGS"
echo "========================================"
echo ""

echo "--- Current Saved Command ---"
if [[ -f "$CMD_FILE" ]]; then
    echo "File: $CMD_FILE"
    echo "Content: $(cat $CMD_FILE)"
else
    echo "No saved command file found"
fi
echo ""

echo "--- Close Window Debug Log (last 30 lines) ---"
if [[ -f "$CLOSE_LOG" ]]; then
    tail -n 30 "$CLOSE_LOG"
else
    echo "No close debug log found. Set DEBUG=1 to enable."
fi
echo ""

echo "--- Reopen Window Debug Log (last 20 lines) ---"
if [[ -f "$REOPEN_LOG" ]]; then
    tail -n 20 "$REOPEN_LOG"
else
    echo "No reopen debug log found yet."
fi
echo ""

echo "========================================"
echo "To watch logs in real-time, run:"
echo "  tail -f $CLOSE_LOG"
echo "  tail -f $REOPEN_LOG"
echo "========================================"



