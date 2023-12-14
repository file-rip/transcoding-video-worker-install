#!/bin/bash
set -e # Exit on any error

USR_LOCAL_PREFIX="/usr/local"
CUDA_HOME=$USR_LOCAL_PREFIX/cuda
HOME_DIR=$HOME
SRC_DIR=$HOME_DIR/sources

CPUS=$(nproc)
LOG_FILE="$HOME_DIR/install.log"
LOCAL_TMP="$HOME_DIR/sources/local-tmp"
mkdir -p $LOCAL_TMP

# Create source directory
mkdir -p $SRC_DIR
cd $SRC_DIR

# Helper functionS to check installation status
check_installation() {
    if [ -f "$1" ]; then
        echo "Success : $2 Installed"
    else
        echo "Error : $2 Installation Failed"
        echo "Exiting script due to installation failure."
        exit 1
    fi
}

install_ffmpeg_prereqs() {

    # Install ffnvcodec FFmpeg with NVIDIA GPU accelsetup_gpueration
    git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && cd nv-codec-headers && make install PREFIX="$USR_LOCAL_PREFIX"
    check_installation "$USR_LOCAL_PREFIX/include/ffnvcodec/nvEncodeAPI.h" "Nvidia ffnvcodec"

    # Install X264 (H.264 Codec)
    git clone --depth 1 https://code.videolan.org/videolan/x264.git &&
        cd x264 &&
        PKG_CONFIG_PATH="$USR_LOCAL_PREFIX/lib/pkgconfig" ./configure \
            --enable-shared --disable-static \
            --prefix="$USR_LOCAL_PREFIX" \
            --bindir="/usr/bin" &&
        make -j $CPUS &&
        make install
    cd ..
    check_installation "$USR_LOCAL_PREFIX/lib/libx264.so" "X264"
}

install_ffmpeg() {
    NVIDIA_CFLAGS="-I$CUDA_HOME/include"
    NVIDIA_LDFLAGS="-L$CUDA_HOME/lib64"
    NVIDIA_FFMPEG_OPTS="--enable-cuda-nvcc --nvcc=$CUDA_HOME/bin/nvcc --enable-cuda --enable-cuvid --enable-nvenc"

    # Install FFMPEG (AV1 Codec Library)
    git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg/ &&
        cd ffmpeg &&
        PKG_CONFIG_PATH="$USR_LOCAL_PREFIX/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig:/usr/lib/pkgconfig:$USR_LOCAL_PREFIX/lib/pkgconfig" \
            ./configure \
            --prefix="$USR_LOCAL_PREFIX" \
            --disable-static --enable-shared \
            --extra-cflags="-I$USR_LOCAL_PREFIX/include $NVIDIA_CFLAGS" \
            --extra-ldflags="-L$USR_LOCAL_PREFIX/lib $NVIDIA_LDFLAGS" \
            --extra-libs='-lpthread -lm' \
            --bindir="$USR_LOCAL_PREFIX/bin" \
            --enable-gpl \
            --enable-libx264 \
            --enable-nonfree \
            --enable-openssl \
            $NVIDIA_FFMPEG_OPTS &&
        make -j $CPUS &&
        make install
    cd ..
    check_installation "$USR_LOCAL_PREFIX/bin/ffmpeg" "ffmpeg"
    check_installation "$USR_LOCAL_PREFIX/bin/ffprobe" "ffprobe"
    ldconfig
}

# Execute Functions
install_ffmpeg_prereqs
install_ffmpeg
rm -fr $SRC_DIR
