#!/bin/bash
# Abort on error
set -e

NV_CODEC_HEADERS_VERSION=11.0.10.1
FFMPEG_VERSION=4.4.2

git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
git checkout n${NV_CODEC_HEADERS_VERSION}
make install
cd ..

rm -rf nv-codec-headers

wget https://github.com/FFmpeg/FFmpeg/archive/refs/tags/n${FFMPEG_VERSION}.tar.gz
tar -xf n${FFMPEG_VERSION}.tar.gz
cd FFmpeg-n${FFMPEG_VERSION}

prefix=/usr/
ccap=75

./configure \
  --prefix="${prefix}" \
  --extra-cflags='-I/usr/local/cuda/include' \
  --extra-ldflags='-L/usr/local/cuda/lib64' \
  --nvccflags="-gencode arch=compute_${ccap},code=sm_${ccap} -O2" \
  --disable-doc \
  --enable-decoder=aac \
  --enable-decoder=h264 \
  --enable-decoder=h264_cuvid \
  --enable-decoder=rawvideo \
  --enable-indev=lavfi \
  --enable-encoder=libx264 \
  --enable-encoder=h264_nvenc \
  --enable-demuxer=mov \
  --enable-muxer=mp4 \
  --enable-filter=scale \
  --enable-filter=testsrc2 \
  --enable-protocol=file \
  --enable-protocol=https \
  --enable-gnutls \
  --enable-shared \
  --enable-gpl \
  --enable-nonfree \
  --enable-cuda-nvcc \
  --enable-libx264 \
  --enable-nvenc \
  --enable-cuvid \
  --enable-nvdec

make clean
make -j
make install

cd ..
rm -rf FFmpeg-n${FFMPEG_VERSION}
