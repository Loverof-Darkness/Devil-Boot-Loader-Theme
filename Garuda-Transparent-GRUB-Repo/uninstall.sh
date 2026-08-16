#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="/boot/grub/themes/garuda-transparent-menu"

if [[ $EUID -ne 0 ]]; then
    echo "Run: sudo ./uninstall.sh"
    exit 1
fi

LATEST="$(find /var/backups -maxdepth 1 -type d \
    -name 'garuda-transparent-grub-*' \
    -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2- || true)"

if [[ -z "${LATEST:-}" || ! -f "$LATEST/grub.default" ]]; then
    echo "No backup from this installer was found."
    echo "Your original GRUB configuration was not automatically changed."
    exit 1
fi

cp -a "$LATEST/grub.default" /etc/default/grub
rm -rf "$THEME_DIR"

if command -v update-grub >/dev/null 2>&1; then
    update-grub
else
    grub-mkconfig -o /boot/grub/grub.cfg
fi

echo "✓ Previous GRUB configuration restored."
