$SOURCE_DIR = $1
$DEFAULT_SOURCE_DIR = $HOME/.config/arch-config-files/
$TARGET_DIR = $2
$DEFAULT_TARGET_DIR = $HOME/.config/

if [ -z "$SOURCE_DIR" ]; then
    SOURCE_DIR = $DEFAULT_SOURCE_DIR
fi

if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR = $DEFAULT_TARGET_DIR
fi

#create backup of current config files
if [ -d "$TARGET_DIR" ]; then
    echo "❌ $TARGET_DIR already exists, creating backup..."
    cp -ar $TARGET_DIR $HOME/.backup/$TARGET_DIR-$(date +%Y-%m-%d_%H-%M-%S)
    echo "✅ Backup created successfully"
fi

#install rsync if not installed
if ! command -v rsync &> /dev/null; then
    echo "❌ rsync could not be found, installing..."
    sudo pacman -S rsync
    echo "✅ rsync installed successfully"
fi

rsync -avz --progress --exclude="omarchy/current" --exclude="omarchy/" $SOURCE_DIR $TARGET_DIR

if [ $? -ne 0 ]; then
    echo "❌ Sync failed"
    exit 1
fi

echo "✅ Sync complete"
echo "🔄 Synced $SOURCE_DIR to $TARGET_DIR"