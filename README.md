# Devil Boot Loader Theme

A clean Garuda Linux GRUB customization that keeps the original Garuda theme design while making the main menu frame transparent and allowing a custom background.

## What it does

- Preserves Garuda's original buttons and selected-item styling
- Preserves fonts, icons, menu layout and spacing
- Removes only the large outer `boot_menu` frame
- Uses the project's custom Devil background
- Creates a backup before changing `/etc/default/grub`
- Does **not** run `pacman -Syu`
- Asks before overwriting an existing installation
- Supports easy uninstall/restore

## One-command install

GitHub Pages is deployed from the **`docs/` folder** on the `main` branch.

```bash
curl -fsSL https://lover-of-darkness.github.io/Devil-Boot-Loader-Theme/install.sh | sudo bash
```

Fallback using GitHub Raw:

```bash
curl -fsSL https://raw.githubusercontent.com/Loverof-Darkness/Devil-Boot-Loader-Theme/main/install.sh | sudo bash
```

The Pages installer is located at `docs/install.sh`. It fetches the background directly from the repository, so the background image does not need to be duplicated inside `docs/`.

If the theme is already installed, the installer asks:

```text
Do you want to reinstall/overwrite it? [y/N]:
```

Press `y` to reinstall or press Enter/`N` to cancel.

## GitHub Pages setup

In GitHub go to:

**Settings → Pages → Build and deployment**

Set:

```text
Source: Deploy from a branch
Branch: main
Folder: /docs
```

Then save. The Pages installer URL is:

```text
https://lover-of-darkness.github.io/Devil-Boot-Loader-Theme/install.sh
```

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

1. Downloads the custom background.
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
- Testing on different Garuda/Linux systems
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
