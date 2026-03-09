#!/bin/bash
set -e

TARBALL="$1"
INSTALL_DIR="$HOME/.local/share/antigravity"
DESKTOP_FILE="$HOME/.local/share/applications/antigravity.desktop"

if [ -z "$TARBALL" ]; then
  echo "Usage: install-antigravity <tarball>"
  exit 1
fi

if [ ! -f "$TARBALL" ]; then
  echo "Error: File '$TARBALL' not found."
  exit 1
fi

# Remove old installation
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Extract tarball
echo "Extracting $TARBALL..."
tar -xf "$TARBALL" -C "$INSTALL_DIR"

# Find the antigravity binary
BINARY=$(find "$INSTALL_DIR" -maxdepth 3 -name "antigravity" -type f -executable | head -1)
if [ -z "$BINARY" ]; then
  echo "Error: Could not find antigravity binary in extracted files."
  exit 1
fi

APP_DIR=$(dirname "$BINARY")
ICON=$(find "$APP_DIR" -path "*/antigravity.png" -type f | head -1)

# Create .desktop entry
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Antigravity
Comment=Antigravity Application
Exec=$BINARY
Icon=${ICON:-antigravity}
Terminal=false
Categories=Development;IDE;
StartupWMClass=antigravity
EOF
chmod +x "$DESKTOP_FILE"

# Update desktop database
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# Delete the original tarball
rm -f "$TARBALL"

echo "Antigravity installed successfully."
echo "Binary: $BINARY"
echo "Desktop entry: $DESKTOP_FILE"
