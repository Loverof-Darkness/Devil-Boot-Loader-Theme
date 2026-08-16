#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Garuda Transparent GRUB Theme
# One-command GitHub installer.
#
# The only repository-specific value is REPO_RAW below.
# After uploading to GitHub, set it to:
# https://raw.githubusercontent.com/OWNER/REPO/main
# ============================================================

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/OWNER/REPO/main}"
THEME_DIR="/boot/grub/themes/garuda-transparent-menu"
THEME_NAME="garuda-transparent-menu"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="/var/backups/${THEME_NAME}-${STAMP}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ $EUID -ne 0 ]]; then
    echo "Please run this installer with sudo."
    echo "Example:"
    echo "  curl -fsSL ${REPO_RAW}/install.sh | sudo bash"
    exit 1
fi

download() {
    local url="$1" out="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --connect-timeout 10 "$url" -o "$out"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --tries=3 -O "$out" "$url"
    else
        echo "ERROR: curl or wget is required."
        exit 1
    fi
}

mkdir -p "$BACKUP"
cp -a /etc/default/grub "$BACKUP/grub.default"

# Detect the currently configured Garuda theme.
CURRENT_THEME=""
if grep -qE '^[[:space:]]*GRUB_THEME=' /etc/default/grub; then
    CURRENT_THEME="$(sed -n 's/^[[:space:]]*GRUB_THEME[[:space:]]*=[[:space:]]*"\([^"]*\)".*$/\1/p' /etc/default/grub | head -n1)"
fi

if [[ -z "$CURRENT_THEME" || ! -f "$CURRENT_THEME" ]]; then
    for candidate in \
        /usr/share/grub/themes/garuda-dr460nized/theme.txt \
        /usr/share/grub/themes/garuda/theme.txt \
        /boot/grub/themes/garuda-dr460nized/theme.txt \
        /boot/grub/themes/garuda/theme.txt; do
        if [[ -f "$candidate" ]]; then
            CURRENT_THEME="$candidate"
            break
        fi
    done
fi

if [[ -z "$CURRENT_THEME" || ! -f "$CURRENT_THEME" ]]; then
    echo "ERROR: Could not find an installed Garuda GRUB theme."
    echo "Install a Garuda GRUB theme first, then rerun this installer."
    exit 1
fi

SOURCE_DIR="$(dirname "$CURRENT_THEME")"
echo "Detected Garuda theme:"
echo "  $CURRENT_THEME"

# Clone the complete installed Garuda theme.
rm -rf "$THEME_DIR"
mkdir -p "$THEME_DIR"
cp -a "$SOURCE_DIR"/. "$THEME_DIR"/

# Download repository background.
download "${REPO_RAW}/theme/background.png" "$TMP/background.png"

# Find the image referenced by the original theme and replace ONLY that image.
THEME_FILE="$THEME_DIR/theme.txt"
IMAGE_REF="$(sed -n 's/^[[:space:]]*desktop-image[[:space:]]*:[[:space:]]*"\([^"]*\)".*$/\1/p' "$THEME_FILE" | head -n1)"

if [[ -n "$IMAGE_REF" ]]; then
    cp -f "$TMP/background.png" "$THEME_DIR/$(basename "$IMAGE_REF")"
else
    cp -f "$TMP/background.png" "$THEME_DIR/background.png"
    sed -i '1i desktop-image: "background.png"\n' "$THEME_FILE"
fi

# Remove ONLY the outer boot_menu frame style.
# Individual Garuda menu-item and selected-item styles remain untouched.
python3 - "$THEME_FILE" <<'PY'
from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
s = p.read_text()

def find_blocks(text):
    result = []
    pos = 0
    while True:
        m = re.search(r'(?m)^\s*\+\s*boot_menu\s*\{', text[pos:])
        if not m:
            break
        start = pos + m.start()
        brace = text.find('{', start)
        depth = 0
        end = None
        for i in range(brace, len(text)):
            if text[i] == '{':
                depth += 1
            elif text[i] == '}':
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break
        if end is None:
            break
        result.append((start, end))
        pos = end
    return result

for start, end in reversed(find_blocks(s)):
    block = s[start:end]
    block = re.sub(r'(?m)^[ \t]*menu_pixmap_style[ \t]*=[^\n]*\n?', '', block)
    s = s[:start] + block + s[end:]

p.write_text(s)
PY

# Point GRUB at our cloned transparent theme.
if grep -qE '^[[:space:]]*GRUB_THEME=' /etc/default/grub; then
    sed -i "s|^[[:space:]]*GRUB_THEME=.*$|GRUB_THEME=\"${THEME_DIR}/theme.txt\"|" /etc/default/grub
else
    printf '\nGRUB_THEME="%s/theme.txt"\n' "$THEME_DIR" >> /etc/default/grub
fi

# Avoid a separate GRUB_BACKGROUND overriding the theme background.
sed -i 's|^[[:space:]]*GRUB_BACKGROUND=.*$|# GRUB_BACKGROUND managed by Garuda Transparent GRUB theme|' /etc/default/grub

echo "Generating GRUB configuration..."
if command -v update-grub >/dev/null 2>&1; then
    update-grub
else
    grub-mkconfig -o /boot/grub/grub.cfg
fi

echo
echo "============================================================"
echo " Garuda Transparent GRUB Theme installed successfully"
echo "============================================================"
echo "Theme : $THEME_DIR"
echo "Backup: $BACKUP"
echo
echo "Reboot to test."
