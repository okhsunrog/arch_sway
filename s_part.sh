#!/bin/bash
set -e

mkdir /mnt/nfs
locale-gen
hwclock --systohc
sed -i 's/# deny = 3/deny = 0/g' /etc/security/faillock.conf
sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -z - --threads=0)/g' /etc/makepkg.conf
sed -i 's/COMPRESSGZ=(gzip -c -f -n)/COMPRESSGZ=(pigz -c -f -n)/g' /etc/makepkg.conf
sed -i 's/COMPRESSBZ2=(bzip2 -c -f)/COMPRESSBZ2=(pbzip2 -c -f)/g' /etc/makepkg.conf
sed -i 's/COMPRESSZST=(zstd -c -z -q -)/COMPRESSZST=(zstd -c -z -q - --threads=0)/g' /etc/makepkg.conf
sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j8"/g' /etc/makepkg.conf
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
echo '#!/bin/sh
CP=/bin/cp
exec $CP --reflink=auto "$@"' > /usr/local/bin/cp
chmod +x /usr/local/bin/cp

#------------------

pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key FBA220DFC880C036
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
sed -i 's/#Color/Color\nILoveCandy/g' /etc/pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/g' /etc/pacman.conf
echo '
[multilib]
Include = /etc/pacman.d/mirrorlist

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist

[okhsunrog-aur]
SigLevel = Never
Server = https://okhsunrog.ru/repos/$repo

[okhsunrog-repo]
SigLevel = Never
Server = https://okhsunrog.ru/repos/$repo' >> /etc/pacman.conf
pacman -Syyuu

pacman -S archlinux-keyring linux-okhsunrog linux-okhsunrog-headers zfs-utils-okhsunrog --noconfirm

#--------------------
echo 'MODULES=""
BINARIES=""
FILES=""
HOOKS="base udev autodetect modconf block keyboard zfs filesystems"
COMPRESSION="zstd"' > /etc/mkinitcpio.conf

echo 'ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-okhsunrog"
ALL_microcode="/boot/*-ucode.img"

PRESETS=('default')

default_image="/boot/initramfs-linux-okhsunrog.img"
default_efi_image="/efi/arch.efi"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"

#fallback_config="/etc/mkinitcpio.conf"
fallback_image="/boot/initramfs-linux-okhsunrog-fallback.img"
fallback_options="-S autodetect"' > /etc/mkinitcpio.d/linux-okhsunrog.preset

echo "zfs=zroot/ROOT/default fbcon=font:TER16x32 zswap.enabled=0 bgrt_disable quiet loglevel=3 rw" > /etc/kernel/cmdline
echo "zfs=zroot/ROOT/restore fbcon=font:TER16x32 zswap.enabled=0 bgrt_disable rw" > /etc/kernel/cmdline_restore
rm /boot/initramfs*
mkinitcpio -p linux-okhsunrog

echo "EDITOR=nvim" >> /etc/environment
echo "LOCALE=en_US.UTF-8
KEYMAP=ru
FONT=ter-u16b
CONSOLEMAP=
TIMEZONE=Europe/Moscow
HARDWARECLOCK=UTC
USECOLOR=yes" > /etc/vconsole.conf

#--------------------------------------------

echo "Installing additional software..."
pacman -Syyuu --noconfirm
#arch repos
pacman -S networkmanager-openconnect xournalpp kicad kicad-library kicad-library-3d python-kikit python-pcbnewtransition texlive-most texlive-lang texlive-bibtexextra texlive-fontsextra thunar tumbler thunar-archive-plugin thunar-media-tags-plugin ark unarchiver electrum noto-fonts noto-fonts-cjk noto-fonts-extra virtualbox virtualbox-host-dkms virtualbox-guest-iso alsa-utils gtk-layer-shell zram-generator keepassxc qutebrowser brightnessctl lximage-qt wireplumber scrcpy intel-media-sdk openssl openssl-1.1 intel-media-driver intel-gpu-tools vulkan-intel libva-utils telegram-desktop vulkan-icd-loader vulkan-tools xorg-xrdb strawberry sof-firmware github-cli docker docker-compose openscad skanlite libvncserver remmina wayvnc exfatprogs nfs-utils tmux screen dex ddcutil i2c-tools archiso thunderbird bluez bluez-utils pacman-contrib smartmontools hdparm wayland-protocols hyphen-en hyphen gnome-keyring libgnome-keyring upower iotop f2fs-tools efitools efibootmgr dosfstools arch-install-scripts ruby-bundler pv alsa-firmware pipewire pipewire-alsa pipewire-jack pipewire-pulse xdg-desktop-portal xdg-desktop-portal-wlr yt-dlp mc translate-shell nm-connection-editor hunspell hunspell-en_us perl-file-mimeinfo swayidle mousepad cups cups-pdf usbutils inkscape go zsh i7z libappindicator-gtk3 lm_sensors stalonetray network-manager-applet gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly tor pigz pbzip2 android-udev libmad opus flac pcmanfm-qt speedtest-cli fzf tree broot lxappearance qt5-wayland noto-fonts-emoji acpi systembus-notify ttf-dejavu otf-font-awesome xmlto pahole inetutils bc terminus-font reflector rsync cronie wf-recorder imagemagick tk python-pip zathura zathura-djvu zathura-pdf-mupdf udiskie udisks2 htop qt5ct qt6ct meson ninja scdoc playerctl libreoffice-fresh xorg-server-xwayland ffmpeg jdk-openjdk jdk8-openjdk mpv imv openssh wget ttf-opensans git neofetch pavucontrol grim slurp jq wl-clipboard neofetch android-tools cpio lhasa lzop p7zip unace unrar unzip zip earlyoom highlight mediainfo odt2txt perl-image-exiftool --noconfirm --needed
#chaotic-aur
pacman -S anki nerd-fonts-jetbrains-mono swaylock-git librewolf ungoogled-chromium chromium-widevine slack-electron virtualbox-ext-oracle clipman fcft foot i3status-rust libdispatch gimp-git numix-icon-theme-git qt5-styleplugins systray-x-git yay zoom --noconfirm --needed
#my repos
pacman -Rnsdd xdg-utils --noconfirm
pacman -S tabletsettings-okhsunrog-git python-grip openhantek6022-git zrepl sway-okhsunrog ivpn python-emoji-fzf-okhsunrog wlr-sunclock-git electrum-ltc atool2-git aria2-fast cava gtk-theme-numix-solarized-git qt6gtk2-git handbrake-full handbrake-full-cli hunspell-ru-aot hyphen-ru lsix-git mako-no-blur-git mimeo ntfsprogs-ntfs3 puddletag qbittorrent-enhanced-qt5 ranger-sixel ruri swaykbdd sworkstyle throttled-git tiny-irc-client ttf-menlo-powerline-git ttf-ms-win11-okhsunrog ytop-okhsunrog-bin wlogout-git xdg-utils-mimeo zsh-vi-mode-git way-displays --noconfirm --needed

#------------------------------------------

chsh -s $(which zsh)
read -p "Enter root password: " -s rpass
echo "$rpass
$rpass" | passwd
echo "Creating a new user..."
read -p "Enter user name: " uname
useradd -mG wheel,video,uucp,i2c,lock,input,vboxusers -s /usr/bin/zsh $uname
read -p "Enter $uname password: " -s upass
echo "$upass
$upass" | passwd $uname
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
chown -R $uname:$uname /vm
#echo "ALL ALL = (root) NOPASSWD: /usr/bin/hdparm" >> /etc/sudoers

#----------------------------------------

#mkdir /etc/docker
#echo '{ "features": { "buildkit": true } }' > etc/docker/daemon.json

ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules

echo "#%PAM-1.0        
        
auth       required     pam_securetty.so        
auth       requisite    pam_nologin.so        
auth       include      system-local-login        
auth       optional     pam_gnome_keyring.so        
account    include      system-local-login        
session    include      system-local-login        
password   include      system-local-login        
session    optional     pam_gnome_keyring.so auto_start" >  /etc/pam.d/login
#curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/master/scripts/99-platformio-udev.rules | sudo tee /etc/udev/rules.d/99-platformio-udev.rules
#echo "i2c_dev" > /etc/modules-load.d/i2c.conf
echo 'ENV{ID_FS_USAGE}=="filesystem|other|crypto", ENV{UDISKS_FILESYSTEM_SHARED}="1"' > /etc/udev/rules.d/99-udisks2.rules
mkdir /etc/systemd/system/getty@tty1.service.d
echo "[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --login-options $uname --noclear %I $TERM" > /etc/systemd/system/getty@tty1.service.d/override.conf
cp /usr/lib/systemd/system/bluetooth.service /etc/systemd/system/
sed -i 's:ExecStart=/usr/lib/bluetooth/bluetoothd:ExecStart=/usr/lib/bluetooth/bluetoothd -E:g' /etc/systemd/system/bluetooth.service

sed -i 's/#export SAL_USE_VCLPLUGIN=gtk3/export SAL_USE_VCLPLUGIN=gtk3/g' /etc/profile.d/libreoffice-fresh.sh

#----------------------------------

systemctl enable NetworkManager  
systemctl enable earlyoom
systemctl enable zrepl
#systemctl enable sshd
systemctl enable docker
#systemctl enable nfs-server

#------------------------------------------

wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
mv install.sh /home/$uname/
su - $uname -c 'sh install.sh --unattended'
rm /home/$uname/install.sh
git clone https://github.com/zsh-users/zsh-completions /home/$uname/.oh-my-zsh/custom/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions /home/$uname/.oh-my-zsh/custom/plugins/zsh-autosuggestions

#----------------------------------------

zpool set cachefile=/etc/zfs/zpool.cache zroot
systemctl enable zfs-import-cache.service
systemctl enable zfs-import.target
mkdir -p /etc/zfs/zfs-list.cache
systemctl enable zfs.target
systemctl enable zfs-zed.service
touch /etc/zfs/zfs-list.cache/zroot
zed -F &
sleep 1
zfs set canmount=off zroot/vm
sleep 1
zfs set canmount=on zroot/vm
zgenhostid $(hostid)
mkinitcpio -p linux-okhsunrog
mkinitcpio -p linux-okhsunrog -- --cmdline=/etc/kernel/cmdline_restore --uefi=/efi/arch_restore.efi
cp /efi/arch.efi /efi/arch_bak.efi

#----------------------------------------

efibootmgr --create --disk /dev/disk/by-partlabel/EFI --loader /arch_restore.efi --label "Recover Arch Sway" --unicode
efibootmgr --create --disk /dev/disk/by-partlabel/EFI --loader /arch_bak.efi --label "Arch Sway backup kernel" --unicode
efibootmgr --create --disk /dev/disk/by-partlabel/EFI --loader /arch.efi --label "Arch Sway" --unicode
efibootmgr -D

#----------------------------------------

#configure pipewire

echo "stream.properties = {
    resample.quality      = 10
}
" > /etc/pipewire/client.conf.d/resampling.conf
echo "stream.properties = {
    resample.quality      = 10
}
" > /etc/pipewire/pipewire-pulse.conf.d/resampling.conf
echo "context.properties = {
    default.clock.allowed-rates = [ 44100 48000 88200 96000 192000 384000 ]
}
" > /etc/pipewire/pipewire.conf.d/resample_rates.conf

#-------------------------------------

#cp /net/*nmconnection /etc/NetworkManager/system-connections/
#cp /net/*conf /etc/wireguard/
#rm -rf /net

#------------------------------------------

sed -i "s?export GRIM_DEFAULT_DIR=/home/username/Pictures/screenshots?export GRIM_DEFAULT_DIR=/home/$uname/Pictures/screenshots?g" /.zprofile
sed -i "s?export ZSH=\"/home/username/.oh-my-zsh\"?export ZSH=\"/home/$uname/.oh-my-zsh\"?g" /.zshrc
sed -i "s?path+=('/home/username/.local/bin')?path+=('/home/""$uname""/.local/bin')?g" /.zshrc
sed -i "s?source /home/username/.config/broot/launcher/bash/br?source /home/$uname/.config/broot/launcher/bash/br?g" /.zshrc
sed -i "s?include \"/home/username/.gtkrc-2.0.mine\"?include \"/home/$uname/.gtkrc-2.0.mine\"?g" /.gtkrc-2.0

mkdir -p /root/.config
mkdir -p /root/.local/share
mkdir -p /home/$uname/Pictures/screenshots
mv /Wallpapers /home/$uname/Pictures/Wallpapers
mv /.local /home/$uname/.local
mv /.config /home/$uname/.config
mv /after_install.sh /home/$uname/
mv /.gtkrc-2.0 /home/$uname/
mv /.zshrc /home/$uname/
ln -s /home/$uname/.zshrc /root/.zshrc
chmod 744 /root/.zshrc
mv /.zprofile /home/$uname/
mkdir -p /home/$uname/.local/share
cd /home/$uname/.local/share
aunpack /nvim.tar.zst
cd /
rm /nvim.tar.zst
mkdir -p /root/.local/share
mkdir -p /root/.config
ln -s /home/$uname/.local/share/nvim /root/.local/share/nvim
ln -s /home/$uname/.config/nvim /root/.config/nvim
chown -R $uname:$uname /home/$uname
chmod +x /home/$uname/.local/bin/*
mkdir /media
mkdir /etc/zrepl
mv /zrepl.yml /etc/zrepl/

