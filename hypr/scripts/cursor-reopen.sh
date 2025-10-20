#!/usr/bin/env bash
# Reopen Cursor in the last opened folder (from Cursor's recent list)

set -euo pipefail

CURSOR_BIN="${1:-/opt/cursor.appimage}"  # you pass "$cursor" from your hyprland conf
DB="${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User/globalStorage/state.vscdb"
STORAGE_JSON="${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User/globalStorage/storage.json"

need() { command -v "$1" >/dev/null 2>&1 || { notify-send "cursor-reopen" "Missing dependency: $1"; exit 1; }; }
need sqlite3
need jq

# Try to extract most-recent folder from the SQLite DB (Cursor/VSCode global state)
from_vscdb() {
  [[ -f "$DB" ]] || return 1
  sqlite3 -readonly "$DB" \
    "SELECT value FROM ItemTable WHERE key='history.recentlyOpenedPathsList'" 2>/dev/null \
    | jq -r '
      try (
        .entries
        | map( .folderUri // (.fileUri | sub("/[^/]+$"; "")) )
        | map( sub("^file://"; "") )
        | map( sub("^path://"; "") )
        | map( sub("^vscode-remote://[^/]+@"; "") )
        | .[0]
      ) catch empty
    '
}

# Fallback for older installs that still use a JSON file
from_storage_json() {
  [[ -f "$STORAGE_JSON" ]] || return 1
  jq -r '
    ( .["history.recentlyOpenedPathsList"].entries // .openedPathsList.entries // .openedPathsList )
    | map( .folderUri // (.fileUri | sub("/[^/]+$"; "")) )
    | map( sub("^file://"; "") )
    | .[0]
  ' "$STORAGE_JSON"
}

DIR="$(from_vscdb || true)"
[[ -z "${DIR:-}" ]] && DIR="$(from_storage_json || true)"

# Final sanity check
if [[ -z "${DIR:-}" || ! -d "$DIR" ]]; then
  notify-send "Cursor reopen" "Couldn't find a recent folder; opening default Cursor"
  exec uwsm app -- "$CURSOR_BIN"
else
  exec uwsm app -- "$CURSOR_BIN" "$DIR"
fi
