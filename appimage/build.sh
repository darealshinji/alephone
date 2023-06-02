#!/bin/bash
set -e

#sudo apt install build-essential autoconf autoconf-archive nasm wget git fuse x11-utils \
#  libboost-all-dev libsdl2-dev libsdl2-image-dev libsdl2-net-dev libsdl2-ttf-dev \
#  libzzip-dev zlib1g-dev libpng-dev libva-dev libvdpau-dev \
#  libcurl4-gnutls-dev libminiupnpc-dev libopenal-dev libsndfile1-dev

#libsmpeg-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev

set -x

cd "$(dirname "$0")"

export LD_LIBRARY_PATH="$PWD/ffmpeg/usr/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$PWD/ffmpeg/usr/lib/pkgconfig"

# build FFmpeg from source to avoid unneeded dependencies
if [ ! -d ffmpeg ]; then
    git clone --depth 5000 https://github.com/FFmpeg/FFmpeg ffmpeg
fi
if [ ! -f ffmpeg/usr/lib/pkgconfig/libavcodec.pc ]; then
    cd ffmpeg
    ./configure --prefix="$PWD/usr" \
        --disable-programs \
        --disable-doc \
        --enable-gpl \
        --enable-version3 \
        --disable-static \
        --enable-shared \
    | tee config.log
    make -j$(nproc)
    make install
    cd ..
fi

# build AlephOne
if [ ! -f build/Source_Files/alephone ]; then
    rm -rf build
    mkdir build
    cd build
    test -f ../../configure || autoreconf -if ../..
    CFLAGS=-O2 CXXFLAGS=-O2 LDFLAGS=-s ../../configure --without-smpeg
    make -j$(nproc) V=0
    wget -q -O linuxdeploy.AppImage -c https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
    chmod a+x linuxdeploy.AppImage
    cd ..
fi

# create AppDirs
mkdir -p out/appdir/usr/bin out/appdir/usr/share/doc/{alephone,ffmpeg}
cp build/Source_Files/alephone out/appdir/usr/bin
cp ../{AUTHORS,COPYING,THANKS} out/appdir/usr/share/doc/alephone
cp ffmpeg/{*.md,MAINTAINERS,Changelog} out/appdir/usr/share/doc/ffmpeg
cp -r out/appdir out/alephone.appdir
cp -r out/appdir out/marathon.appdir
cp -r out/appdir out/marathon2.appdir
cp -r out/appdir out/marathon-infinity.appdir
cp -r out/appdir out/marathon-trilogy.appdir
cp -r ../data/Scenarios/Marathon out/marathon.appdir/usr/share
cp -r ../data/Scenarios/"Marathon 2" out/marathon2.appdir/usr/share
cp -r ../data/Scenarios/"Marathon Infinity" out/marathon-infinity.appdir/usr/share
cp -r ../data/Scenarios out/marathon-trilogy.appdir/usr/share
cp /usr/bin/xmessage out/marathon-trilogy.appdir/usr/bin

# create AppImages
cd out
deploy=../build/linuxdeploy.AppImage
$deploy -oappimage --appdir=alephone.appdir          -d../alephone.desktop          -i../alephone.png
$deploy -oappimage --appdir=marathon.appdir          -d../marathon.desktop          -i../marathon.png          --custom-apprun=../apprun-marathon.sh
$deploy -oappimage --appdir=marathon2.appdir         -d../marathon2.desktop         -i../marathon2.png         --custom-apprun=../apprun-marathon2.sh
$deploy -oappimage --appdir=marathon-infinity.appdir -d../marathon-infinity.desktop -i../marathon-infinity.png --custom-apprun=../apprun-marathon-infinity.sh
$deploy -oappimage --appdir=marathon-trilogy.appdir  -d../marathon-trilogy.desktop  -i../alephone.png          --custom-apprun=../apprun-marathon-trilogy.sh
