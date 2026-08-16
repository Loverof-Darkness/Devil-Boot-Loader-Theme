# Garuda Transparent GRUB Theme

A minimal customization for Garuda Linux:

- Keeps the installed Garuda theme's buttons, icons, fonts and menu layout.
- Removes only the large outer `boot_menu` frame.
- Keeps the individual menu-item and selected-item styling.
- Uses a custom full-HD background.
- Does not run a system update.
- Creates a backup before changing `/etc/default/grub`.

## One-command installation

After this repository is uploaded to GitHub, the installer can be run with:

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/main/install.sh | sudo bash
```

The repository owner/name placeholder will be replaced in the final command after the GitHub repository URL is known.

## Uninstall

Clone/download the repository and run:

```bash
sudo ./uninstall.sh
```

The installer restores the latest backup it created.

## Requirements

- Garuda Linux / Arch-based Garuda installation
- An installed Garuda GRUB theme
- UEFI/GRUB setup
- `curl` or `wget`
- Python 3 (normally present on Garuda)

## How it works

The installer detects the currently configured Garuda GRUB theme, clones its complete theme directory to:

```text
/boot/grub/themes/garuda-transparent-menu/
```

It then:

1. Replaces only the theme's desktop background.
2. Removes only `menu_pixmap_style` from the `boot_menu` block.
3. Leaves `item_pixmap_style` and `selected_item_pixmap_style` unchanged.
4. Points `GRUB_THEME` to the cloned theme.
5. Runs `update-grub`.

The original theme in `/usr/share/grub/themes/` is not modified.

## Custom background

Replace:

```text
theme/background.png
```

with your own image.

Recommended:

```text
1920x1080 PNG
```

Keep the filename exactly:

```text
background.png
```

## No system upgrade

The installer does NOT execute:

```text
pacman -Syu
```

It only modifies the GRUB theme configuration and regenerates `grub.cfg`.

## Safety

Before changing the configuration, the installer creates:

```text
/var/backups/garuda-transparent-grub-TIMESTAMP/
```

with a copy of `/etc/default/grub`.

## License

MIT. See `LICENSE`.
