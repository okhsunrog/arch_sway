#!/bin/bash

pkill udiskie
pkill udisksd

rmmod pcspkr

_drive=$1
hsname="${2:-archzfs}"
ping -c 1 archlinux.org || { echo "No internet connection!"; exit; }

if [[ $EUID -ne 0 ]]; then    
    echo "You must be a root user to run this." 2>&1    
    exit 1    
fi

# make sure drive exists    
if [[ ! -b "${_drive}" ]]; then    
    echo "Block device ${_drive} not found, or is not a block device!" 2>&1    
    echo "Usage: ${0} disk_path" 2>&1             
    exit 1    
fi

#-------------------------------------------------

umount -R /mnt/install
umount /mnt/install/efi
zfs umount -a
zfs umount zroot/ROOT/default
zpool export zroot
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

timedatectl set-ntp true
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/g' /etc/pacman.conf
reflector --verbose --sort rate --protocol https --country Germany,UK,Poland,Netherlands --age 3 --save /etc/pacman.d/mirrorlist

#-------------------------

dd if=/dev/zero bs=512 count=34 status=progress oflag=sync of=${_drive}
dd if=/dev/zero of=${_drive} bs=512 count=34 seek=$((`blockdev --getsz ${_drive}` - 34))

cat <<EOF | gdisk ${_drive} 
o
y
n
1

+500M
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
             -R /mnt/install           \
             -O compression=lz4        \
						 -O encryption=aes-256-gcm \
             -O keyformat=passphrase   \
             -O keylocation=prompt     \
             zroot /dev/disk/by-partlabel/rootpart
sync
zfs create -o canmount=off -o mountpoint=none zroot/data
zfs create -o canmount=off -o mountpoint=none zroot/ROOT
zfs create -o mountpoint=/ -o canmount=noauto zroot/ROOT/default
zfs create -o mountpoint=/home zroot/data/home
zfs create -o mountpoint=/root zroot/data/home/root
zfs create -o mountpoint=/var -o canmount=off     zroot/var
zfs create                                        zroot/var/log
zfs create -o mountpoint=/var/lib -o canmount=off zroot/var/lib
zfs create                                        zroot/var/lib/libvirt
zfs create																				zroot/var/lib/AccountsService
zfs create																				zroot/var/lib/NetworkManager
zfs create                                        zroot/var/lib/docker
zfs create                                        zroot/var/cache
zfs create -o mountpoint=/vm                      zroot/vm
zpool export zroot
zpool import -d /dev/disk/by-partlabel/rootpart -R /mnt/install zroot -N
zfs load-key zroot
zfs mount zroot/ROOT/default
zfs mount -a
zpool set cachefile=/etc/zfs/zpool.cache zroot
mkdir -p /mnt/install/etc/zfs/
mkdir /mnt/install/new_root
cp /etc/zfs/zpool.cache /mnt/install/etc/zfs/zpool.cache

#------------------------------

mount -o X-mount.mkdir LABEL=EFI /mnt/install/efi
#genfstab -L /mnt/install > /mnt/install/etc/fstab
echo "LABEL=EFI           	/efi     	vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro	0 2

/ /new_root none bind 0 0
" > /mnt/install/etc/fstab
pacstrap /mnt/install base base-devel openssl-1.1 linux-firmware intel-ucode man-db man-pages neovim networkmanager

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
umount /mnt/install/efi
zfs umount -a
zfs umount zroot/ROOT/default
sleep 1
zfs mount zroot/ROOT/default
sed -Ei "s|/mnt/install/?|/|" /mnt/install/etc/zfs/zfs-list.cache/zroot
zfs umount zroot/ROOT/default
zfs snapshot zroot/ROOT/default@install
zfs snapshot zroot/data/home@install
zpool export zroot

echo "You may now reboot."
