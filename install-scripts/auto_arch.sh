#!/bin/bash
set -e

echo "Setting up NTP..."
timedatectl set-ntp true

echo "Partitioning /dev/vda..."
fdisk /dev/vda <<EOF
g       
n       
1
        
+512M
t       
1
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
mkdir -p /mnt/boot
mount /dev/vda1 /mnt/boot

echo "Installing base system..."
pacstrap /mnt base linux linux-firmware nano vim networkmanager sudo grub efibootmgr git base-devel

echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "Entering chroot to configure system..."

arch-chroot /mnt /bin/bash <<'EOF'
set -e

echo "Generating and setting root password..."
rootpass=$(openssl rand -base64 16)
echo "root:$rootpass" | chpasswd
echo "$rootpass" > /root/root_password.txt
chmod 600 /root/root_password.txt
echo "Root password saved to /root/root_password.txt"

echo "Creating user 'archuser' and setting password..."
username="archuser"
userpass=$(openssl rand -base64 16)
useradd -m -G wheel -s /bin/bash "$username"
echo "$username:$userpass" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo "$username:$userpass" > /root/user_password.txt
chmod 600 /root/user_password.txt
echo "User password saved to /root/user_password.txt"

echo "Setting timezone to UTC..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

echo "Configuring locale..."
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "Setting hostname..."
echo "arch" > /etc/hostname

echo "Configuring hosts file..."
cat > /etc/hosts <<EOL
127.0.0.1    localhost
::1          localhost
127.0.1.1    arch.localdomain arch
EOL

echo "Installing and configuring GRUB bootloader..."
mount /dev/vda1 /boot
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "Enabling parallel downloads in pacman..."
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

echo "Installing Hyprland and essential packages..."
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
  git \
  sddm \
  mpv \
  ranger \
  ufw

echo "Enabling systemd services..."
systemctl enable NetworkManager sddm ufw

echo "Configuring UFW firewall..."
ufw default deny incoming
ufw default allow outgoing
echo "y" | ufw enable

echo "Setting up AUR helper yay for Brave Browser installation..."
sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
runuser -u archuser -- makepkg -si --noconfirm

echo "Installing zen browser..."
runuser -u archuser -- yay -S --noconfirm zen-browser-bin

echo "Setting up autologin on tty1 for user $username..."
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOL
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $username --noclear %I \$TERM
EOL

echo "Setting up Hyprland autostart in user's bash_profile..."
echo '[[ -z $DISPLAY && $XDG_SESSION_TYPE != "wayland" ]] && exec Hyprland' >> /home/$username/.bash_profile
chown $username:$username /home/$username/.bash_profile

EOF

echo "Unmounting partitions..."
umount -R /mnt

echo "Installation complete. Please reboot..."
