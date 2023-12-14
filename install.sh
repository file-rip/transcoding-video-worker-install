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

# Install system utilities and updates
install_utils() {
    if [ -n "$(command -v dnf)" ]; then
        package_manager="dnf"
    elif [ -n "$(command -v apt)" ]; then
        package_manager="apt"
    else
        echo "Neither DNF nor APT package manager found. Exiting."
        exit 1
    fi

    echo "Updating packages..."
    $package_manager -y update

    echo "Installing packages..."
    if [ "$package_manager" = "dnf" ]; then
        $package_manager -y groupinstall "Development Tools"
        $package_manager install -y git autoconf openssl-devel cmake3 htop iotop yasm nasm jq freetype-devel fribidi-devel harfbuzz-devel fontconfig-devel bzip2-devel
    elif [ "$package_manager" = "apt" ]; then
        export DEBIAN_FRONTEND=noninteractive;
        export NEEDRESTART_MODE=a;
        $package_manager install -y build-essential git autoconf libtool libssl-dev cmake htop iotop yasm nasm jq libfreetype6-dev libfribidi-dev libharfbuzz-dev libfontconfig1-dev libbz2-dev
    fi

    echo "Success: Updates and packages installed."
}

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
install_utils
install_ffmpeg_prereqs
install_ffmpeg
rm -fr $SRC_DIR
