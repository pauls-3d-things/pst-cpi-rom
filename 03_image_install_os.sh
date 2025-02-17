#!/bin/bash
# based on: https://github.com/wolfallein/clockworkpi-debian/blob/master/create-debian.sh

rootfs_dir="/root/clockworkpi-image/rootfs"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Create filesystem with packages
multistrap -a armhf -f $SCRIPT_DIR/cpi-files/multistrap.conf

# Configure new system
cp /usr/bin/qemu-arm-static $rootfs_dir/usr/bin
mount -o bind /dev/ $rootfs_dir/dev/

# Set environment variables
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
chroot $rootfs_dir dpkg --configure -a
# For some reason the following packages are configured before dependences
# Try to reconfigure. Maybe can be removed in future.
chroot $rootfs_dir dpkg --configure base-files
chroot $rootfs_dir dpkg --configure bash

# Add cpi user
chroot $rootfs_dir adduser --disabled-password --gecos "" cpi
# Add cpi to groups
chroot $rootfs_dir usermod -a -G audio,video,input,render,bluetooth,sudo cpi

# Empty password
chroot $rootfs_dir passwd -d root
chroot $rootfs_dir passwd -d cpi

# Create mounting point for read-only file
chroot $rootfs_dir mkdir /home/cpi/storage
chroot $rootfs_dir chown -R cpi /home/cpi/storage

# Copy new retroarch configuration with tweaks for CPI
chroot $rootfs_dir mkdir /home/cpi/.config
chroot $rootfs_dir mkdir /home/cpi/.config/retroarch
cp -r /root/clockworkpi-debian/retroarch/config/* $rootfs_dir/home/cpi/.config/retroarch/
chroot $rootfs_dir chown -R cpi /home/cpi

# Kill processes running in rootfs
fuser -sk $rootfs_dir
rm $rootfs_dir/usr/bin/qemu-arm-static
umount $rootfs_dir/dev/

# Copy bt/wifi firmware
mkdir $rootfs_dir/lib/firmware
rsync -a /root/clockworkpi-debian/brcm/* $rootfs_dir/lib/firmware/brcm/

# Create fstab
# microSD partitions mounting
filename=$rootfs_dir/etc/fstab
echo /dev/mmcblk0p1 / ext4 noatime 0 1 >> $filename
echo proc /proc proc defaults 0 0 >> $filename

# Copy network files
cp /root/clockworkpi-debian/interfaces $rootfs_dir/etc/network/
cp $SCRIPT_DIR/cpi-files/wpa_supplicant.conf $rootfs_dir/etc/wpa_supplicant/

echo NetworkInterfaceBlacklist=usb0 >> $rootfs_dir/etc/connman/main.conf
echo AlwaysConnectedTechnologies =bluetooth,wifi >> $rootfs_dir/etc/connman/main.conf

# Add modules to start at boot
echo blacklist sunxi_cedrus > $rootfs_dir/etc/modprobe.d/nocedrus.conf
echo g_multi >> $rootfs_dir/etc/modules
echo options g_multi file=\"\" ro=0 removable=1 stall=0 >> $rootfs_dir/etc/modprobe.d/multigadget.conf

# Fix dhcp server for RNDIS usb
echo "subnet 192.168.11.0 netmask 255.255.255.0 {
  range 192.168.11.10 192.168.11.250;
}" >> $rootfs_dir/etc/dhcp/dhcpd.conf
sed -i "s/option domain-name/#option domain-name/" $rootfs_dir/etc/dhcp/dhcpd.conf
sed -i "s/option domain-name-servers/#option domain-name-servers/" $rootfs_dir/etc/dhcp/dhcpd.conf
echo INTERFACES=\"usb0\" >> $rootfs_dir/etc/default/isc-dhcp-server

# Enable root autologin on serial
#filename=$rootfs_dir/lib/systemd/system/serial-getty@.service
#autologin='--autologin root'
#execstart='ExecStart=-\/sbin\/agetty'
#if [[ ! $(grep -e "$autologin" $filename) ]]; then
#    sed -i "s/$execstart/$execstart $autologin/" $filename
#fi

# Enable cpi autologin on TTY1
filename=$rootfs_dir/lib/systemd/system/getty@.service
autologin='--autologin cpi'
execstart='ExecStart=-\/sbin\/agetty'
if [[ ! $(grep -e "$autologin" $filename) ]]; then
    sed -i "s/$execstart/$execstart $autologin/" $filename
fi

# Set systemd logging
filename=$rootfs_dir/etc/systemd/system.conf
for i in 'LogLevel=warning'\
         'LogTarget=journal'\
; do
    sed -i "/${i%=*}/c\\$i" $filename
done

# Enable root to connect to ssh with empty password
filename=$rootfs_dir/etc/ssh/sshd_config
if [[ -f $filename ]]; then
    for i in 'PermitRootLogin yes'\
             'PermitEmptyPasswords yes'\
             'UsePAM no'\
    ; do
        sed -ri "/^#?${i% *}/c\\$i" $filename
    done
fi

# Expand filesystem executable
cp /root/clockworkpi-debian/expand.sh $rootfs_dir/home/cpi/
echo "/home/cpi/expand.sh" >> $rootfs_dir/home/cpi/.profile

# Unmute sound
cp -pr /root/clockworkpi-debian/asound.state $rootfs_dir/var/lib/alsa/


# Execute retroarch at boot
echo "if [[ \"\$(tty)\" == \"/dev/tty1\" ]]
 then
  pulseaudio --daemonize --disallow-exit
  # We need to load it after boot is complete because if we have it as an
  # module option it can load before fstab mount the filesystem and it will
  # mount as a read-only
  # echo "/mass_storage" | sudo tee /sys/devices/platform/soc/1c19000.usb/musb-hdrc.2.auto/gadget/lun0/file
  DISPLAY=":0"
  DBUS_SESSION_BUS_ADDRESS="unix:path=/run/dbus/system_bus_socket"
  export DBUS_SESSION_BUS_ADDRESS
  retroarch
fi" >> $rootfs_dir/home/cpi/.profile

echo
echo "$rootfs_dir configured"