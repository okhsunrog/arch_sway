#!/bin/bash
set -e

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

pacman -S archlinux-keyring --noconfirm

#--------------------

echo 'MODULES=""
BINARIES=""
FILES=""
HOOKS="base udev autodetect modconf block encrypt filesystems keyboard fsck"' > /etc/mkinitcpio.conf

echo "EDITOR=nvim" >> /etc/environment
echo "LOCALE=en_US.UTF-8
KEYMAP=ru
FONT=ter-u16b
CONSOLEMAP=
TIMEZONE=Europe/Moscow
HARDWARECLOCK=UTC
USECOLOR=yes" > /etc/vconsole.conf
mkinitcpio -P

#--------------------------------------------

echo "Installing additional software..."
pacman -Syyuu --noconfirm
#arch repos
pacman -S brightnessctl lximage-qt wireplumber scrcpy gimp intel-media-sdk intel-media-driver intel-gpu-tools vulkan-intel libva-utils telegram-desktop vulkan-icd-loader vulkan-tools xorg-xrdb sof-firmware github-cli docker docker-compose openscad skanlite libvncserver remmina wayvnc exfatprogs nfs-utils tmux screen dex ddcutil i2c-tools archiso thunderbird bluez bluez-utils helvum pacman-contrib smartmontools hdparm wayland-protocols hyphen-en hyphen gnome-keyring libgnome-keyring upower iotop f2fs-tools efibootmgr dosfstools arch-install-scripts ruby-bundler pv alsa-firmware pipewire pipewire-alsa pipewire-jack pipewire-pulse xdg-desktop-portal xdg-desktop-portal-wlr yt-dlp mc translate-shell nm-connection-editor hunspell hunspell-en_us perl-file-mimeinfo seatd sway swayidle mousepad cups cups-pdf usbutils inkscape go zsh i7z libappindicator-gtk3 lm_sensors stalonetray network-manager-applet ttf-jetbrains-mono gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly tor pigz pbzip2 android-udev libmad opus flac pcmanfm-qt speedtest-cli fzf tree broot lxappearance qt5-wayland noto-fonts-emoji acpi systembus-notify ttf-dejavu otf-font-awesome xmlto pahole inetutils bc terminus-font reflector snapper rsync cronie wf-recorder imagemagick tk python-pip zathura zathura-djvu zathura-pdf-mupdf udiskie udisks2 htop qt5ct meson ninja scdoc playerctl libreoffice-fresh xorg-server-xwayland ffmpeg jdk-openjdk jdk8-openjdk mpv imv openssh wget ttf-opensans git neofetch pavucontrol grim slurp jq wl-clipboard neofetch android-tools cpio lhasa lzop p7zip unace unrar unzip zip earlyoom highlight mediainfo odt2txt perl-image-exiftool --noconfirm --needed
#chaotic-aur
pacman -S clipman fcft foot i3status-rust libdispatch numix-icon-theme-git qt5-styleplugins systray-x-git yay zoom --noconfirm --needed
#my repos
pacman -Rnsdd xdg-utils --noconfirm
pacman -S atool2-git aria2-fast cava gtk-theme-numix-solarized handbrake-full handbrake-full-cli hunspell-ru-aot hyphen-ru lsix-git mako-no-blur-git mimeo ntfsprogs-ntfs3 puddletag qbittorrent-enhanced-qt5 ranger-sixel ruri strawberry-qt5 swaykbdd swaylock-effects-git sworkstyle throttled-git tiny-irc-client ttf-menlo-powerline-git ttf-ms-win11-okhsunrog wlogout-git wlr-sunclock-git xdg-utils-mimeo zsh-vi-mode-git --noconfirm --needed

#------------------------------------------

chsh -s $(which zsh)
read -p "Enter root password: " rpass
echo "$rpass
$rpass" | passwd
echo "Creating a new user..."
read -p "Enter user name: " uname
useradd -mG wheel,video,uucp,i2c,lock -s /usr/bin/zsh $uname
read -p "Enter $uname password: "$'\n' -s upass
echo "$upass
$upass" | passwd $uname
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
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
#echo "vboxdrv" > /etc/modules-load.d/virtualbox.conf
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
#systemctl enable sshd
#systemctl enable docker
#systemctl enable nfs-server

#------------------------------------------

#swsizeG=4
#echo "Creating swap file..."
#swsize=$((swsizeG*1024))
#truncate -s 0 /swap/swapfile
#chattr +C /swap/swapfile
#btrfs property set /swap/swapfile compression none
#dd if=/dev/zero of=/swap/swapfile bs=1M count=$swsize status=progress
#chmod 600 /swap/swapfile
#mkswap /swap/swapfile
#swapon /swap/swapfile
#echo "/swap/swapfile          none            swap            defaults        0 0" >> /etc/fstab

#--------------------------------

echo "Installing bootloader..."
bootctl --path=/boot install
echo "default arch.conf
editor  no" > /boot/loader/loader.conf
echo "title           Arch Linux
linux           /vmlinuz-linux-lts
initrd          /intel-ucode.img
initrd          /initramfs-linux-lts.img
options         root=LABEL=system rootflags=subvol=@ cryptdevice=PARTLABEL=cryptsystem:cryptroot:allow-discards rw" > /boot/loader/entries/arch.conf

#---------------------------------

wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
mv install.sh /home/$uname/
su - $uname -c 'sh install.sh --unattended'
rm /home/$uname/install.sh
git clone https://github.com/zsh-users/zsh-completions /home/$uname/.oh-my-zsh/custom/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions /home/$uname/.oh-my-zsh/custom/plugins/zsh-autosuggestions

#----------------------------------------

#cp /net/*nmconnection /etc/NetworkManager/system-connections/
#cp /net/*conf /etc/wireguard/
#rm -rf /net

#------------------------------------------

echo '# /etc/anacrontab: configuration file for anacron    
    
# See anacron(8) and anacrontab(5) for details.    
    
SHELL=/bin/sh    
PATH=/sbin:/bin:/usr/sbin:/usr/bin    
# the maximal random delay added to the base delay of the jobs    
RANDOM_DELAY=5    
# the jobs will be started during the following hours only    
START_HOURS_RANGE=0-23    
    
#period in days   delay in minutes   job-identifier   command    
1 3 cron.daily    nice run-parts /etc/cron.daily    
7 25  cron.weekly   nice run-parts /etc/cron.weekly    
@monthly 45 cron.monthly    nice run-parts /etc/cron.monthly    
' > /etc/anacrontab

echo '#!/bin/sh

#
# paranoia settings
#
umask 022
PATH=/sbin:/bin:/usr/sbin:/usr/bin
export PATH


SNAPPER_CONFIGS="root home"

#
# run snapper for all configs
#
for CONFIG in $SNAPPER_CONFIGS ; do

    TIMELINE_CREATE="no"
    NUMBER_CLEANUP="no"
    TIMELINE_CLEANUP="no"
    EMPTY_PRE_POST_CLEANUP="no"
    
    . /etc/snapper/configs/$CONFIG

    if [ "$TIMELINE_CREATE" = "yes" ] ; then
	snapper --config=$CONFIG --quiet create --description="timeline" --cleanup-algorithm="timeline"
    fi

    if [ "$NUMBER_CLEANUP" = "yes" ] ; then
	snapper --config=$CONFIG --quiet cleanup number
    fi

    if [ "$TIMELINE_CLEANUP" = "yes" ] ; then
	snapper --config=$CONFIG --quiet cleanup timeline
    fi

    if [ "$EMPTY_PRE_POST_CLEANUP" = "yes" ] ; then
	snapper --config=$CONFIG --quiet cleanup empty-pre-post
    fi

done

exit 0' > /etc/cron.hourly/snapper

#---------------------------------------
sed -i "s?export GRIM_DEFAULT_DIR=/home/username/Pictures/screenshots?export GRIM_DEFAULT_DIR=/home/$uname/Pictures/screenshots?g" /.zprofile
sed -i "s?export ZSH=\"/home/username/.oh-my-zsh\"?export ZSH=\"/home/$uname/.oh-my-zsh\"?g" /.zshrc
sed -i "s?path+=('/home/username/.local/bin')?path+=('/home/""$uname""/.local/bin')?g" /.zshrc
sed -i "s?source /home/username/.config/broot/launcher/bash/br?source /home/$uname/.config/broot/launcher/bash/br?g" /.zshrc
sed -i "s?include \"/home/username/.gtkrc-2.0.mine\"?include \"/home/$uname/.gtkrc-2.0.mine\"?g" /.gtkrc-2.0

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
mv snapper /home/$uname/
chown -R $uname:$uname /home/$uname
chown -R $uname:$uname /vm
chmod +x /home/$uname/.local/bin/*
mkdir /media

