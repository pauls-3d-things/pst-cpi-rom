#!/bin/bash

dd if=/root/u-boot/u-boot-sunxi-with-spl.bin of=/root/clockworkpi-debian.img bs=1024 seek=8
cp -p /root/clockworkpi-debian/boot.scr /root/clockworkpi-image/rootfs/
