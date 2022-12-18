#!/bin/bash
mkdir temp mnt build share Videos Documents Downloads Music
mkdir Videos/records
broot --install
echo "Stay near the pc, you will have to enter root password for a few times"
echo "Updating mirrors"
sudo reflector --verbose --sort rate --protocol https --country Germany,UK,Poland,Netherlands --age 3 --save /etc/pacman.d/mirrorlist
echo "Setting timezone and time sync..."
sudo timedatectl set-ntp true --no-ask-password
sudo timedatectl set-timezone Europe/Moscow --no-ask-password
echo "[zram0]
zram-size = ram / 2" | sudo tee /etc/systemd/zram-generator.conf
sudo systemctl daemon-reload
sudo systemctl start /dev/zram0
if [ $USER = 'okhsunrog' ]; then
    git config --global user.name "okhsunrog"
    git config --global user.email  "me@okhsunrog.ru"
fi
#---------------------------------------------

#sudo mkdir /opt/{idea,pycharm,clion}
#sudo curl -L "https://download.jetbrains.com/product?code=IIU&latest&distribution=linux" | sudo tar xvz -C /opt/idea  --strip 1
#sudo curl -L "https://download.jetbrains.com/product?code=PCP&latest&distribution=linux" | sudo tar xvz -C /opt/pycharm  --strip 1
#sudo curl -L "https://download.jetbrains.com/product?code=CL&latest&distribution=linux" | sudo tar xvz -C /opt/clion  --strip 1

#------------------------------------------

#pip3 install --user git+https://github.com/rachmadaniHaryono/we-get

#--------------------------------------------

echo '# If running from tty1 start sway
if [[ "$(tty)" = "/dev/tty1" ]] && [[ -z $DISPLAY ]] ; then
  export SSH_AUTH_SOCK
  exec sway
fi' >> .zprofile

#------------------------------------

sudo systemctl enable cronie
sudo systemctl enable cups.socket
sudo systemctl enable bluetooth

#---------------------------

sudo zfs snapshot zroot/data/home@install
sudo zfs snapshot zroot/ROOT/default@restore
sudo zfs clone zroot/ROOT/default@restore zroot/ROOT/restore

#-------------------------

sleep 1
rm "after_install.sh"
sleep 1
reboot
