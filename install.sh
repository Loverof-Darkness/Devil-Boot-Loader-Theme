#!/usr/bin/env bash
set -euo pipefail

# Devil Boot Loader Theme - Universal GRUB installer
# Supports Linux distributions using GRUB. It preserves an existing distro
# theme and changes only the outer menu frame and background.

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
    echo "This installer expects a standard GRUB configuration."
    exit 1
fi

# Locate the distro's GRUB directory.
if [[ -d /boot/grub2 ]]; then
    GRUB_DIR="/boot/grub2"
elif [[ -d /boot/grub ]]; then
    GRUB_DIR="/boot/grub"
else
    echo "ERROR: GRUB directory was not found under /boot/grub or /boot/grub2."
    exit 1
fi

THEME_DIR="${GRUB_DIR}/themes/devil-transparent-grub"

# Ask before overwriting an installation created by this universal branch.
if [[ -d "$THEME_DIR" ]] || grep -qF "GRUB_THEME=\"${THEME_DIR}/theme.txt\"" /etc/default/grub 2>/dev/null; then
    echo
    echo "Devil Boot Loader Theme (Universal GRUB) is already installed."
    read -r -p "Do you want to reinstall/overwrite it? [y/N]: " answer
    case "$answer" in
        [yY]|[yY][eE][sS]) echo "Reinstalling..." ;;
        *) echo "Installation cancelled."; exit 0 ;;
    esac
fi

# Downloader.
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

# Read the currently configured theme.
CURRENT_THEME="$(sed -n 's/^[[:space:]]*GRUB_THEME[[:space:]]*=[[:space:]]*"\([^"]*\)".*$/\1/p' /etc/default/grub | head -n1)"

# IMPORTANT: do not stack a universal installation on top of the Garuda/main
# custom theme if this installer is being tested on a machine that already has
# the project installed. Prefer the underlying distro theme where possible.
if [[ "$CURRENT_THEME" == *"/garuda-transparent-menu/"* || "$CURRENT_THEME" == *"/devil-transparent-grub/"* ]]; then
    FOUND_ORIGINAL=""
    for candidate in \
        /usr/share/grub/themes/garuda-dr460nized/theme.txt \
        /usr/share/grub/themes/garuda/theme.txt \
        /usr/share/grub/themes/grub/theme.txt; do
        if [[ -f "$candidate" ]]; then
            FOUND_ORIGINAL="$candidate"
            break
        fi
    done

    # Generic fallback: search standard theme roots, excluding our generated
    # theme directories. This lets the universal installer work on other distros.
    if [[ -z "$FOUND_ORIGINAL" ]]; then
        while IFS= read -r candidate; do
            case "$candidate" in
                *"/garuda-transparent-menu/"*|*"/devil-transparent-grub/"*) continue ;;
            esac
            FOUND_ORIGINAL="$candidate"
            break
        done < <(
            find \
                /usr/share/grub/themes \
                /usr/share/grub2/themes \
                "${GRUB_DIR}/themes" \
                -type f -name theme.txt 2>/dev/null | sort
        )
    fi

    if [[ -n "$FOUND_ORIGINAL" ]]; then
        CURRENT_THEME="$FOUND_ORIGINAL"
    fi
fi

# If GRUB_THEME is absent/broken, find an installed theme in standard locations.
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
        find \
            /usr/share/grub/themes \
            /usr/share/grub2/themes \
            "${GRUB_DIR}/themes" \
            -type f -name theme.txt 2>/dev/null | sort
    )
fi

if [[ -z "$CURRENT_THEME" || ! -f "$CURRENT_THEME" ]]; then
    echo "ERROR: No existing GRUB theme was found."
    echo "This universal installer preserves an installed theme rather than inventing a new button design."
    exit 1
fi

SOURCE_DIR="$(dirname "$CURRENT_THEME")"
echo "Base GRUB theme: $CURRENT_THEME"
echo "GRUB directory: $GRUB_DIR"

# Backup before changing anything.
mkdir -p "$BACKUP"
cp -a /etc/default/grub "$BACKUP/grub.default"

# Clone the complete distro theme. The original theme is untouched.
rm -rf "$THEME_DIR"
mkdir -p "$THEME_DIR"
cp -a "$SOURCE_DIR"/. "$THEME_DIR"/

# Download common Devil background.
download "${RAW_BASE}/theme/devil-background.png" "$TMP/devil-background.png"

THEME_FILE="$THEME_DIR/theme.txt"

# Replace only the image referenced by the existing theme.
IMAGE_REF="$(sed -n 's/^[[:space:]]*desktop-image[[:space:]]*:[[:space:]]*"\([^" ]*\)".*$/\1/p' "$THEME_FILE" | head -n1)"
if [[ -n "$IMAGE_REF" ]]; then
    cp -f "$TMP/devil-background.png" "$THEME_DIR/$(basename "$IMAGE_REF")"
else
    cp -f "$TMP/devil-background.png" "$THEME_DIR/devil-background.png"
    sed -i '1i desktop-image: "devil-background.png"\n' "$THEME_FILE"
fi

# Remove ONLY menu_pixmap_style from every boot_menu block. Individual menu
# item and selected-item styling remains untouched.
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

# Point GRUB to our cloned universal theme.
if grep -qE '^[[:space:]]*GRUB_THEME=' /etc/default/grub; then
    sed -i "s|^[[:space:]]*GRUB_THEME=.*$|GRUB_THEME=\"${THEME_DIR}/theme.txt\"|" /etc/default/grub
else
    printf '\nGRUB_THEME="%s/theme.txt"\n' "$THEME_DIR" >> /etc/default/grub
fi

sed -i 's|^[[:space:]]*GRUB_BACKGROUND=.*$|# GRUB_BACKGROUND managed by Devil Boot Loader Theme|' /etc/default/grub

# Regenerate GRUB using whichever standard command is available.
echo "Generating GRUB configuration..."
if command -v update-grub >/dev/null 2>&1; then
    update-grub
elif command -v grub2-mkconfig >/dev/null 2>&1; then
    grub2-mkconfig -o "${GRUB_DIR}/grub.cfg"
elif command -v grub-mkconfig >/dev/null 2>&1; then
    grub-mkconfig -o "${GRUB_DIR}/grub.cfg"
else
    echo "ERROR: update-grub, grub2-mkconfig, or grub-mkconfig was not found."
    echo "Configuration was not regenerated. Backup: $BACKUP"
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
