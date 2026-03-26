#!/usr/bin/env bash
# Get the cwd of the focused shell inside the zellij session running in the focused terminal.
# Strategy: find the zellij server process, then find its most-recently-active shell child.

fallback="${HOME}"

# Get the focused window's PID from hyprctl
terminal_pid=$(hyprctl activewindow 2>/dev/null | awk '/pid:/ {print $2}')
if [[ -z "$terminal_pid" ]]; then
    echo "$fallback"
    exit 0
fi

# Find the zellij client process that is a direct child of the terminal
zellij_client_pid=$(pgrep -P "$terminal_pid" -x zellij 2>/dev/null | head -n1)
if [[ -z "$zellij_client_pid" ]]; then
    # Not a zellij terminal — fall back to the terminal's own child cwd
    shell_pid=$(pgrep -P "$terminal_pid" 2>/dev/null | head -n1)
    if [[ -n "$shell_pid" ]]; then
        cwd=$(readlink -f "/proc/$shell_pid/cwd" 2>/dev/null)
        echo "${cwd:-$fallback}"
    else
        echo "$fallback"
    fi
    exit 0
fi

# Find the zellij server process (sibling socket-server, named like "zellij --server ...")
# It's launched as a separate process by the client; find it by matching the session name
session_name=$(ZELLIJ_SESSION_NAME= cat "/proc/$zellij_client_pid/environ" 2>/dev/null \
    | tr '\0' '\n' | grep '^ZELLIJ_SESSION_NAME=' | cut -d= -f2)

if [[ -n "$session_name" ]]; then
    server_pid=$(pgrep -f "zellij --server.*${session_name}" 2>/dev/null | head -n1)
fi

if [[ -z "$server_pid" ]]; then
    # Fallback: any zellij process with "--server" flag
    server_pid=$(pgrep -f "zellij --server" 2>/dev/null | head -n1)
fi

if [[ -z "$server_pid" ]]; then
    echo "$fallback"
    exit 0
fi

# Get all direct shell children of the zellij server, pick the most recently active one
# (the one with the latest access time on its cwd symlink)
best_cwd=""
best_time=0

while IFS= read -r shell_pid; do
    cwd_link="/proc/$shell_pid/cwd"
    if [[ -L "$cwd_link" ]]; then
        cwd=$(readlink -f "$cwd_link" 2>/dev/null)
        mtime=$(stat -c '%Y' "$cwd_link" 2>/dev/null || echo 0)
        if [[ -n "$cwd" && "$mtime" -ge "$best_time" ]]; then
            best_time="$mtime"
            best_cwd="$cwd"
        fi
    fi
done < <(pgrep -P "$server_pid" 2>/dev/null)

echo "${best_cwd:-$fallback}"
