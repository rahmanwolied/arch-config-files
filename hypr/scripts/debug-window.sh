#!/bin/bash
# Debug script to inspect the active window without closing it

echo "==================================="
echo "Active Window Debug Info"
echo "==================================="
echo ""

ACTIVE_WINDOW=$(hyprctl activewindow -j)

echo "Full JSON output:"
echo "$ACTIVE_WINDOW" | jq '.'
echo ""

echo "==================================="
echo "Key Fields:"
echo "==================================="
echo "class:        $(echo "$ACTIVE_WINDOW" | jq -r '.class')"
echo "initialClass: $(echo "$ACTIVE_WINDOW" | jq -r '.initialClass')"
echo "title:        $(echo "$ACTIVE_WINDOW" | jq -r '.title')"
echo "pid:          $(echo "$ACTIVE_WINDOW" | jq -r '.pid')"
echo ""

