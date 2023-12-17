#!/bin/bash
# Abort on error
set -e

git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
make
make install
cd ..

rm -rf nv-codec-headers

git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg
cd ffmpeg
./configure --enable-nonfree --enable-cuda-nvcc --enable-libnpp --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 --disable-static --enable-shared --enable-libx264 --enable-libx265
make -j$(nproc)
make install

rm -rf ffmpeg

echo "Verification:"
#ffmpeg -codecs 2> /dev/null | grep nvenc
ffmpeg -hwaccels
