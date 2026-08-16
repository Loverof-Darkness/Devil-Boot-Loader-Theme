#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run: sudo ./uninstall.sh"
    exit 1
fi

# Detect GRUB directory used by the system.
if [[ -d /boot/grub2 ]]; then
    GRUB_DIR="/boot/grub2"
elif [[ -d /boot/grub ]]; then
    GRUB_DIR="/boot/grub"
else
    echo "GRUB directory not found."
    exit 1
fi

THEME_DIR="${GRUB_DIR}/themes/devil-transparent-grub"

LATEST="$(find /var/backups -maxdepth 1 -type d \
    -name 'devil-boot-loader-*' \
    -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2- || true)"

if [[ -z "${LATEST:-}" || ! -f "$LATEST/grub.default" ]]; then
    echo "No universal installer backup was found."
    echo "Your original GRUB configuration was not automatically changed."
    exit 1
fi

cp -a "$LATEST/grub.default" /etc/default/grub
rm -rf "$THEME_DIR"

if command -v update-grub >/dev/null 2>&1; then
    update-grub
elif command -v grub2-mkconfig >/dev/null 2>&1; then
    if [[ -d /boot/grub2 ]]; then grub2-mkconfig -o /boot/grub2/grub.cfg; else grub2-mkconfig -o /boot/grub/grub.cfg; fi
elif command -v grub-mkconfig >/dev/null 2>&1; then
    grub-mkconfig -o "${GRUB_DIR}/grub.cfg"
else
    echo "ERROR: No GRUB configuration generator was found."
    exit 1
fi

echo "✓ Previous GRUB configuration restored."
