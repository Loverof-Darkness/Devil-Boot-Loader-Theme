# Devil Boot Loader Theme

A universal GRUB customization with a transparent main menu and Devil background. On Garuda Linux it preserves the installed Garuda theme's buttons, icons, fonts and layout; on other GRUB-based Linux systems it uses the project's standalone theme.

## What it does

- Transparent main menu / outer frame
- Custom Devil background
- Preserves Garuda's original buttons, selected-item styling, fonts, icons and layout when a Garuda theme is installed
- Provides a standalone fallback theme for non-Garuda GRUB systems
- Creates a backup before changing `/etc/default/grub`
- Does **not** run `pacman -Syu` or perform a system upgrade
- Asks before overwriting an existing Devil Boot Loader installation
- Supports uninstall/restore

## One-command install

### GitHub Pages — recommended

GitHub Pages should be configured to deploy from the **`main` branch → `/docs` folder**.

```bash
curl -fsSL https://lover-of-darkness.github.io/Devil-Boot-Loader-Theme/install.sh | sudo bash
```

### GitHub Raw — fallback

If GitHub Pages is unavailable or still deploying, use:

```bash
curl -fsSL https://raw.githubusercontent.com/Loverof-Darkness/Devil-Boot-Loader-Theme/main/install.sh | sudo bash
```

The installer automatically chooses the appropriate theme mode:

- **Garuda:** clones the installed Garuda theme and makes only the outer menu transparent.
- **Other GRUB-based Linux:** installs the project's standalone Devil GRUB theme.

If the Devil theme is already installed, the installer asks:

```text
Devil Boot Loader Theme is already installed.
Do you want to reinstall/overwrite it? [y/N]:
```

Press `y` to reinstall or press Enter/`N` to cancel.

## GitHub Pages deployment

In GitHub open:

**Settings → Pages → Build and deployment**

Set exactly:

```text
Source: Deploy from a branch
Branch: main
Folder: /docs
```

Save the settings and wait for the Pages deployment to complete. The public installer URL is:

```text
https://lover-of-darkness.github.io/Devil-Boot-Loader-Theme/install.sh
```

The Pages installer is stored at `docs/install.sh`. It downloads the background from the repository's `main` branch, so the background does not need to be duplicated into `docs/`.

## Uninstall

Download/clone the repository and run:

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

Both installers fetch the current background automatically.

## Requirements

- A GRUB-based Linux installation
- `curl` or `wget`
- Python 3 for theme processing
- `sudo` privileges

For Garuda-specific styling, an installed Garuda GRUB theme is required. Other systems use the standalone fallback theme.

## How it works

The installer first checks whether the Devil theme is already installed. It then backs up `/etc/default/grub`.

On Garuda, it detects the installed Garuda theme and clones it to:

```text
/boot/grub/themes/garuda-transparent-menu/
```

It then:

1. Downloads the custom background.
2. Replaces only the theme's desktop background.
3. Removes only `menu_pixmap_style` from the `boot_menu` block.
4. Leaves `item_pixmap_style` and `selected_item_pixmap_style` unchanged.
5. Points `GRUB_THEME` to the cloned theme.
6. Regenerates `grub.cfg`.

On non-Garuda systems, the installer uses a standalone theme instead of requiring Garuda assets.

The original Garuda theme under `/usr/share/grub/themes/` is not modified.

## Backup

Before changing the configuration, a backup is created at:

```text
/var/backups/garuda-transparent-grub-TIMESTAMP/
```

---

# Support the Project

Thank you for using **Devil Boot Loader Theme**.

If this project is useful to you and you would like to support its development, you can optionally contribute through UPI.

## UPI Support

### UPI / Payment ID

```text
788888988
```

You can copy the payment ID and enter it in your UPI application. **Always verify the recipient details displayed by your UPI app before completing a payment.**

### Scan & Pay

The project's QR code is stored directly in the repository:

**[Open / Scan the UPI QR Code](docs/upi-qr.png)**

The QR image contains the payment information. Verify the recipient details shown by your UPI app before paying.

## Suggested Support Amounts

| Amount | Support type |
|---:|---|
| ₹50 | Coffee Support |
| ₹100 | Developer Support |
| ₹250 | Project Support |
| ₹500 | Strong Support |

These are only suggestions. Any voluntary support is appreciated.

## Where Your Support Helps

Your support can help with:

- GRUB theme development
- Testing on different Linux systems
- New backgrounds and visual improvements
- Documentation
- Maintenance and bug fixes
- Future improvements to the project

## Payment Safety

Please **verify the recipient name and payment details displayed by your UPI application before completing a transaction**. Do not rely only on the payment ID or QR image displayed in this repository.

## Thank You

Every contribution helps keep **Devil Boot Loader Theme** maintained and freely available.

**Thank you for supporting the project.**

## License

MIT. See `LICENSE`.
