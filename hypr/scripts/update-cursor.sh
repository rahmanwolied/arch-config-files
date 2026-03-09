#!/bin/bash

# =============================================================================
# Cursor IDE - Download & Update Script
# Supports: Arch Linux (native + AUR), other Linux distros, macOS
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${BLUE}[INFO]${NC}  $1"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# =============================================================================
# Detect OS & Architecture
# =============================================================================
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)  PLATFORM="linux" ;;
  Darwin) PLATFORM="mac" ;;
  *)      error "Unsupported OS: $OS. This script supports Linux and macOS." ;;
esac

case "$ARCH" in
  x86_64)        ARCH_LABEL="x64" ;;
  aarch64|arm64) ARCH_LABEL="arm64" ;;
  *)             error "Unsupported architecture: $ARCH" ;;
esac

log "Detected platform: $OS ($ARCH)"

# =============================================================================
# Detect if running on Arch Linux
# =============================================================================
IS_ARCH=false
if [ "$PLATFORM" = "linux" ] && [ -f /etc/arch-release ]; then
  IS_ARCH=true
  log "Arch Linux detected."
fi

# =============================================================================
# Arch Linux: prefer AUR helper or makepkg
# =============================================================================
if [ "$IS_ARCH" = true ]; then
  echo ""
  log "Arch Linux install options:"
  echo "  1) AUR (cursor-bin)  — recommended, managed by pacman"
  echo "  2) AppImage          — manual install to ~/.local/bin"
  echo ""
  read -rp "Choose install method [1/2] (default: 1): " METHOD
  METHOD="${METHOD:-1}"

  if [ "$METHOD" = "1" ]; then
    # -------------------------------------------------------------------------
    # AUR install via helper or makepkg fallback
    # -------------------------------------------------------------------------
    AUR_PKG="cursor-bin"

    # Detect available AUR helper
    AUR_HELPER=""
    for helper in yay paru trizen aura; do
      if command -v "$helper" &>/dev/null; then
        AUR_HELPER="$helper"
        break
      fi
    done

    if [ -n "$AUR_HELPER" ]; then
      log "Using AUR helper: $AUR_HELPER"
      log "Installing/updating $AUR_PKG ..."
      "$AUR_HELPER" -Syu --noconfirm "$AUR_PKG"
      ok "Cursor installed/updated via $AUR_HELPER."

    else
      warn "No AUR helper found (yay, paru, etc.). Falling back to manual makepkg."
      log "Installing build dependencies..."
      sudo pacman -S --needed --noconfirm git base-devel

      BUILD_DIR="$(mktemp -d)"
      trap 'rm -rf "$BUILD_DIR"' EXIT

      log "Cloning $AUR_PKG from AUR..."
      git clone "https://aur.archlinux.org/${AUR_PKG}.git" "$BUILD_DIR/$AUR_PKG"

      cd "$BUILD_DIR/$AUR_PKG"
      log "Building and installing $AUR_PKG (this may take a moment)..."
      makepkg -si --noconfirm

      ok "Cursor installed/updated via makepkg."
    fi

    # Check installed version
    INSTALLED=$(pacman -Q "$AUR_PKG" 2>/dev/null | awk '{print $2}' || true)
    [ -n "$INSTALLED" ] && ok "Installed version: $INSTALLED"

    echo ""
    ok "=========================================="
    ok " Cursor update complete! (Arch / AUR)"
    [ -n "$INSTALLED" ] && ok " Version: $INSTALLED"
    ok "=========================================="
    echo ""
    exit 0
  fi
  # METHOD=2 falls through to AppImage path below
fi

# =============================================================================
# Fetch latest version from Cursor API (AppImage / DMG path)
# =============================================================================
log "Fetching latest Cursor version..."

API_URL="https://www.cursor.com/api/download?platform=${PLATFORM}&releaseTrack=stable"
RESPONSE=$(curl -fsSL "$API_URL" 2>/dev/null) || error "Failed to fetch version info. Check your internet connection."

DOWNLOAD_URL=$(echo "$RESPONSE" | grep -o '"downloadUrl":"[^"]*"' | cut -d'"' -f4)
VERSION=$(echo "$RESPONSE" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)

if [ -z "$DOWNLOAD_URL" ]; then
  warn "Could not parse API response. Using fallback download URL."
  if [ "$PLATFORM" = "linux" ]; then
    DOWNLOAD_URL="https://downloader.cursor.sh/linux/appImage/${ARCH_LABEL}"
  else
    DOWNLOAD_URL="https://downloader.cursor.sh/mac/dmg/${ARCH_LABEL}"
  fi
fi

[ -n "$VERSION" ] && log "Latest version: $VERSION" || log "Version: (unknown)"
log "Download URL: $DOWNLOAD_URL"

# =============================================================================
# Check currently installed version
# =============================================================================
CURRENT_VERSION=""

if [ "$PLATFORM" = "linux" ]; then
  for loc in "$(command -v cursor 2>/dev/null)" "$HOME/.local/bin/cursor"; do
    if [ -x "$loc" ]; then
      CURRENT_VERSION=$("$loc" --version 2>/dev/null | head -1 || true)
      break
    fi
  done
elif [ "$PLATFORM" = "mac" ]; then
  if [ -d "/Applications/Cursor.app" ]; then
    CURRENT_VERSION=$(defaults read /Applications/Cursor.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || true)
  fi
fi

if [ -n "$CURRENT_VERSION" ]; then
  log "Installed version: $CURRENT_VERSION"
  if [ "$CURRENT_VERSION" = "$VERSION" ] && [ -n "$VERSION" ]; then
    ok "Cursor is already up to date ($VERSION)."
    echo ""
    read -rp "Re-install anyway? [y/N] " REINSTALL
    [[ "$REINSTALL" =~ ^[Yy]$ ]] || { log "Nothing to do. Exiting."; exit 0; }
  fi
else
  log "Cursor does not appear to be installed. Proceeding with fresh install."
fi

# =============================================================================
# Download
# =============================================================================
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [ "$PLATFORM" = "linux" ]; then
  DEST_FILE="$TMP_DIR/cursor.AppImage"
  log "Downloading Cursor AppImage..."
  curl -L --progress-bar "$DOWNLOAD_URL" -o "$DEST_FILE" || error "Download failed."

  chmod +x "$DEST_FILE"

  INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$INSTALL_DIR"

  log "Installing to $INSTALL_DIR/cursor ..."
  cp "$DEST_FILE" "$INSTALL_DIR/cursor"
  chmod +x "$INSTALL_DIR/cursor"

  # Create .desktop entry
  DESKTOP_DIR="$HOME/.local/share/applications"
  mkdir -p "$DESKTOP_DIR"

  cat > "$DESKTOP_DIR/cursor.desktop" <<EOF
[Desktop Entry]
Name=Cursor
Exec=$INSTALL_DIR/cursor --no-sandbox %U
Icon=cursor
Type=Application
Categories=Development;TextEditor;IDE;
MimeType=text/plain;
StartupWMClass=Cursor
Comment=Cursor - AI-first Code Editor
EOF

  ok "Cursor installed to $INSTALL_DIR/cursor"
  ok "Desktop entry created at $DESKTOP_DIR/cursor.desktop"

  # Arch-specific: refresh desktop database
  if [ "$IS_ARCH" = true ] && command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    ok "Desktop database updated."
  fi

  # Warn if not in PATH
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    warn "$INSTALL_DIR is not in your PATH."
    echo -e "  Add this to your ~/.bashrc or ~/.zshrc:\n"
    echo -e "    ${YELLOW}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}\n"
  fi

  # Arch: check for FUSE (required to run AppImages)
  if [ "$IS_ARCH" = true ]; then
    if ! pacman -Q fuse2 &>/dev/null && ! pacman -Q fuse3 &>/dev/null; then
      warn "AppImages require FUSE. Install it with:"
      echo -e "    ${YELLOW}sudo pacman -S fuse2${NC}"
    fi
  fi

elif [ "$PLATFORM" = "mac" ]; then
  DEST_FILE="$TMP_DIR/cursor.dmg"
  log "Downloading Cursor DMG..."
  curl -L --progress-bar "$DOWNLOAD_URL" -o "$DEST_FILE" || error "Download failed."

  log "Mounting DMG..."
  MOUNT_POINT=$(hdiutil attach "$DEST_FILE" -nobrowse -quiet | grep "/Volumes/" | awk '{print $NF}')
  [ -z "$MOUNT_POINT" ] && error "Failed to mount DMG."
  log "Mounted at: $MOUNT_POINT"

  if [ -d "/Applications/Cursor.app" ]; then
    log "Removing old Cursor.app..."
    rm -rf "/Applications/Cursor.app"
  fi

  log "Copying Cursor.app to /Applications..."
  cp -R "$MOUNT_POINT/Cursor.app" /Applications/

  log "Unmounting DMG..."
  hdiutil detach "$MOUNT_POINT" -quiet

  ok "Cursor installed to /Applications/Cursor.app"
fi

# =============================================================================
# Done
# =============================================================================
echo ""
ok "=========================================="
ok " Cursor update complete!"
[ -n "$VERSION" ] && ok " Version: $VERSION"
ok "=========================================="
echo ""