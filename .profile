PNPM_PATH="$HOME/.local/share/pnpm"
export HOME_LOCAL_BIN="$HOME/.local/bin"
GO_BIN="$(go env GOBIN):$(go env GOPATH)/bin"
HOME_LOCAL_SHARE_OMARCHY_BIN="$HOME/.local/share/omarchy/bin/"
USR_LOCAL_SBIN="/usr/local/sbin"
USR_LOCAL_BIN="/usr/local/bin"
USR_BIN="/usr/bin"

export PATH="$HOME_LOCAL_BIN:$PNPM_PATH:$HOME_LOCAL_SHARE_OMARCHY_BIN:$USR_LOCAL_SBIN:$USR_LOCAL_BIN:$USR_BIN:$GO_BIN"