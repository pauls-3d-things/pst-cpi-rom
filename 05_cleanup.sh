#!/bin/bash
umount /root/clockworkpi-image/rootfs
losetup -d /dev/loop0
losetup -d /dev/loop1
losetup -a
rm -rf /root/clockworkpi-image