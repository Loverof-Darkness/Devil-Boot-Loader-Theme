# Devil Boot Loader Theme — Universal GRUB Branch

This branch is the **distro-independent GRUB version** of Devil Boot Loader Theme.

It keeps the same project background and visual concept as the main branch, but it does **not** look specifically for Garuda's GRUB theme.

Instead, the installer detects the GRUB theme already installed on the user's Linux system, clones it, applies the project background, and removes only the large outer `boot_menu` frame so the menu becomes transparent.

## Supported target

Any Linux distribution that uses **GRUB** and has an installed GRUB theme.

Examples include Arch-based, Debian-based, Fedora-based and other distributions using GRUB.

This branch does **not** install GRUB itself and does not replace a distro's existing theme design.

## One-command installation

Use the universal branch directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/Loverof-Darkness/Devil-Boot-Loader-Theme/universal-grub/install.sh | sudo bash
```

The installer:

1. Detects `/boot/grub` or `/boot/grub2`.
2. Reads the current `GRUB_THEME` from `/etc/default/grub`.
3. Falls back to searching common GRUB theme directories when necessary.
4. Clones the detected theme without modifying the original.
5. Downloads the same project background from this branch.
6. Replaces only the background image.
7. Removes only `menu_pixmap_style` from `boot_menu` blocks.
8. Leaves the theme's individual item and selected-item styling unchanged.
9. Updates `GRUB_THEME` to the cloned theme.
10. Regenerates GRUB using `update-grub`, `grub2-mkconfig`, or `grub-mkconfig`.

## Reinstall behavior

If the universal version is already installed, the installer asks:

```text
Do you want to reinstall/overwrite it? [y/N]:
```

- `y` / `Y` / `yes` → reinstall
- Enter / `N` → cancel safely

## Important

This branch requires an **existing GRUB theme**. It intentionally preserves the distro's current theme instead of forcing Garuda-specific assets onto another Linux distribution.

If no GRUB theme is detected, the installer stops and explains what is missing.

## Backup

Before changing `/etc/default/grub`, the installer creates a timestamped backup under:

```text
/var/backups/devil-boot-loader-TIMESTAMP/
```

## No system upgrade

The installer does **not** run:

```text
pacman -Syu
```

and does not install unrelated packages.

## Background

The same project background is used as the main branch:

```text
 theme/devil-background.png
```

Replace that file on this branch with another image of the same filename if you want a different wallpaper.

Recommended image: **1920×1080 PNG**.

## GitHub Pages

The universal branch also contains a copy of the installer under `docs/install.sh`.

To deploy this branch with GitHub Pages, use:

```text
Branch: universal-grub
Folder: /docs
```

Otherwise, the Raw GitHub command above is the simplest installation method.

## Restore / uninstall

Use the repository's `uninstall.sh` from this branch after downloading/cloning the branch:

```bash
sudo ./uninstall.sh
```

The uninstall script restores the latest backup created by this installer.

## Support

For project support information, see the support section at the bottom of the README on the main branch.

## License

MIT. See `LICENSE`.
