#!/bin/bash
# xone install or update script for SteamOS
# by SavageCore, forked from cdleveille's original script on Gist.
#
# https://github.com/SavageCore/xone-steam-deck-installer
# Script version 0.13.0

# Set xone local repo location
XONE_LOCAL_REPO="/home/deck/repos/xone"
XPAD_NOONE_LOCAL_REPO="/home/deck/repos/xpad-noone"
# Set xone remote repo location
# dlundqvist is maintaining a fork that contains PRs that have not been merged into the main repo
# main repo: https://github.com/medusalix/xone
XONE_REMOTE_REPO="https://github.com/dlundqvist/xone"
XPAD_NOONE_REMOTE_REPO="https://github.com/forkymcforkface/xpad-noone"
XPAD_NOONE_VERSION="1.0"

# DO NOT EDIT BELOW THIS LINE
SCRIPT_VERSION="0.13.0"
KEEP_READ_ONLY="false"
REDIRECT=">/dev/null 2>&1"
DEBUG="false"
CURRENT_USER=$(whoami)
REQUIRED_PACKAGES=("curl" "wget" "git" "gcc" "cabextract" "dkms" "libisl" "libmpc" "plymouth")
# If --debug is passed as an argument, enable debug mode
if [[ "$1" == "--debug" ]]; then
    REDIRECT=""
    DEBUG="true"
fi

# compare_semver: Compare two Semantic Versioning (SemVer) strings.
# Usage: compare_semver <version1> <version2>
compare_semver() {
    # Split version strings into major, minor, and patch segments.
    ver1_major=$(echo "$1" | cut -d '.' -f 1)
    ver1_minor=$(echo "$1" | cut -d '.' -f 2)
    ver1_patch=$(echo "$1" | cut -d '.' -f 3)

    ver2_major=$(echo "$2" | cut -d '.' -f 1)
    ver2_minor=$(echo "$2" | cut -d '.' -f 2)
    ver2_patch=$(echo "$2" | cut -d '.' -f 3)

    # Compare major versions.
    if [ "$ver1_major" -gt "$ver2_major" ]; then
        echo "1"
        return
    elif [ "$ver1_major" -lt "$ver2_major" ]; then
        echo "-1"
        return
    fi

    # Compare minor versions.
    if [ "$ver1_minor" -gt "$ver2_minor" ]; then
        echo "1"
        return
    elif [ "$ver1_minor" -lt "$ver2_minor" ]; then
        echo "-1"
        return
    fi

    # Compare patch versions.
    if [ "$ver1_patch" -gt "$ver2_patch" ]; then
        echo "1"
        return
    elif [ "$ver1_patch" -lt "$ver2_patch" ]; then
        echo "-1"
        return
    fi

    # Versions are equal.
    echo "0"
}

# Check for kernel header mismatch and offer workaround
# Returns 0 if mismatch detected and user wants to fix, 1 otherwise
check_kernel_header_mismatch() {
    local dkms_output="$1"

    # Check if the error message indicates missing kernel headers
    if echo "$dkms_output" | grep -q "Your kernel headers for kernel .* cannot be found"; then
        echo ""
        echo -e "\e[1;31mError: Kernel headers mismatch detected!\e[0m"
        echo ""
        echo "Your running kernel does not match the installed kernel headers."
        echo "This is a known issue on SteamOS after system updates."
        echo ""
        echo -e "\e[1mWorkaround:\e[0m"
        echo "1. Upgrade the kernel package to match the headers"
        echo "2. Reboot your Steam Deck"
        echo "3. Re-run this installer"
        echo ""

        # Prompt user to apply the fix
        if zenity --question --title="Kernel Headers Mismatch" \
            --text="A kernel headers mismatch was detected.\n\nWould you like to upgrade the kernel package and reboot?\n\nAfter rebooting, please run this installer again." \
            --ok-label="Upgrade & Reboot" --cancel-label="Cancel"; then

            echo -e "\e[1mUpgrading kernel package...\e[0m"
            echo ""

            # Get the linux-neptune package name (e.g., linux-neptune-611)
            local linux_pkg
            linux_pkg=$(pacman -Qsq linux-neptune | grep -E "^linux-neptune-[0-9]+$" | tail -n 1)

            if [ -n "$linux_pkg" ]; then
                if [[ $DEBUG == "true" ]]; then
                    echo "Upgrading package: $linux_pkg"
                fi

                if sudo pacman -S "$linux_pkg" --noconfirm; then
                    echo ""
                    echo -e "\e[1;32mKernel package upgraded successfully!\e[0m"
                    echo ""
                    zenity --info --title="Reboot Required" \
                        --text="The kernel has been upgraded.\n\nYour Steam Deck will now reboot.\n\nAfter rebooting, please run this installer again."

                    # Reboot the system
                    sudo reboot
                    exit 0
                else
                    echo -e "\e[1;31mFailed to upgrade kernel package.\e[0m"
                    zenity --error --title="Error" --text="Failed to upgrade the kernel package.\n\nPlease try manually running:\nsudo pacman -S $linux_pkg"
                fi
            else
                echo -e "\e[1;31mCould not determine kernel package name.\e[0m"
                zenity --error --title="Error" --text="Could not determine the kernel package name.\n\nPlease try manually running:\nsudo pacman -S linux-neptune-611"
            fi

            return 0
        fi

        # User cancelled
        zenity --warning --title="Installation Incomplete" \
            --text="The driver installation cannot continue without matching kernel headers.\n\nTo fix this manually:\n1. Run: sudo pacman -S linux-neptune-611\n2. Reboot\n3. Run this installer again"
        exit 1
    fi

    return 1
}

install_xone() {
    if [ -n "$(dkms status xone)" ]; then
        if [[ $DEBUG == "true" ]]; then
            echo ""
            echo "xone is already installed"
        fi

        return
    fi

    cd $XONE_LOCAL_REPO || {
        echo "Failed to cd into xone repo. Aborting..."
        read -n 1 -s -r -p "Press any key to exit"
        exit 1
    }

    echo -e "\e[1mInstalling xone...\e[0m"
    echo ""

    # Run the xone install script and capture output to check for errors
    local install_output
    install_output=$(sudo ./install.sh --release 2>&1)
    local install_exit_code=$?

    if [[ $DEBUG == "true" ]]; then
        echo "$install_output"
    fi

    # Check for kernel header mismatch error
    if check_kernel_header_mismatch "$install_output"; then
        return 1
    fi

    # Check if installation failed for other reasons
    if [ $install_exit_code -ne 0 ]; then
        echo -e "\e[1;31mxone installation failed with exit code $install_exit_code\e[0m"
        if [[ $DEBUG != "true" ]]; then
            echo "$install_output"
        fi
        read -n 1 -s -r -p "Press any key to exit"
        exit 1
    fi

    echo -e "\e[1mGetting xone firmware...\e[0m"
    echo ""
    eval sudo install/firmware.sh --skip-disclaimer "$REDIRECT"
}

uninstall_xone() {
    cd $XONE_LOCAL_REPO || {
        echo "Failed to cd into xone repo. Aborting..."
        read -n 1 -s -r -p "Press any key to exit"
        exit 1
    }

    # Run the xone uninstall script
    eval sudo ./uninstall.sh "$REDIRECT"
}

install_xpad_noone() {
    if [ -n "$(dkms status xpad-noone)" ]; then
        if [[ $DEBUG == "true" ]]; then
            echo "xpad-noone is already installed"
        fi

        return
    fi

    echo -e "\e[1mInstalling xpad-noone...\e[0m"
    echo ""

    sudo modprobe -r xpad-noone 2>/dev/null || true
    eval sudo cp -r "$XPAD_NOONE_LOCAL_REPO" /usr/src/xpad-noone-$XPAD_NOONE_VERSION "$REDIRECT"

    # Run dkms install and capture output to check for errors
    local dkms_output
    dkms_output=$(sudo dkms install -m xpad-noone -v $XPAD_NOONE_VERSION 2>&1)
    local dkms_exit_code=$?

    if [[ $DEBUG == "true" ]]; then
        echo "$dkms_output"
    fi

    # Check for kernel header mismatch error
    if check_kernel_header_mismatch "$dkms_output"; then
        return 1
    fi

    # Check if installation failed for other reasons
    if [ $dkms_exit_code -ne 0 ]; then
        echo -e "\e[1;31mxpad-noone installation failed with exit code $dkms_exit_code\e[0m"
        if [[ $DEBUG != "true" ]]; then
            echo "$dkms_output"
        fi
        read -n 1 -s -r -p "Press any key to exit"
        exit 1
    fi
}

uninstall_xpad_noone() {
    if [ -n "$(dkms status xpad-noone)" ]; then
        eval sudo dkms remove -m xpad-noone -v "$XPAD_NOONE_VERSION" --all "$REDIRECT"
        sudo rm -rf "/usr/src/xpad-noone-$XPAD_NOONE_VERSION"
    else
        echo 'Driver is not installed!'
    fi
}

# Install linux headers (if not already installed)
install_linux_headers() {
    echo -e "\e[1mChecking for linux headers...\e[0m"
    echo ""
    linux=$(pacman -Qsq linux-neptune | grep -e "[0-9]$" | tail -n 1)
    kernel_headers="$linux-headers"

    # 0 = true (remove), 1 = false (skip removal)
    remove_legacy_headers=1

    # Remove legacy 3.4 kernel headers package if installed
    if [[ $remove_legacy_headers -eq 0 ]] && pacman -Qs "linux-neptune-headers" >/dev/null; then
        if [[ $DEBUG == "true" ]]; then
            echo "Found old 3.4 kernel package - removing"
        fi
        sudo pacman -R linux-neptune-headers --noconfirm >/dev/null
    fi

    if [[ $DEBUG == "true" ]]; then
        echo "Using $kernel_headers package" "$REDIRECT"
    fi

    # Are the kernel headers already installed and up-to-date?
    if pacman -Qs "$kernel_headers" >/dev/null && ! pacman -Qu "$kernel_headers" >/dev/null; then
        if [[ $DEBUG == "true" ]]; then
            echo "Headers are already installed and up to date"
        fi
        return
    fi

    # If the headers are not installed or need updating, install them
    echo -e "\e[1mInstalling required kernel headers, this may take a while...\e[0m"
    echo ""
    eval sudo pacman -Sy "$kernel_headers" --noconfirm >/dev/null
}

install_base_devel() {
    # Get list of base-devel packages
    base_devel_packages=$(pacman -Sg base-devel | cut -d ' ' -f 2)

    # Check if any of the base-devel packages are missing or need updating
    for package in $base_devel_packages; do
        if pacman -Qs "$package" >/dev/null; then
            if pacman -Qu "$package" >/dev/null; then
                packages_to_update+=("$package")
            fi
        else
            packages_to_install+=("$package")
        fi
    done
}

install_pairing_shortcuts() {
    # If the pairing shortcuts are already installed (on desktop), exit
    if [ -f ~/Desktop/enable-pairing.desktop ] && [ -f ~/Desktop/disable-pairing.desktop ]; then
        if [[ $DEBUG == "true" ]]; then
            echo "Pairing shortcuts already installed"
        fi
        return
    fi

    # Download the pairing shortcuts
    curl -sSfL "https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/enable-pairing.desktop" >~/Desktop/enable-pairing.desktop || {
        echo "Failed to download enable-pairing.desktop."
    }

    curl -sSfL "https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/disable-pairing.desktop" >~/Desktop/disable-pairing.desktop || {
        echo "Failed to download disable-pairing.desktop."
    }
}

echo -e "\e[1mxone install script by SavageCore\e[0m"
echo -e "\e[1mVersion: $SCRIPT_VERSION\e[0m"
echo -e "\e[1mhttps://github.com/SavageCore/xone-steam-deck-installer/\e[0m"
echo "─────────────────────────────"
echo ""
echo "This script will install the xone and xpad-noone drivers for the Xbox wireless dongle and controller"
echo ""

# Check if script is up to date
# Get the latest release tag from GitHub API and remove leading 'v'
REQUIRED_VERSION=$(curl -sSfL "https://api.github.com/repos/SavageCore/xone-steam-deck-installer/releases/latest" | grep -Po '"tag_name": *"\K.*?(?=")' | sed 's/^v//')

# Only compare versions if both are non-empty
if [[ -n "$SCRIPT_VERSION" ]] && [[ -n "$REQUIRED_VERSION" ]]; then
    VERSION_DIFF=$(compare_semver "$SCRIPT_VERSION" "$REQUIRED_VERSION")
else
    VERSION_DIFF=0
fi

if [[ $VERSION_DIFF == -1 ]]; then
    echo -e "\e[1mYou have an outdated version of the script. Updating...\e[0m"
    echo ""

    # Download the latest version of the script from the release assets
    curl -sSfL "https://github.com/SavageCore/xone-steam-deck-installer/releases/latest/download/xone_install_or_update.sh" >/tmp/xone_install_or_update.sh || {
        echo "Failed to download the latest version of the script. Aborting..."
        read -n 1 -s -r -p "Press any key to exit"
        exit 1
    }

    # Preserve the current working directory and arguments
    PWD=$(pwd)
    ARGS=("$@")

    # Replace the current script with the new version
    mv /tmp/xone_install_or_update.sh "$0"

    read -n 1 -s -r -p "Press any key to relaunch the script..."
    clear
    # Re-run the script with the same environment variables and arguments
    cd "$PWD" || {
        echo "Failed to change directory. Aborting..."
        read -n 1 -s -r -p "Press any key to exit"
        exit 1
    }
    exec bash "$0" "${ARGS[@]}"
fi

# Does the user have a sudo password set?
# If not, prompt them to set one
if [ "$(passwd -S "$CURRENT_USER" | cut -d" " -f2)" != "P" ]; then
    echo -e "\e[1mA sudo password is required, please enter one now to create it\e[0m"
    PASSWORD=$(zenity --password --title="Password")
    CONFIRM_PASSWORD=$(zenity --password --title="Confirm password")

    # If the passwords don't match, exit
    if [ "$PASSWORD" != "$CONFIRM_PASSWORD" ]; then
        zenity --error --text="Passwords do not match\n\nExiting..." --title="Error"
        exit 1
    fi

    {
        echo -e "$PASSWORD\n$PASSWORD" | passwd
        # Elevate with sudo
        echo -e "$PASSWORD" | sudo -S echo "" "$REDIRECT"
    } &>/dev/null
fi

# Check if the user has sudo privileges
# If not, prompt the user for a password
if ! sudo -n true 2>/dev/null; then
    if ! zenity --password --title="Sudo password" | eval sudo -S echo "" "$REDIRECT"; then
        zenity --error --text="Sorry, you need to have sudo privileges to run this script." --title="Error"
        exit 1
    fi
fi

# Rename fakeroot.conf to avoid error
if [ -f /etc/ld.so.conf.d/fakeroot.conf ]; then
    sudo mv /etc/ld.so.conf.d/fakeroot.conf /etc/ld.so.conf.d/fakeroot.conf.bck
fi

# If output of `sudo steamos-readonly status` is "enabled", disable it
if [ "$(sudo steamos-readonly status)" == "enabled" ]; then
    sudo steamos-readonly disable
    KEEP_READ_ONLY="true"
fi

# If pacman-key is not initialised, initialise it
if ! eval pacman-key --list-keys >/dev/null 2>&1; then
    echo -e "\e[1mInitialising pacman...\e[0m"
    echo ""
    sudo pacman-key --init
fi

echo "Refreshing pacman keys..."
# Always populate archlinux and holo keys, quick enough to do every time
# TODO: Only populate if not already populated
sudo pacman-key --populate archlinux holo >/dev/null 2>&1

# Install linux headers (if not already installed)
install_linux_headers

packages_to_install=()
packages_to_update=()

# Check if the required packages are installed and if they have updates
for package in "${REQUIRED_PACKAGES[@]}"; do
    if pacman -Qs "$package" >/dev/null; then
        if pacman -Qu "$package" >/dev/null; then
            packages_to_update+=("$package")
        fi
    else
        packages_to_install+=("$package")
    fi
done

# Special case for base-devel, as it is a group, not a package
install_base_devel

# Are there any packages to install?
if [ ! ${#packages_to_install[@]} -eq 0 ]; then
    # Install the packages
    echo -e "\e[1mInstalling required packages, this may take a while...\e[0m"
    echo ""
    if [[ $DEBUG == "true" ]]; then
        echo "Packages to install: ${packages_to_install[*]}"
    fi

    # Install the packages
    for package in "${packages_to_install[@]}"; do
        if [[ $DEBUG == "true" ]]; then
            echo "Installing $package" "$REDIRECT"
        fi
        sudo pacman -S "$package" --noconfirm >/dev/null
    done
fi

# Are there any packages to update?
if [ ! ${#packages_to_update[@]} -eq 0 ]; then
    # Update the packages
    echo -e "\e[1mUpdating required packages, this may take a while...\e[0m"
    echo ""
    if [[ $DEBUG == "true" ]]; then
        echo "Packages to update: ${packages_to_update[*]}"
    fi

    # Update the packages
    for package in "${packages_to_update[@]}"; do
        if [[ $DEBUG == "true" ]]; then
            echo "Updating $package" "$REDIRECT"
        fi

        sudo pacman -S "$package" --noconfirm >/dev/null
    done
fi

if [ ${#packages_to_install[@]} -eq 0 ] && [ ${#packages_to_update[@]} -eq 0 ]; then
    echo -e "\e[1mRequired packages installed and up to date\e[0m"
    echo ""
fi

XONE_HAS_UPDATED=false
XPAD_HAS_UPDATED=false

# Does the xone local repo folder already exist?
if [ -d "$XONE_LOCAL_REPO" ]; then
    cd $XONE_LOCAL_REPO || {
        echo "Failed to cd into xone repo. Aborting..."
        read -n 1 -s -r -p "Press any key to exit"
        exit 1
    }

    # Check if the correct fork is being used
    current_remote=$(git remote get-url origin)
    expected_remote="$XONE_REMOTE_REPO"

    if [[ "$current_remote" != "$expected_remote" ]]; then
        echo -e "\e[1;33mWarning: The current xone repo is not from the expected fork:\e[0m"
        echo "  Current:  $current_remote"
        echo "  Expected: $expected_remote"
        echo ""
        echo -e "\e[1;33mDeleting the current xone repo and cloning the correct fork...\e[0m"
        echo ""
        cd "/home/deck/repos" || {
            echo "Failed to cd into /home/deck/repos. Aborting..."
            read -n 1 -s -r -p "Press any key to exit"
            exit 1
        }
        rm -rf "$XONE_LOCAL_REPO"
        echo -e "\e[1mCloning correct xone fork...\e[0m"
        echo ""
        eval git clone $XONE_REMOTE_REPO $XONE_LOCAL_REPO "$REDIRECT"
        cd "$XONE_LOCAL_REPO" || {
            echo "Failed to cd into newly cloned repo. Aborting..."
            read -n 1 -s -r -p "Press any key to exit"
            exit 1
        }
    fi

    # ...if yes, run the uninstall script, and pull down any new updates from the remote repo
    echo -e "\e[1mChecking for xone updates...\e[0m"
    echo ""

    # Ensure the repo is in a clean state for git pull
    eval git reset --hard "$REDIRECT"
    # Check for updates with git pull, and if there are updates, uninstall
    git_output=$(eval git pull)

    if [[ $git_output != *"Already up to date."* ]]; then
        uninstall_xone
        XPAD_HAS_UPDATED=true
    else
        echo "No updates available"
    fi
else
    # ...if not, clone the repo
    echo -e "\e[1mCloning xone repo...\e[0m"
    echo ""
    eval git clone $XONE_REMOTE_REPO $XONE_LOCAL_REPO "$REDIRECT"
    cd $XONE_LOCAL_REPO || {
        echo "Failed to clone xone repo. Aborting..."
        read -n 1 -s -r -p "Press any key to exit"
        exit 1
    }
fi

# Does the xpad-noone local repo folder already exist?
if [ -d "$XPAD_NOONE_LOCAL_REPO" ]; then
    # ...if yes, check if it's the old medusalix repo
    cd $XPAD_NOONE_LOCAL_REPO || {
        echo "Failed to cd into xpad-noone repo. Aborting..."
        read -n 1 -s -r -p "Press any key to exit"
        exit 1
    }

    current_remote=$(git remote get-url origin)
    old_remote="https://github.com/medusalix/xpad-noone"

    if [[ "$current_remote" == "$old_remote" ]]; then
        echo ""
        echo -e "\e[1mDeleting the old xpad-noone repo and cloning the forkymcforkface fork...\e[0m"
        echo ""
        # Uninstall the old xpad-noone driver
        modules=$(lsmod | grep '^xpad_noone' | cut -d ' ' -f 1 | tr '\n' ' ')
        if [ -n "$modules" ]; then
            eval sudo modprobe -r -a "$modules" "$REDIRECT"
        fi
        if [ -n "$(dkms status xpad-noone)" ]; then
            eval sudo dkms remove -m xpad-noone -v "1.0" --all "$REDIRECT"
            sudo rm -rf "/usr/src/xpad-noone-1.0"
        fi
        # Remove the old repo
        cd "/home/deck/repos" || {
            echo "Failed to cd into /home/deck/repos. Aborting..."
            read -n 1 -s -r -p "Press any key to exit"
            exit 1
        }
        rm -rf "$XPAD_NOONE_LOCAL_REPO"
        rm -f /etc/modules-load.d/xpad-noone.conf
        # Clone the new repo
        echo -e "\e[1mCloning xpad-noone...\e[0m"
        echo ""
        eval git clone $XPAD_NOONE_REMOTE_REPO $XPAD_NOONE_LOCAL_REPO "$REDIRECT"
        cd "$XPAD_NOONE_LOCAL_REPO" || {
            echo "Failed to cd into newly cloned repo. Aborting..."
            read -n 1 -s -r -p "Press any key to exit"
            exit 1
        }
        XPAD_HAS_UPDATED=true
    else
        # Check for updates with git pull
        echo -e "\e[1mChecking for xpad-noone updates...\e[0m"
        echo ""
        eval git reset --hard "$REDIRECT"
        git_output=$(eval git pull)
        if [[ $git_output != *"Already up to date."* ]]; then
            uninstall_xpad_noone
            XPAD_HAS_UPDATED=true
        else
            echo "No updates available"
        fi
    fi
else
    # ...if not, clone the repo
    echo -e "\e[1mCloning xpad-noone repo...\e[0m"
    echo ""
    eval git clone $XPAD_NOONE_REMOTE_REPO $XPAD_NOONE_LOCAL_REPO "$REDIRECT"
    cd $XPAD_NOONE_LOCAL_REPO || {
        echo "Failed to clone xpad-noone repo. Aborting..."
        read -n 1 -s -r -p "Press any key to exit"
        exit 1
    }
fi

# If debug, remove xone and xpad-noone to force a reinstall
if [[ $DEBUG == "true" ]]; then
    echo ""
    echo "Removing xone and xpad-noone to force a reinstall"
    echo ""
    if [ $XONE_HAS_UPDATED = "false" ]; then
        uninstall_xone
    fi
    if [ $XPAD_HAS_UPDATED = "false" ]; then
        uninstall_xpad_noone
    fi
fi

# Run the xone install function
install_xone

# Run the xpad-noone install function
install_xpad_noone

# Using lsmod check if xone_dongle is loaded, if not, load it
if ! lsmod | grep -q xone_dongle; then
    load_cmd="sudo modprobe -q xone_dongle"
    if [[ $DEBUG == "true" ]]; then
        load_cmd="sudo modprobe xone_dongle"
    fi

    # Load the xone dongle module, if it exists
    if ! $load_cmd; then
        echo "Failed to load xone_dongle module. Aborting..."
        read -n 1 -s -r -p "Press any key to exit"
        exit 1
    fi
    sudo touch /etc/modules-load.d/xone-dongle.conf
    echo "xone-dongle" | sudo tee /etc/modules-load.d/xone-dongle.conf >/dev/null 2>&1
fi

# Using lsmod check if xpad_noone is loaded, if not, load it
if ! lsmod | grep -q xpad_noone; then
    load_cmd="sudo modprobe -q xpad-noone"
    if [[ $DEBUG == "true" ]]; then
        load_cmd="sudo modprobe xpad-noone"
    fi

    # Load the xpad module, if it exists
    if ! $load_cmd; then
        echo "Failed to load xpad module. Aborting..."
        read -n 1 -s -r -p "Press any key to exit"
        exit 1
    fi

    sudo touch /etc/modules-load.d/xpad-noone.conf
    echo "xpad-noone" | sudo tee /etc/modules-load.d/xpad-noone.conf >/dev/null 2>&1
fi

# Ensure /etc/modules-load.d/xpad.conf does not exist
if [ -f /etc/modules-load.d/xpad.conf ]; then
    sudo rm /etc/modules-load.d/xpad.conf
fi

# Re enable steamos-readonly if it was enabled before
if [ $KEEP_READ_ONLY = "true" ]; then
    sudo steamos-readonly enable
fi

install_pairing_shortcuts

zenity --info \
    --text="Done. You may now plug in your controller/adapter."

# If debug wait for user input before exiting
if [ $DEBUG = "true" ]; then
    read -n 1 -s -r -p "Press any key to exit"
fi
