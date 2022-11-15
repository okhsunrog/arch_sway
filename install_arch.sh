#!/bin/bash

pkill udiskie
pkill udisksd

rmmod pcspkr

_drive=/dev/disk/by-id/$1
ping -c 1 archlinux.org || { echo "No internet connection!"; exit; }

if [[ $EUID -ne 0 ]]; then    
    echo "You must be a root user to run this." 2>&1    
    exit 1    
fi

# make sure drive exists    
if [[ ! -b "${_drive}" ]]; then    
    echo "Block device ${_drive} not found, or is not a block device!" 2>&1    
    echo "Usage: ${0} disk_id" 2>&1             
    exit 1    
fi

#-------------------------------------------------

umount -R /mnt/install
umount ${_drive} &> /dev/null
umount ${_drive}p1 &> /dev/null
umount ${_drive}p2 &> /dev/null
umount ${_drive}p3 &> /dev/null
umount ${_drive}p4 &> /dev/null
umount ${_drive}1 &> /dev/null
umount ${_drive}2 &> /dev/null
umount ${_drive}3 &> /dev/null
umount ${_drive}4 &> /dev/null

#-------------------------------------------------

set -e

#--------------------------------------------------

read -p "Enter hostname: " hsname

#------------------------

timedatectl set-ntp true
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/g' /etc/pacman.conf

#-------------------------

dd if=/dev/zero bs=512 count=34 status=progress oflag=sync of=${_drive}
dd if=/dev/zero of=${_drive} bs=512 count=34 seek=$((`blockdev --getsz ${_drive}` - 34))

cat <<EOF | gdisk ${_drive} 
o
y
n
1

+200M
ef00
c
EFI
n
2


bf00
c
2
rootpart
w
y
EOF
sleep 1
partprobe $_drive
sync
sleep 3
mkfs.fat -I -F32 -n EFI /dev/disk/by-partlabel/EFI
zpool create -f -o ashift=12         \
             -O acltype=posixacl       \
             -O relatime=on            \
             -O xattr=sa               \
						 -o autotrim=on						 \
             -O dnodesize=auto         \
             -O normalization=formD    \
             -O mountpoint=none        \
             -O canmount=off           \
             -O devices=off            \
             -R /mnt                   \
             -O compression=zstd       \
             zroot $_drive
sync

exit
#------------------------------

o=X-mount.mkdir,ssd,discard=async,noatime
mkdir -p /mnt/install
mount LABEL=system /mnt/install
btrfs subvolume create /mnt/install/@
btrfs subvolume create /mnt/install/@home
btrfs subvolume create /mnt/install/@swap
btrfs subvolume create /mnt/install/@snapshots_root
btrfs subvolume create /mnt/install/@snapshots_home
btrfs subvolume create /mnt/install/@log
btrfs subvolume create /mnt/install/@vm
btrfs subvolume create /mnt/install/@cache
btrfs subvolume create /mnt/install/@docker
umount -R /mnt/install
mount -o subvol=@,$o LABEL=system /mnt/install
mount -o subvol=@home,$o LABEL=system /mnt/install/home
mount -o subvol=@swap,$o LABEL=system /mnt/install/swap
mount -o subvol=@snapshots_home,$o LABEL=system /mnt/install/home/.snapshots
mount -o subvol=@snapshots_root,$o LABEL=system /mnt/install/.snapshots
mount -o subvol=@log,$o LABEL=system /mnt/install/var/log
mount -o subvol=@vm,$o LABEL=system /mnt/install/vm
mount -o subvol=@cache,$o LABEL=system /mnt/install/var/cache
mount -o subvol=@docker,$o LABEL=system /mnt/install/var/lib/docker
mount -o X-mount.mkdir LABEL=EFI /mnt/install/efi
mkdir /mnt/install/etc
genfstab -L /mnt/install > /mnt/install/etc/fstab
pacstrap /mnt/install base base-devel linux-firmware btrfs-progs intel-ucode man-db man-pages neovim networkmanager

#-----------------------------

echo $hsname > /mnt/install/etc/hostname
echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	${hsname}.localdomain	${hsname}" > /mnt/install/etc/hosts
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /mnt/install/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/install/etc/locale.conf 

#-------------------------------

cp s_part.sh /mnt/install
cp after_install.sh /mnt/install
cp -r .config /mnt/install
cp -r .local /mnt/install
cp -r Wallpapers /mnt/install
cp -r snapper /mnt/install
cp .gtkrc-2.0 /mnt/install
cp .z1 /mnt/install/.zshrc
cp .z2 /mnt/install/.zprofile
#cp -r net /mnt/install

chmod +x /mnt/install/after_install.sh
chmod +x /mnt/install/s_part.sh
arch-chroot /mnt/install ./s_part.sh
rm /mnt/install/s_part.sh
sleep 1
echo "All done! Attemping unmount..."

sync
umount -R /mnt/install
sync

echo "You may now reboot."
