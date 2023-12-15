
# Automatically compile and install FFMPEG with NVIDIA hardware acceleration on Debian 12
# Includes cuvid, cuda, nvenc, nvdec, and non-free libnpp
# Based on:
#  https://www.tal.org/tutorials/ffmpeg_nvidia_encode
#  https://developer.nvidia.com/blog/nvidia-ffmpeg-transcoding-guide/

# Abort on error
set -e

suite=$(. /etc/os-release && echo $VERSION_CODENAME)*

echo "deb-src http://deb.debian.org/debian/ bookworm main contrib non-free" | tee -a /etc/apt/sources.list

apt update

# Install libavcodec-extra manually so the build-deps step doesn't pull the problematic libavcodec59
# libjs-bootstrap is a dependency of ffmpeg-doc
# devscripts contains the dch command
sudo apt-get install -y libavcodec-extra libjs-bootstrap devscripts
sudo apt-mark auto libavcodec-extra libjs-bootstrap devscripts

sudo apt-get build-dep ffmpeg -t $suite

mkdir -p ffmpeg-deb/src
cd ffmpeg-deb
if [[ -d nv-codec-headers ]]
then
  cd nv-codec-headers
  git fetch --tags
else
  git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
  cd nv-codec-headers
fi
# Checkout latest release, intead of HEAD. The Debian driver in stable may not yet support the pre-release API.
git checkout $(git describe --tags $(git rev-list --tags --max-count=1))
make
sudo make install
cd ../src
rm -rf ./*
apt-get source ffmpeg -t $suite

cd ffmpeg-*
sed -i 's/--enable-sdl2/--enable-sdl2 --enable-cuda --enable-cuvid --enable-nvdec --enable-nvenc --enable-libnpp --enable-nonfree/' debian/rules
DEBEMAIL="root@local" DEBFULLNAME="script" dch --local "+nvidiasupport" "Compiled with support for nvidia hardware acceleration"
DEB_BUILD_OPTIONS="nocheck notest" dpkg-buildpackage -r -nc --jobs=auto --no-sign
cd ..

# Install all built packages, except the non-extra variants of libavfilter, libavcodec and libavformat
sudo dpkg -i $(ls *.deb | grep -Ev "(libavfilter|libavcodec|libavformat)[0-9]+_")
echo "Verification:"
ffmpeg -codecs 2> /dev/null | grep nvenc
