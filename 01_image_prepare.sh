#!/bin/bash
# src: https://github.com/wolfallein/clockworkpi-debian/blob/master/create-image.sh

umount /root/clockworkpi-image/rootfs
losetup -d /dev/loop0
sleep 1

losetup -d /dev/loop1
sleep 1

rm -rf /root/clockworkpi-image

mkdir /root/clockworkpi-image
mkdir /root/clockworkpi-image/rootfs

if [ -f "/root/clockworkpi-debian.img" ] ; then
    rm /root/clockworkpi-debian.img
    echo "DELETED /root/clockworkpi-debian.img"
    sleep 1
fi

dd if=/dev/zero of=/root/clockworkpi-debian.img bs=1M seek=2800 count=0
echo "CREATED clockworkpi-debian.img"
sync
sleep 1

echo -e "n\np\n1\n8192\n\nt\n83\nw\n" | fdisk /root/clockworkpi-debian.img
sync
sleep 1

losetup -o 4194304 --sizelimit 2750M /dev/loop0 /root/clockworkpi-debian.img
mkfs.ext4 /dev/loop0 -L rootfs
sync
sleep 1

mount -t ext4 /dev/loop0 /root/clockworkpi-image/rootfs

ls /root/clockworkpi-image/rootfs