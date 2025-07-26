#!/bin/bash
set -e

# Set time
timedatectl set-ntp true

echo "Partitioning disk..."
fdisk /dev/vda <<EOF
g
n
1

+512M
t
1
n
2


w
EOF

echo "Formatting partitions..."
mkfs.fat -F32 /dev/vda1
mkfs.ext4 /dev/vda2

echo "Mounting partitions..."
mount /dev/vda2 /mnt
mkdir /mnt/boot
mount /dev/vda1 /mnt/boot

echo "Installing base system..."
pacstrap /mnt base linux linux-firmware nano vim networkmanager sudo grub efibootmgr

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "Chrooting into the system..."
arch-chroot /mnt /bin/bash <<'EOF'
set -e

# Time & locale
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname & hosts
echo "arch" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    arch.localdomain arch
EOT

# Bootloader
mount /dev/vda1 /boot
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Create user and set passwords
rootpass=$(openssl rand -base64 16)
echo "root:$rootpass" | chpasswd
echo "$rootpass" > /root/root_password.txt
chmod 600 /root/root_password.txt

username="archuser"
userpass=$(openssl rand -base64 16)
useradd -m -G wheel -s /bin/bash $username
echo "$username:$userpass" | chpasswd
echo "$userpass" > /root/user_password.txt
chmod 600 /root/user_password.txt
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable parallel downloads
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

# Install Hyprland and essentials
pacman -Sy --noconfirm \
  hyprland xdg-desktop-portal-hyprland waybar foot wofi \
  network-manager-applet xdg-utils polkit-gnome pipewire wireplumber \
  bluez bluez-utils brightnessctl grim slurp wl-clipboard \
  unzip unrar pavucontrol neovim git base-devel

systemctl enable NetworkManager
systemctl enable bluetooth

# Hyprland config
mkdir -p /home/$username/.config/hypr
cp -r /etc/xdg/hypr/* /home/$username/.config/hypr/
chown -R $username:$username /home/$username/.config/hypr

# Autologin
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat <<EOT > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $username --noclear %I \$TERM
EOT

echo '[[ -z $DISPLAY && $XDG_SESSION_TYPE != "wayland" ]] && exec Hyprland' >> /home/$username/.bash_profile
chown $username:$username /home/$username/.bash_profile

# Enable multilib and install additional packages
sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm sddm mpv ranger ufw

systemctl enable sddm
systemctl enable ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable

# Install yay for AUR
cd /tmp
git clone https://aur.archlinux.org/yay.git
chown -R $username:$username yay
cd yay
sudo -u $username makepkg -si --noconfirm
sudo -u $username yay -S --noconfirm brave-bin

EOF

echo "Unmounting and rebooting..."
umount -R /mnt
reboot
