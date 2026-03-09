#!/bin/bash
set -e

APPIMAGE="$1"
INSTALL_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/cursor.desktop"

if [ -z "$APPIMAGE" ]; then
  echo "Usage: install-cursor <AppImage>"
  exit 1
fi

if [ ! -f "$APPIMAGE" ]; then
  echo "Error: File '$APPIMAGE' not found."
  exit 1
fi

# Uninstall AUR cursor-bin if installed
if pacman -Q cursor-bin &>/dev/null; then
  echo "Removing AUR cursor-bin..."
  sudo pacman -Rns --noconfirm cursor-bin
fi

# Remove existing cursor binary
if [ -f "$INSTALL_DIR/cursor" ]; then
  echo "Removing existing $INSTALL_DIR/cursor..."
  rm -f "$INSTALL_DIR/cursor"
fi

# Remove any existing desktop entries
rm -f "$DESKTOP_DIR"/cursor*.desktop

# Install new AppImage
mkdir -p "$INSTALL_DIR"
echo "Installing Cursor AppImage..."
cp "$APPIMAGE" "$INSTALL_DIR/cursor"
chmod +x "$INSTALL_DIR/cursor"

# Create .desktop entry
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_FILE" <<EOF
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
chmod +x "$DESKTOP_FILE"

update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

# Delete the original AppImage
rm -f "$APPIMAGE"

echo "Cursor installed successfully."
echo "Binary: $INSTALL_DIR/cursor"
echo "Desktop entry: $DESKTOP_FILE"
