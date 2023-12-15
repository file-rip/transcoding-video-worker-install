#!/bin/bash
# Automatically compile and install FFMPEG with NVIDIA hardware acceleration in nvidia/cuda:12.0-devel-ubuntu22.04
# Includes cuvid, cuda, nvenc, nvdec, and libnpp
# Based on:
#  https://www.tal.org/tutorials/ffmpeg_nvidia_encode
#  https://developer.nvidia.com/blog/nvidia-ffmpeg-transcoding-guide/

# Abort on error
set -e

suite=$(. /etc/os-release && echo $VERSION_CODENAME)*

# Update package list
apt-get update

# Install necessary tools and dependencies
apt-get install -y wget git build-essential yasm cmake libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev

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

#install ffmpeg

git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg/
cd ffmpeg

# Checkout the latest release
git checkout $(git describe --tags $(git rev-list --tags --max-count=1))

./configure  --enable-cuda-nvcc --enable-cuda --enable-cuvid --enable-nvdec --enable-nvenc --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 --enable-libnpp --enable-nonfree  --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 --disable-static --enable-shared

cd ..

echo "Verification:"
ffmpeg -codecs 2> /dev/null | grep nvenc
