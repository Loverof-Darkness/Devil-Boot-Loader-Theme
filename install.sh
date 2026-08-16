#!/usr/bin/env bash
set -euo pipefail

# Garuda Transparent GRUB Theme
# One-command installer.

REPO_RAW="https://raw.githubusercontent.com/Loverof-Darkness/Devil-Boot-Loader-Theme/main"
THEME_DIR="/boot/grub/themes/garuda-transparent-menu"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="/var/backups/garuda-transparent-grub-${STAMP}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo:"
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
    exit 1
fi

SOURCE_DIR="$(dirname "$CURRENT_THEME")"
echo "Detected Garuda theme: $CURRENT_THEME"

rm -rf "$THEME_DIR"
mkdir -p "$THEME_DIR"
cp -a "$SOURCE_DIR"/. "$THEME_DIR"/

download "${REPO_RAW}/theme/background.png" "$TMP/background.png"

THEME_FILE="$THEME_DIR/theme.txt"
IMAGE_REF="$(sed -n 's/^[[:space:]]*desktop-image[[:space:]]*:[[:space:]]*"\([^"]*\)".*$/\1/p' "$THEME_FILE" | head -n1)"

if [[ -n "$IMAGE_REF" ]]; then
    cp -f "$TMP/background.png" "$THEME_DIR/$(basename "$IMAGE_REF")"
else
    cp -f "$TMP/background.png" "$THEME_DIR/background.png"
    sed -i '1i desktop-image: "background.png"\n' "$THEME_FILE"
fi

python3 - "$THEME_FILE" <<'PY'
from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
s = p.read_text()

# Remove only menu_pixmap_style from every boot_menu block. This keeps
# the Garuda individual item and selected-item graphical styling intact.
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

if grep -qE '^[[:space:]]*GRUB_THEME=' /etc/default/grub; then
    sed -i 's|^[[:space:]]*GRUB_THEME=.*$|GRUB_THEME="/boot/grub/themes/garuda-transparent-menu/theme.txt"|' /etc/default/grub
else
    printf '\nGRUB_THEME="/boot/grub/themes/garuda-transparent-menu/theme.txt"\n' >> /etc/default/grub
fi

sed -i 's|^[[:space:]]*GRUB_BACKGROUND=.*$|# GRUB_BACKGROUND managed by Garuda Transparent GRUB theme|' /etc/default/grub

echo "Generating GRUB configuration..."
if command -v update-grub >/dev/null 2>&1; then
    update-grub
else
    grub-mkconfig -o /boot/grub/grub.cfg
fi

echo
echo "✓ Garuda Transparent GRUB Theme installed"
echo "✓ Original Garuda buttons/layout preserved"
echo "✓ Outer menu frame made transparent"
echo "✓ Backup: $BACKUP"
echo "Reboot to test."
