#!/bin/bash
# Abort on error
set -e

apt update

apt-get install -y build-essential yasm nasm cmake git pkg-config

apt-get install -y libx264-dev libx265-dev libnuma-dev

git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
make
make install
cd ..

rm -rf nv-codec-headers

git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
cd ffmpeg
./configure --enable-cuda-nvcc --enable-libnpp --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 --nvccflags="-gencode arch=compute_52,code=sm_52 -O2" --enable-gpl --enable-libx264 --enable-libx265
make -j$(nproc)
make install

echo "Verification:"
#ffmpeg -codecs 2> /dev/null | grep nvenc
ffmpeg -hwaccels
