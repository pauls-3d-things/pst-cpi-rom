#!/bin/bash

cp -p /root/kernel/uImage /root/clockworkpi-image/rootfs/boot/
cp -p /root/kernel/arch/arm/boot/dts/sun8i-r16-clockworkpi-cpi3.dtb /root/clockworkpi-image/rootfs/boot/
cp -p /root/kernel/arch/arm/boot/dts/sun8i-r16-clockworkpi-cpi3-hdmi.dtb /root/clockworkpi-image/rootfs/boot/

export PATH="${PATH}:/root/gcc-linaro-7.2.1-2017.11-x86_64_arm-linux-gnueabihf/bin"

cd /root/kernel
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=/root/clockworkpi-image/rootfs modules_install
