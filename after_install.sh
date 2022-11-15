#!/bin/bash
mkdir temp mnt build share Videos Documents Downloads Music
mkdir Videos/records
broot --install
echo "Stay near the pc, you will have to enter root password for a few times"
echo "Updating mirrors"
sudo reflector --verbose --sort rate --protocol https --country Russia --age 12 --save /etc/pacman.d/mirrorlist
echo "Setting timezone and time sync..."
sudo timedatectl set-ntp true --no-ask-password
sudo timedatectl set-timezone Europe/Moscow --no-ask-password

#---------------------------------------------

#sudo mkdir /opt/{idea,pycharm,clion}
#sudo curl -L "https://download.jetbrains.com/product?code=IIU&latest&distribution=linux" | sudo tar xvz -C /opt/idea  --strip 1
#sudo curl -L "https://download.jetbrains.com/product?code=PCP&latest&distribution=linux" | sudo tar xvz -C /opt/pycharm  --strip 1
#sudo curl -L "https://download.jetbrains.com/product?code=CL&latest&distribution=linux" | sudo tar xvz -C /opt/clion  --strip 1

#------------------------------------------

#pip3 install --user git+https://github.com/rachmadaniHaryono/we-get
nvim -c ":PlugInstall"

#--------------------------------------------

sudo mv snapper/snapper /etc/conf.d/
sudo chown root:root /etc/conf.d/snapper
sudo chmod 644 /etc/conf.d/snapper
sudo mv snapper/* /etc/snapper/configs/
sudo chown root:root /etc/snapper/configs/*
sudo chmod 640 /etc/snapper/configs/*
rm -rf snapper
sudo chmod 750 /.snapshots
sudo chmod 750 /home/.snapshots
sudo chmod a+rx /home/.snapshots
sudo chown :$(whoami) /home/.snapshots

#-----------------------------------

echo '# If running from tty1 start sway
if [[ "$(tty)" = "/dev/tty1" ]] && [[ -z $DISPLAY ]] ; then
	eval $(gnome-keyring-daemon --start)
  export SSH_AUTH_SOCK
  exec sway
fi' >> .zprofile

#------------------------------------

sudo systemctl enable cronie
sudo systemctl enable cups.socket
sudo systemctl enable bluetooth

#---------------------------

sleep 1
rm "after_install.sh"
sleep 1
reboot
