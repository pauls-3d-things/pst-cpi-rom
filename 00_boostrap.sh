#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ ! -d "gcc-linaro-7.2.1-2017.11-x86_64_arm-linux-gnueabihf" ] ; then
    wget https://releases.linaro.org/components/toolchain/binaries/7.2-2017.11/arm-linux-gnueabihf/gcc-linaro-7.2.1-2017.11-x86_64_arm-linux-gnueabihf.tar.xz
    tar -xf gcc-linaro-7.2.1-2017.11-x86_64_arm-linux-gnueabihf.tar.xz
    rm gcc-linaro-7.2.1-2017.11-x86_64_arm-linux-gnueabihf.tar.xz
fi

export PATH="${PATH}:/root/gcc-linaro-7.2.1-2017.11-x86_64_arm-linux-gnueabihf/bin"

apt-get update \
    && apt-get install -y \
        flex bison libssl-dev u-boot-tools libgmp-dev libmpc-dev bc \
        python-setuptools \
        git build-essential \
        bison flex swig python3-distutils python3-dev python-dev \
        libssl-dev u-boot-tools \
        multistrap qemu-user-static \
        gcc-9 \
        fdisk rsync psmisc dosfstools \
    && rm -rf /var/lib/apt/lists/*

# get clockworkpi kernel patches
cd /root
git clone https://github.com/clockworkpi/Kernel.git kernel-patches

# get kernel
cd /root
git config --global init.defaultBranch main \
    && mkdir kernel \
    && cd kernel \
    && git init \
    && git remote add origin git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git \
    && git fetch --depth 1 origin 5827ddaf4534c52d31dd464679a186b41810ef76 \
    && git checkout FETCH_HEAD
# patch kernel
cd /root/kernel \
    && git apply ../kernel-patches/v0.6/*.patch 
# build kernel
cd /root/kernel/ \
    && cp ./arch/arm/configs/clockworkpi_cpi3_defconfig .config \
    && make -j$(nproc) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- \
    && mkimage -A arm -O linux -T kernel -C none -a 0x40008000 -e 0x40008000 -n "Linux Kernel" -d arch/arm/boot/zImage uImage

# get clockworkpi-debian
cd /root \
    && git clone https://github.com/wolfallein/clockworkpi-debian.git clockworkpi-debian

# get u-boot
cd /root \
    && git clone git://git.denx.de/u-boot.git \
    && cd u-boot/ \
    && git checkout v2019.10-rc4
# patch u-boot
cd /root/u-boot  \
    && git apply ../clockworkpi-debian/cpi-u-boot.patch
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 1
# build u-boot
cd /root/u-boot \
    && export ARCH=arm \
    && export CROSS_COMPILE=arm-linux-gnueabihf- \
    && make clockworkpi-cpi3_defconfig \
    && make -j$(nproc)

# build boot.scr
mkimage -C none -A arm -T script -d $SCRIPT_DIR/cpi-files/boot.cmd /root/clockworkpi-debian/boot.scr
