#!/usr/bin/env bash
set -euo pipefail

# Devil Boot Loader Theme - universal GRUB installer
# Works with Garuda's existing theme when available and falls back to a
# self-contained transparent GRUB theme on Ubuntu/Debian/other distros.

REPO_RAW="https://raw.githubusercontent.com/Loverof-Darkness/Devil-Boot-Loader-Theme/main"
THEME_DIR="/boot/grub/themes/devil-boot-loader"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="/var/backups/devil-boot-loader-${STAMP}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo."
    echo "curl -fsSL ${REPO_RAW}/install.sh | sudo bash"
    exit 1
fi

# Ask before overwriting our existing installation.
if [[ -d "$THEME_DIR" ]] || grep -qF 'GRUB_THEME="/boot/grub/themes/devil-boot-loader/theme.txt"' /etc/default/grub 2>/dev/null || grep -qF 'GRUB_THEME="/boot/grub/themes/garuda-transparent-menu/theme.txt"' /etc/default/grub 2>/dev/null; then
    echo
    echo "Devil Boot Loader Theme is already installed."
    read -r -p "Do you want to reinstall/overwrite it? [y/N]: " answer
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

mkdir -p "$BACKUP"
cp -a /etc/default/grub "$BACKUP/grub.default"

download "${REPO_RAW}/theme/devil-background.png" "$TMP/devil-background.png"

# Find a real Garuda theme first. If none exists (Ubuntu/Debian/etc.),
# create our own self-contained theme instead of failing.
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
        if [[ -f "$candidate" ]]; then CURRENT_THEME="$candidate"; break; fi
    done
fi

rm -rf "$THEME_DIR"
mkdir -p "$THEME_DIR"

if [[ -n "$CURRENT_THEME" && -f "$CURRENT_THEME" ]]; then
    echo "Detected Garuda theme: $CURRENT_THEME"
    echo "Preserving the Garuda theme's buttons, icons, fonts and layout."
    SOURCE_DIR="$(dirname "$CURRENT_THEME")"
    cp -a "$SOURCE_DIR"/. "$THEME_DIR"/

    THEME_FILE="$THEME_DIR/theme.txt"
    IMAGE_REF="$(sed -n 's/^[[:space:]]*desktop-image[[:space:]]*:[[:space:]]*"\([^" ]*\)".*$/\1/p' "$THEME_FILE" | head -n1)"
    if [[ -n "$IMAGE_REF" ]]; then
        cp -f "$TMP/devil-background.png" "$THEME_DIR/$(basename "$IMAGE_REF")"
    else
        cp -f "$TMP/devil-background.png" "$THEME_DIR/devil-background.png"
        sed -i '1i desktop-image: "devil-background.png"\n' "$THEME_FILE"
    fi

    # Remove only the outer menu frame; keep Garuda item/selection styling.
    python3 - "$THEME_FILE" <<'PY'
from pathlib import Path
import re, sys
p=Path(sys.argv[1]); s=p.read_text()
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
else
    echo "No Garuda GRUB theme found; installing the universal Devil theme."

    # Ubuntu/Debian fallback. Use an installed GRUB font if available.
    FONT=""
    for f in /usr/share/grub/themes/*/*.pf2 /usr/share/grub/*.pf2; do
        if [[ -f "$f" ]]; then FONT="$f"; break; fi
    done

    if [[ -z "$FONT" ]]; then
        echo "ERROR: No GRUB .pf2 font found. Is grub installed?"
        exit 1
    fi

    FONT_NAME="$(basename "$FONT")"
    cp -f "$FONT" "$THEME_DIR/$FONT_NAME"
    cp -f "$TMP/devil-background.png" "$THEME_DIR/devil-background.png"

    # Transparent menu, simple centered title and clean selectable entries.
    # No external theme assets are required.
    cat > "$THEME_DIR/theme.txt" <<EOF
# Devil Boot Loader Theme - universal fallback
# Transparent main menu with custom background.

desktop-image: "devil-background.png"

+ label {
    top = 12%
    left = 50%
    width = 50%
    align = "center"
    text = "DEVIL BOOT LOADER"
    font = "$FONT_NAME"
    color = "ffffff"
}

+ boot_menu {
    left = 22%
    top = 32%
    width = 56%
    height = 48%
    item_font = "$FONT_NAME"
    item_color = "ffffff"
    selected_item_color = "ff718f"
    item_height = 36
    item_padding = 8
    selected_item_pixmap_style = ""
}
EOF
fi

# Point GRUB to the generated theme.
if grep -qE '^[[:space:]]*GRUB_THEME=' /etc/default/grub; then
    sed -i 's|^[[:space:]]*GRUB_THEME=.*$|GRUB_THEME="/boot/grub/themes/devil-boot-loader/theme.txt"|' /etc/default/grub
else
    printf '\nGRUB_THEME="/boot/grub/themes/devil-boot-loader/theme.txt"\n' >> /etc/default/grub
fi

sed -i 's|^[[:space:]]*GRUB_BACKGROUND=.*$|# GRUB_BACKGROUND managed by Devil Boot Loader Theme|' /etc/default/grub

echo "Generating GRUB configuration..."
if command -v update-grub >/dev/null 2>&1; then
    update-grub
elif command -v grub-mkconfig >/dev/null 2>&1; then
    grub-mkconfig -o /boot/grub/grub.cfg
else
    echo "ERROR: grub-mkconfig/update-grub not found. Install GRUB first."
    exit 1
fi

echo
echo "============================================================"
echo "✓ Devil Boot Loader Theme installed"
echo "✓ Transparent main menu"
echo "✓ Custom Devil background"
if [[ -n "$CURRENT_THEME" && -f "$CURRENT_THEME" ]]; then
    echo "✓ Existing Garuda theme styling preserved"
else
    echo "✓ Universal GRUB fallback theme used"
fi
echo "✓ Backup: $BACKUP"
echo "============================================================"
echo "Reboot to test."
