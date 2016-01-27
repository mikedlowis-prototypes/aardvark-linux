#!/bin/sh

# Load the config file
. ./config.sh

# Mount virtual filesystems
mount -t proc proc "$AL_ROOT/proc"
mount --rbind /sys "$AL_ROOT/sys"
mount --make-rslave "$AL_ROOT/sys"
mount --rbind /dev "$AL_ROOT/dev"
mount --make-rslave "$AL_ROOT/dev"

# Setup env variables
export PATH=/bin:/tools/bin

# Enter the chroot
chroot "$AL_ROOT" /bin/sh

# Cleanup afterwards
umount -l "$AL_ROOT/proc"
umount -l "$AL_ROOT/sys"
umount -l "$AL_ROOT/dev"

