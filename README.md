# Devil Boot Loader Theme

A clean Garuda Linux GRUB customization that keeps the original Garuda theme design while making the main menu frame transparent and allowing a custom background.

## What it does

- Preserves Garuda's original buttons and selected-item styling
- Preserves fonts, icons, menu layout and spacing
- Removes only the large outer `boot_menu` frame
- Uses the project's custom Devil background
- Creates a backup before changing `/etc/default/grub`
- Does **not** run `pacman -Syu`
- Supports easy uninstall/restore

## One-command install

### GitHub Pages

```bash
curl -fsSL https://lover-of-darkness.github.io/Devil-Boot-Loader-Theme/install.sh | sudo bash
```

### GitHub Raw

```bash
curl -fsSL https://raw.githubusercontent.com/Loverof-Darkness/Devil-Boot-Loader-Theme/main/install.sh | sudo bash
```

Both commands install the same theme. GitHub Pages is the recommended command because it is shorter and easier to remember.

The installer automatically detects the installed Garuda GRUB theme, clones it, replaces the background, makes the outer menu transparent, and regenerates GRUB.

## Uninstall

Clone the repository or download `uninstall.sh`, then run:

```bash
sudo ./uninstall.sh
```

The installer restores the latest backup it created.

## Custom background

Replace:

```text
theme/devil-background.png
```

with your own image while keeping the exact filename.

Recommended:

```text
1920x1080 PNG
```

The next installation will automatically use the new image.

## Requirements

- Garuda Linux
- Installed Garuda GRUB theme
- UEFI/GRUB setup
- `curl` or `wget`
- Python 3

## How it works

The installer detects the currently configured Garuda theme and clones it to:

```text
/boot/grub/themes/garuda-transparent-menu/
```

Then it:

1. Downloads `theme/devil-background.png`.
2. Replaces only the theme's desktop background.
3. Removes only `menu_pixmap_style` from the `boot_menu` block.
4. Leaves `item_pixmap_style` and `selected_item_pixmap_style` unchanged.
5. Points `GRUB_THEME` to the cloned theme.
6. Runs `update-grub`.

The original theme under `/usr/share/grub/themes/` is not modified.

## Backup

Before changing the configuration, a backup is created at:

```text
/var/backups/garuda-transparent-grub-TIMESTAMP/
```

## License

MIT. See `LICENSE`.
