![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/SavageCore/xone-steam-deck-installer/test.yml?style=for-the-badge&label=ShellCheck)
 ![GitHub Downloads (specific asset, all releases)](https://img.shields.io/github/downloads/SavageCore/xone-steam-deck-installer/xone_install_or_update.sh?style=for-the-badge)

# Decky Plugin

I've just released a Decky plugin with the same functionailty! Please see more information in the [repo](https://github.com/SavageCore/xone-decky-plugin)! 🎉🚀

# Donate

Enjoying this script? Consider buying me a beer/coffee!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/E1E6P7VIQ)

First time setting up your Deck? You may enjoy my [setup guide](https://gist.github.com/SavageCore/eeb8b6ba032c0865e5c2a9eb8e073ab5). It'll get you started on Emulation.

# xone Driver installation script for Steam Deck

A fork of [cdleveille's](https://gist.github.com/cdleveille/e84c235c6e8c17042d35a7c0d92cdc96) script. With additional features and improvements.

- Support for SteamOS 3.5+
- Added zenity for a basic "GUI"
- Added sudo check
- Added various checks to prevent the script from redoing things that are already done
- Ensure the module is loaded after install and on boot
- Return `steamos-readonly` to its previous state after install
- Allow Xbox 360 controllers by installing [xpad-noone](https://github.com/forkymcforkface/xpad-noone) which removes Xbox One support from the standard Linux `xpad` driver and allows it to coexist with `xone`

# Installation ⬇️

1. Switch to [Desktop mode](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C)
2. Launch Konsole
3. Run `wget -O /tmp/bootstrap.sh https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/bootstrap.sh && sh /tmp/bootstrap.sh`

⚠️ If you have problems during install please read this [pinned issue](https://github.com/SavageCore/xone-steam-deck-installer/issues/1).

## Pairing 👫

You can enable (1) and disable (0) pairing mode with the included Desktop shortcuts, saving you from getting up and pressing that button! There's also the following command:

`echo 1 | sudo tee /sys/bus/usb/drivers/xone-dongle/*/pairing`

> Note: This currently seems to be broken, tracking [here](https://github.com/dlundqvist/xone/issues/111).

# Updating 🔄

1. Switch to [Desktop mode](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C)
2. Click the Install/Update Xone icon on your desktop

# Uninstalling ❌

1. Switch to [Desktop mode](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C)
2. Launch Konsole
3. Run `wget -O /tmp/xone_uninstall.sh https://github.com/SavageCore/xone-steam-deck-installer/raw/refs/heads/main/src/xone_uninstall.sh && sh /tmp/xone_uninstall.sh`

# Troubleshooting 🛠️

1. Switch to [Desktop mode](https://help.steampowered.com/en/faqs/view/671A-4453-E8D2-323C)
2. Click the Install/Update Xone (DEBUG) icon on your desktop
3. Please search for an existing [issue](https://github.com/SavageCore/xone-steam-deck-installer/issues) then post a [new](https://github.com/SavageCore/xone-steam-deck-installer/issues/new) one if you can't find it! You can also pop by my [Discord](https://discord.gg/MxMFhsKrZd) and leave a message in #xone-install-script
4. This script was originally a [Gist](https://gist.github.com/SavageCore/263a3413532bc181c9bb215c8fe6c30d) so you may find some useful information in the comments there too.
