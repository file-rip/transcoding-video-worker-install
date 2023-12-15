#!/bin/bash
# Automatically compile and install FFMPEG with NVIDIA hardware acceleration in nvidia/cuda:12.0-devel-ubuntu22.04
# Includes cuvid, cuda, nvenc, nvdec, and libnpp
# Based on:
#  https://www.tal.org/tutorials/ffmpeg_nvidia_encode
#  https://developer.nvidia.com/blog/nvidia-ffmpeg-transcoding-guide/

# Abort on error
set -e

# Update package list
apt-get update

# Install necessary tools and dependencies
apt-get install -y wget git make

# Ubuntu 22.04 should already have the necessary codecs and libraries in its standard repositories
# Install devscripts for the dch command
apt-get install -y devscripts

NON_FREE_REPO="deb-src mirror://mirrors.ubuntu.com/mirrors.txt jammy main restricted universe multiverse"
if ! grep -q "^$NON_FREE_REPO$" /etc/apt/sources.list; then
    echo "$NON_FREE_REPO" | sudo tee -a /etc/apt/sources.list
fi

apt-get update

# Clone and install nv-codec-headers
mkdir -p ffmpeg-deb/src
cd ffmpeg-deb
if [[ -d nv-codec-headers ]]; then
    cd nv-codec-headers
    git fetch --tags
else
    git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
    cd nv-codec-headers
fi

# Checkout the latest release
git checkout $(git describe --tags $(git rev-list --tags --max-count=1))
make
make install
cd ../src
rm -rf ./*
apt-get source ffmpeg

# Modify ffmpeg package for NVIDIA hardware acceleration
cd ffmpeg-*
sed -i 's/--enable-sdl2/--enable-sdl2 --enable-cuda --enable-cuvid --enable-nvdec --enable-nvenc --enable-libnpp --enable-nonfree/' debian/rules
DEBEMAIL="root@local" DEBFULLNAME="script" dch --local "+nvidiasupport" "Compiled with support for NVIDIA hardware acceleration"
DEB_BUILD_OPTIONS="nocheck notest" dpkg-buildpackage -r -nc --jobs=auto --no-sign
cd ..

# Install all built packages, except the non-extra variants of libavfilter, libavcodec and libavformat
dpkg -i $(ls *.deb | grep -Ev "(libavfilter|libavcodec|libavformat)[0-9]+_")
echo "Verification:"
ffmpeg -codecs 2> /dev/null | grep nvenc
