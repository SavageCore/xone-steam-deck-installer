# Changelog

### 0.13.0

 - Add an automated workaround for mismatched kernel headers. This should help people with [#1](https://github.com/SavageCore/xone-steam-deck-installer/issues/1)

### 0.12.4

 - Determine latest release from GitHub tags not by parsing the script

### 0.12.3

 - Fix xpad-noone version number to match the actual version

### 0.12.2

 - Update to support forkmcforkface's renamed xpad-noone, no longer conflicts with xpad
 - Automatically determine the Linux version for downloading the correct headers package. Possibly no more updates each time there's a major SteamOS update!

### 0.12.1

 - Fix autoloading of new xpad-noone

### 0.12.0

 - Update xpad-noone to use the new fork (https://github.com/forkymcforkface/xpad-noone)

### 0.11.1

 - Fix firmware installation script path

### 0.11.0

 - Move to a GitHub repository, functionality is the same as 0.10.0

### 0.10.0

 - Support SteamOS 3.7
 - Ensure the correct repo is used for the xone driver

### 0.9.0

 - Support SteamOS 3.6

### 0.8.0

 - Add shortcuts to the Desktop to enable / disable pairing mode on the adapter

### 0.7.13
 - Ensure local repo is "clean" so that git pull can correctly update.

### 0.7.12
 - When running as debug, force the drivers to reinstall
 - Debug output is less verbose. No need to see all the pacman keys.

### 0.7.11
 - Ensure old kernel headers are removed when the user has upgraded to 3.5.
 Found at [Reddit](https://www.reddit.com/r/SteamDeck/comments/17lj4j6/installing_dkms_modules_fails/k7ekm0x/), potential fix for some.

### 0.7.10
 - Fix driver reinstallation in non debug mode
 - Better linux header install/update handling

### 0.7.9
 - Reinstate checks to prevent driver reinstallation
 - Add a function to handle the base-devel package group installation - you should no longer see errors

### 0.7.8
 - Revert "`steamos-readonly` should always be disabled". This results in an already read write error needlessly.

### 0.7.7
 - Fix driver update checks
 - Fix modprobe check which resulted in script exiting when install did infact happen

### 0.7.6
 - Test version, didn't fix anything

### 0.7.5
 - `steamos-readonly` should always be disabled
 - Exit script if either driver module failed to install

### 0.7.4
 - Fix required packages installation. There may not have been an issue or it was debug mode only or I'm going mad.

### 0.7.3
 - Fix `--populate` commands not running

### 0.7.2
 - Fix installs on latest SteamOS (3.5.1)

### 0.7.1
 - Fix broken package installs/updates

### 0.7.0
 #### Improve update process:
 - Only install required packages if they are not already installed
 - Update required packages if needed
 - Add xone installation function, skips if already installed
### 0.6.0
 - If the user has no sudo password, prompt for one and set it. This script should now work on first boot of a Deck without any previous steps taken.

### 0.5.2
 - Fix kernel installation - forgot to answer yes to the prompt...

### 0.5.1
 - Remove kernel headers installation from required packages as we now handle that in a dedicated step

### 0.5.0
 - Added support for SteamOS 3.5 - should now work on all SteamOS versions out of the box

### 0.4.0
 - Added [xpad-noone](https://github.com/medusalix/xpad-noone) to restore Xbox and Xbox 360 controller support. Now working with [GP2040-CE](https://github.com/OpenStickCommunity/GP2040-CE) devices!

### 0.3.0
 - Added `--debug` argument to show the output of every command, an additional desktop shortcut is also created for this

### 0.2.1
 - Implement basic semver comparison

### 0.2.0
 - Added auto update check

### 0.1.0
 - Initial release
