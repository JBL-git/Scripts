#!/bin/bash

set -e

# sets time
timedatectl set-ntp true

echo "partitioning disk with fdisk..."

fdisk /dev/vda << EOF
g     # create new GPT partition table
n     # new parition 1 (EFI)
1     # partition 1
      # default start
+512M
t     # change type
1
1
n     # new partition 2 (root)
2     # parition number 2
      # default start
      # default end
w     # write changes
EOF

echo "formating partitions..."

mkfs.fat -32 /dev/vda1
mkfs.ext4 /dev/vda2

echo "mounting paritions..."

mount /dev/vda2 /mnt
mkdir /mnt/boot
mount /dev/vda1 /mnt/boot

echo "installing base system..."

pacstrap /mnt base linux linux-firmware nano vim networkmanager sudo grub efibootmgr

echo "generating fstab..."

genfstab -U /mnt >> /mnt/etc/fstab

echo "chrooting..."

arch-chroot /mnt /bin/bash
echo "setting the timezone..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

echo "setting the hardware clock..."

hwclock --systohc

echo "setting locale..."

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

cat <<EOF > /etc/locale.conf
LANG=en_US.UTF-8
EOF

echo "setting language..."

echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "setting the hostname..."

echo "arch" > /etc/hostname

cat <<EOT > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    arch.localdomain arch
EOT

# installing and configuring the grub bootloader

echo "getting GRUB ready..."

mount /dev/vda1 /boot
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "setting root password and creating a user..."

rootpass=$(openssl rand -base64 16)
echo "root:$rootpass" | chpasswd
echo "saving the password to a file /root/root_password.txt"
echo "$rootpass" > /root/root_password.txt
chmod 600 /root/root_password.txt
echo "Root password: $rootpass"

username="archuser"
userpass=\$(openssl rand -base64 16)
useradd -m -G wheel -s /bin/bash \$username
echo "\$username:\$userpass" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo "User '\$username' password: \$userpass" > /root/user_password.txt
chmod 600 /root/user_password.txt


echo "installing parallel downloads in pacman..."
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

echo "installing hyprland and other packages..."
pacman -Sy --noconfirm \
  hyprland \
  xdg-desktop-portal-hyprland \
  waybar \
  foot \
  wofi \
  network-manager-applet \
  xdg-utils \
  polkit-gnome \
  pipewire \
  wireplumber \
  bluez \
  bluez-utils \
  brightnessctl \
  grim \
  slurp \
  wl-clipboard \
  unzip \
  unrar \
  pavucontrol \
  neovim \
  git

echo "enabling network access on boot..."
systemctl enable NetworkManager


username="archuser"

mkdir -p /home/\$username/.config/hypr
cp -r /etc/xdg/hypr/* /home/\$username/.config/hypr/
chown -R \$username:\$username /home/\$username/.config/hypr

mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat <<EOT > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin archuser --noclear %I \$TERM
EOT
EOF

username="archuser"  

echo '[[ -z \$DISPLAY && \$XDG_SESSION_TYPE != "wayland" ]] && exec Hyprland' >> /home/\$username/.bash_profile
chown \$username:\$username /home/\$username/.bash_profile

echo "[*] installing sddm, Brave, Ranger, mpv, and ufw..."

# enable multilib repo and add AUR helper (yay) for Brave
sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

pacman -S --noconfirm sddm mpv ranger ufw git base-devel

# enable sddm service
systemctl enable sddm

# install yay (AUR helper) to install brave browser
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm

# install brave browser
yay -S --noconfirm brave-bin

# enable and configure UFW
systemctl enable ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable
EOF

echo "exiting chroot..."
umount -R /mnt
reboot
