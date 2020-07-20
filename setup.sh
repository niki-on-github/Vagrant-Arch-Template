#!/bin/sh

LOCALE="de_DE.UTF-8"
MIRROR="Germany"
LANG="de_DE.UTF-8"
KEYMAP="de-latin1"
X11_KEYMAP="de pc105"
LOCALTIME="/usr/share/zoneinfo/Europe/Berlin"

setup_timezone() {
    rm -f /etc/localtime
    ln -sf $LOCALTIME /etc/localtime
    timedatectl set-ntp true
}

setup_locale() {
    sed -i 's/#'"$LOCALE"' UTF-8/'"$LOCALE"' UTF-8/g' /etc/locale.gen
    locale-gen
    echo "LANG=$LANG" > /etc/locale.conf
    export LANG=$LANG
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
}

setup_pacman() {
    sed -i "s/^#Color/Color/" /etc/pacman.conf
    pacman -Sy --noconfirm --needed reflector
    reflector --country "$MIRROR" -l 30 --sort rate --save /etc/pacman.d/mirrorlist
    pacman-key --refresh-keys
    pacman -S --noconfirm --needed archlinux-keyring
}

setup_kde() {
    pacman -S --noconfirm --needed dolphin dolphin-plugins konsole plasma-nm plasma sddm sddm-kcm
    pacman -Rdd --noconfirm discover
    systemctl enable -f sddm
    balooctl disable
    localectl set-keymap $KEYMAP
    localectl set-x11-keymap $X11_KEYMAP
    localectl set-locale LANG=$LANG
}

resize_disk() {
    pacman -S --noconfirm --needed parted expect
    expect -c "spawn parted /dev/sda; send \"resizepart 2 -1\rYes\r-1\rq\r\"; expect eof"
    resize2fs /dev/sda2
}

# MAIN
setup_timezone
setup_locale
setup_pacman
setup_kde
resize_disk
