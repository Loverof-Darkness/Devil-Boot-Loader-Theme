#!/usr/bin/env bash
set -euo pipefail

# Devil Boot Loader Theme - Universal GRUB installer
BRANCH="universal-grub"
RAW_BASE="https://raw.githubusercontent.com/Loverof-Darkness/Devil-Boot-Loader-Theme/${BRANCH}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="/var/backups/devil-boot-loader-${STAMP}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo."
    echo "curl -fsSL ${RAW_BASE}/install.sh | sudo bash"
    exit 1
fi

if [[ ! -f /etc/default/grub ]]; then
    echo "ERROR: /etc/default/grub was not found."
    exit 1
fi

if [[ -d /boot/grub2 ]]; then
    GRUB_DIR="/boot/grub2"
elif [[ -d /boot/grub ]]; then
    GRUB_DIR="/boot/grub"
else
    echo "ERROR: GRUB directory was not found under /boot/grub or /boot/grub2."
    exit 1
fi

THEME_DIR="${GRUB_DIR}/themes/devil-transparent-grub"

# Detect whether our Universal Devil theme is already installed.
if [[ -d "$THEME_DIR" ]] || grep -qF "GRUB_THEME=\"${THEME_DIR}/theme.txt\"" /etc/default/grub 2>/dev/null; then
    echo
    echo "Devil Boot Loader Theme (Universal GRUB) is already installed."
    read -r -p "Would you like to reinstall/overwrite it? [y/N]: " answer
    case "$answer" in
        [yY]|[yY][eE][sS]) echo "Reinstalling..." ;;
        *) echo "Installation cancelled."; exit 0 ;;
    esac
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

# Read currently configured theme and never treat our generated theme as the base.
CURRENT_THEME="$(sed -n 's/^[[:space:]]*GRUB_THEME[[:space:]]*=[[:space:]]*"\([^"]*\)".*$/\1/p' /etc/default/grub | head -n1)"
if [[ "$CURRENT_THEME" == *"/garuda-transparent-menu/"* || "$CURRENT_THEME" == *"/devil-transparent-grub/"* ]]; then
    CURRENT_THEME=""
fi

# Search common theme roots, excluding generated/project themes.
if [[ -z "$CURRENT_THEME" || ! -f "$CURRENT_THEME" ]]; then
    while IFS= read -r candidate; do
        case "$candidate" in
            *"/garuda-transparent-menu/"*|*"/devil-transparent-grub/"*) continue ;;
        esac
        if [[ -f "$candidate" ]]; then
            CURRENT_THEME="$candidate"
            break
        fi
    done < <(
        find /usr/share/grub/themes /usr/share/grub2/themes "${GRUB_DIR}/themes" \
            -type f -name theme.txt 2>/dev/null | sort
    )
fi

if [[ -z "$CURRENT_THEME" || ! -f "$CURRENT_THEME" ]]; then
    echo "ERROR: No existing GRUB theme was found."
    echo "This installer preserves an installed distro theme rather than creating a new button design."
    exit 1
fi

SOURCE_DIR="$(dirname "$CURRENT_THEME")"

echo "Detected GRUB theme: $CURRENT_THEME"
echo "GRUB directory: $GRUB_DIR"

echo
read -r -p "Would you like to install the Devil Boot Loader Theme using this theme? [y/N]: " answer
case "$answer" in
    [yY]|[yY][eE][sS]) echo "Installing..." ;;
    *) echo "Installation cancelled."; exit 0 ;;
esac

mkdir -p "$BACKUP"
cp -a /etc/default/grub "$BACKUP/grub.default"

rm -rf "$THEME_DIR"
mkdir -p "$THEME_DIR"
cp -a "$SOURCE_DIR"/. "$THEME_DIR"/

download "${RAW_BASE}/theme/devil-background.png" "$TMP/devil-background.png"

THEME_FILE="$THEME_DIR/theme.txt"
IMAGE_REF="$(sed -n 's/^[[:space:]]*desktop-image[[:space:]]*:[[:space:]]*"\([^" ]*\)".*$/\1/p' "$THEME_FILE" | head -n1)"
if [[ -n "$IMAGE_REF" ]]; then
    cp -f "$TMP/devil-background.png" "$THEME_DIR/$(basename "$IMAGE_REF")"
else
    cp -f "$TMP/devil-background.png" "$THEME_DIR/devil-background.png"
    sed -i '1i desktop-image: "devil-background.png"\n' "$THEME_FILE"
fi

python3 - "$THEME_FILE" <<'PY'
from pathlib import Path
import re
import sys
p = Path(sys.argv[1])
s = p.read_text()

def find_blocks(text):
    result=[]; pos=0
    while True:
        m=re.search(r'(?m)^\s*\+\s*boot_menu\s*\{', text[pos:])
        if not m: break
        start=pos+m.start(); brace=text.find('{',start); depth=0; end=None
        for i in range(brace,len(text)):
            if text[i]=='{': depth+=1
            elif text[i]=='}':
                depth-=1
                if depth==0: end=i+1; break
        if end is None: break
        result.append((start,end)); pos=end
    return result

for start,end in reversed(find_blocks(s)):
    block=s[start:end]
    block=re.sub(r'(?m)^[ \t]*menu_pixmap_style[ \t]*=[^\n]*\n?','',block)
    s=s[:start]+block+s[end:]
p.write_text(s)
PY

if grep -qE '^[[:space:]]*GRUB_THEME=' /etc/default/grub; then
    sed -i "s|^[[:space:]]*GRUB_THEME=.*$|GRUB_THEME=\"${THEME_DIR}/theme.txt\"|" /etc/default/grub
else
    printf '\nGRUB_THEME="%s/theme.txt"\n' "$THEME_DIR" >> /etc/default/grub
fi
sed -i 's|^[[:space:]]*GRUB_BACKGROUND=.*$|# GRUB_BACKGROUND managed by Devil Boot Loader Theme|' /etc/default/grub

echo "Generating GRUB configuration..."
if command -v update-grub >/dev/null 2>&1; then
    update-grub
elif command -v grub2-mkconfig >/dev/null 2>&1; then
    grub2-mkconfig -o "${GRUB_DIR}/grub.cfg"
elif command -v grub-mkconfig >/dev/null 2>&1; then
    grub-mkconfig -o "${GRUB_DIR}/grub.cfg"
else
    echo "ERROR: No supported GRUB configuration command was found."
    echo "Backup: $BACKUP"
    exit 1
fi

echo
echo "============================================================"
echo "✓ Devil Boot Loader Theme installed (Universal GRUB)"
echo "✓ Base distro theme preserved"
echo "✓ Outer menu frame made transparent"
echo "✓ Devil background applied"
echo "✓ Backup: $BACKUP"
echo "============================================================"
echo "Reboot to test."
