# Only run fastfetch if this is an interactive terminal opened by the user
# Skip if opened by automated apps (VSCode, Cursor, SSH, etc.)
if [[ $- == *i* ]] && [ -t 0 ] && [ -z "$VSCODE_IPC_HOOK_CLI" ] && [ -z "$TERM_PROGRAM" ]; then
    fastfetch
fi