#!/bin/bash


# get retroarch
apt-get update \
    && apt-get install -y \
        build-essential libudev-dev libegl-dev libasound-dev libgbm-dev libdrm-dev libgles2-mesa-dev libavcodec-dev libavformat-dev libavdevice-dev libdbus-1-dev libpulse-dev \
    && rm -rf /var/lib/apt/lists/*

git clone https://github.com/libretro/RetroArch.git --depth=1 --branch=v1.19.0 /root/retroarch

CFLAGS=-mfpu=neon ./configure --enable-alsa --enable-udev --enable-floathard --enable-neon --enable-networking --enable-opengles --enable-egl --enable-kms --disable-x11 --disable-xmb --disable-ozone --disable-materialui --disable-vg --enable-ffmpeg --enable-pulse --disable-oss --disable-freetype --enable-7zip --enable-dbus --prefix=/usr
