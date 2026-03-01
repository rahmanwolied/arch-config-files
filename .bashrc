# Only run fastfetch if this is an interactive terminal opened by the user
# Skip if opened by automated apps (VSCode, Cursor, SSH, etc.)
if [[ $- == *i* ]] && [ -t 0 ] && [ -z "$VSCODE_IPC_HOOK_CLI" ] && [ -z "$TERM_PROGRAM" ]; then
    fastfetch
fi

# Auto-start SSH Agent
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -s > "$HOME/.ssh/agent.env"
fi

if [[ -f "$HOME/.ssh/agent.env" ]]; then
    source "$HOME/.ssh/agent.env" > /dev/null
fi

# Automatically add your specific key if it's not already loaded
if ! ssh-add -l | grep -q "id_ed25519"; then
    ssh-add ~/.ssh/id_ed25519
fi