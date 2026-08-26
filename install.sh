#!/usr/bin/env bash
set -euo pipefail

# Devil Boot Loader Theme - universal GRUB installer
# Supports Garuda/Arch-derived Garuda themes when present, and creates a
# standalone universal GRUB theme on Ubuntu/Debian/other GRUB systems.

REPO_BASE="https://raw.githubusercontent.com/Loverof-Darkness/Devil-Boot-Loader-Theme/main"
THEME_DIR="/boot/grub/themes/devil-boot-loader"
THEME_FILE="$THEME_DIR/theme.txt"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="/var/backups/devil-boot-loader-${STAMP}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo:"
    echo "curl -fsSL ${REPO_BASE}/install.sh | sudo bash"
    exit 1
fi

if [[ -d "$THEME_DIR" ]] || grep -qF 'GRUB_THEME="/boot/grub/themes/devil-boot-loader/theme.txt"' /etc/default/grub 2>/dev/null; then
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

# Download the project's background.
download "${REPO_BASE}/theme/devil-background.png" "$TMP/devil-background.png"

# Prefer the installed Garuda theme when available so Garuda users keep their
# original buttons, icons, fonts and layout. Everyone else gets the universal
# standalone theme below.
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
    SOURCE_DIR="$(dirname "$CURRENT_THEME")"
    cp -a "$SOURCE_DIR"/. "$THEME_DIR"/

    ORIGINAL_IMAGE="$(sed -n 's/^[[:space:]]*desktop-image[[:space:]]*:[[:space:]]*"\([^"]*\)".*$/\1/p' "$THEME_FILE" | head -n1)"
    if [[ -n "$ORIGINAL_IMAGE" ]]; then
        cp -f "$TMP/devil-background.png" "$THEME_DIR/$(basename "$ORIGINAL_IMAGE")"
    else
        cp -f "$TMP/devil-background.png" "$THEME_DIR/devil-background.png"
        sed -i '1i desktop-image: "devil-background.png"\n' "$THEME_FILE"
    fi

    # Remove only the outer boot_menu frame. Garuda item/selection styles stay.
    python3 - "$THEME_FILE" <<'PY'
from pathlib import Path
import re, sys
p=Path(sys.argv[1]); s=p.read_text()
def blocks(text):
    out=[]; pos=0
    while True:
        m=re.search(r'(?m)^\s*\+\s*boot_menu\s*\{',text[pos:])
        if not m: break
        start=pos+m.start(); brace=text.find('{',start); depth=0; end=None
        for i in range(brace,len(text)):
            if text[i]=='{': depth+=1
            elif text[i]=='}':
                depth-=1
                if depth==0: end=i+1; break
        if end is None: break
        out.append((start,end)); pos=end
    return out
for start,end in reversed(blocks(s)):
    b=s[start:end]
    b=re.sub(r'(?m)^[ \t]*menu_pixmap_style[ \t]*=[^\n]*\n?','',b)
    s=s[:start]+b+s[end:]
p.write_text(s)
PY
else
    echo "No Garuda theme found; installing universal GRUB theme."
    cp -f "$TMP/devil-background.png" "$THEME_DIR/devil-background.png"

    # Standalone theme: transparent outer menu, simple readable entries.
    cat > "$THEME_FILE" <<'THEME'
# Devil Boot Loader Theme - universal fallback
# Compatible with GRUB's gfxterm theme renderer.

desktop-image: "devil-background.png"

# Transparent menu: no menu_pixmap_style is specified.
+ boot_menu {
    left = 15%
    width = 70%
    top = 52%
    height = 38%
    item_height = 42
    item_padding = 8
    item_icon_space = 12
    item_spacing = 6
    selected_item_color = "#ffffff"
    item_color = "#d0d0d0"
    font = "DejaVu Sans 18"
}
THEME
fi

# Ensure GRUB uses the theme.
if grep -qE '^[[:space:]]*GRUB_THEME=' /etc/default/grub; then
    sed -i 's|^[[:space:]]*GRUB_THEME=.*$|GRUB_THEME="/boot/grub/themes/devil-boot-loader/theme.txt"|' /etc/default/grub
else
    printf '\nGRUB_THEME="/boot/grub/themes/devil-boot-loader/theme.txt"\n' >> /etc/default/grub
fi

# GRUB themes require gfxterm; force a graphics mode without requiring a
# particular resolution supported by the machine.
if grep -qE '^[[:space:]]*GRUB_TERMINAL=' /etc/default/grub; then
    sed -i 's|^[[:space:]]*GRUB_TERMINAL=.*$|GRUB_TERMINAL="gfxterm"|' /etc/default/grub
else
    printf 'GRUB_TERMINAL="gfxterm"\n' >> /etc/default/grub
fi

if grep -qE '^[[:space:]]*GRUB_GFXMODE=' /etc/default/grub; then
    sed -i 's|^[[:space:]]*GRUB_GFXMODE=.*$|GRUB_GFXMODE="auto"|' /etc/default/grub
else
    printf 'GRUB_GFXMODE="auto"\n' >> /etc/default/grub
fi

# Theme supplies its own background.
sed -i 's|^[[:space:]]*GRUB_BACKGROUND=.*$|# GRUB_BACKGROUND managed by Devil Boot Loader Theme|' /etc/default/grub

# Regenerate the actual boot configuration.
if command -v update-grub >/dev/null 2>&1; then
    update-grub
elif command -v grub-mkconfig >/dev/null 2>&1; then
    grub-mkconfig -o /boot/grub/grub.cfg
else
    echo "ERROR: grub-mkconfig/update-grub not found."
    exit 1
fi

# Verify that the generated config references our theme.
if ! grep -qF '/boot/grub/themes/devil-boot-loader/theme.txt' /boot/grub/grub.cfg; then
    echo
    echo "WARNING: grub.cfg was generated but does not reference the theme."
    echo "Your distribution may require an additional GRUB theme configuration."
    exit 1
fi

echo
echo "✓ Devil Boot Loader Theme installed"
echo "✓ Theme: $THEME_FILE"
echo "✓ Backup: $BACKUP"
echo "✓ GRUB graphics mode: gfxterm / auto"
echo "Reboot to test."
