#!/bin/bash -e
#
# build_android.sh
# Copyright (c) 2012 Jacek Marchwicki
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# export ANDROID_NDK_HOME=/Users/binxu/Documents/Android/android-ndk-r14b
set -x

if [ "$ANDROID_NDK_HOME" = "" ]; then
	echo ANDROID_NDK_HOME variable not set, exiting
	echo "Use: export ANDROID_NDK_HOME=/your/path/to/android-ndk"
	exit 1
fi

# Get the newest arm-linux-androideabi version
if [ -z "$COMPILATOR_VERSION" ]; then
	DIRECTORIES=$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-*
	for i in $DIRECTORIES; do
		PROPOSED_NAME=${i#*$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-}
		if [[ $PROPOSED_NAME =~ ^[0-9\.]+$ ]] ; then
			echo "Available compilator version: $PROPOSED_NAME"
			COMPILATOR_VERSION=$PROPOSED_NAME
		fi
	done
fi

if [ -z "$COMPILATOR_VERSION" ]; then
	echo "Could not find compilator"
	exit 1
fi

if [ ! -d $ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-$COMPILATOR_VERSION ]; then
	echo $ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-$COMPILATOR_VERSION does not exist
	exit 1
fi
echo "Using compilator version: $COMPILATOR_VERSION"

OS_ARCH=`basename $ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-$COMPILATOR_VERSION/prebuilt/*`
echo "Using architecture: $OS_ARCH"


function setup_paths
{
	export PLATFORM=$ANDROID_NDK_HOME/platforms/$PLATFORM_VERSION/arch-$ARCH/
	if [ ! -d $PLATFORM ]; then
		echo $PLATFORM does not exist
		exit 1
	fi
	echo "Using platform: $PLATFORM"
	export PATH=${PATH}:$PREBUILT/bin/
	export CROSS_COMPILE=$PREBUILT/bin/$EABIARCH-
	export CFLAGS=$OPTIMIZE_CFLAGS
	export CPPFLAGS="$CFLAGS"
	export CFLAGS="$CFLAGS"
	export CXXFLAGS="$CFLAGS"
	export CXX="${CROSS_COMPILE}g++ --sysroot=$PLATFORM"
	export AS="${CROSS_COMPILE}gcc --sysroot=$PLATFORM"
	export CC="${CROSS_COMPILE}gcc --sysroot=$PLATFORM"
	export PKG_CONFIG="${CROSS_COMPILE}pkg-config"
	export LD="${CROSS_COMPILE}ld"
	export NM="${CROSS_COMPILE}nm"
	export STRIP="${CROSS_COMPILE}strip"
	export RANLIB="${CROSS_COMPILE}ranlib"
	export AR="${CROSS_COMPILE}ar"
	export LDFLAGS="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib -nostdlib -lc -lm -ldl -llog -lgcc"
	export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig/
	export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/

	if [ ! -f "${CROSS_COMPILE}gcc" ]; then
		echo "Gcc does not exists in path: ${CROSS_COMPILE}gcc"
		exit 1;
	fi
}

function build_x264
{
	echo "Starting build x264 for $ARCH"
	cd x264
	./configure --prefix=$PREFIX --host=$ARCH-linux --enable-static --enable-pic -march=armv7-a -mfloat-abi=softfp -mfpu=neon $ADDITIONAL_CONFIGURE_FLAG

	make clean
	make -j4 install
	make clean
	cd ..
	echo "FINISHED x264 for $ARCH"
}


function build_aac
{
	echo "Starting build aac for $ARCH"
	cd fdk_aac
	./configure \
	    --prefix=$PREFIX \
	    --host=$ARCH-linux \
	    --disable-dependency-tracking \
	    --disable-shared \
	    --enable-static \
	    --with-pic \
	    $ADDITIONAL_CONFIGURE_FLAG

	make clean
	make -j4 install
	make clean
	cd ..
	echo "FINISHED aac for $ARCH"
}

function build_lame
{
	echo "Starting build lame for $ARCH"
	cd lame
	./configure \
	    --prefix=$PREFIX \
	    --host=$ARCH-linux \
	    --disable-shared \
	    --enable-static \
	    --with-pic \
	    $ADDITIONAL_CONFIGURE_FLAG

	make clean
	make -j4 install
	make clean
	cd ..
	echo "FINISHED aac for $ARCH"
}


#arm v7 + neon (neon also include vfpv3-32)
EABIARCH=arm-linux-androideabi
ARCH=arm
CPU=armv7-a
OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=neon -marm -march=$CPU -mtune=cortex-a8 -mthumb -D__thumb__ "
PREFIX=$(pwd)/build/android/build/exlib/armv7a
ADDITIONAL_CONFIGURE_FLAG=--enable-neon
PREBUILT=$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-$COMPILATOR_VERSION/prebuilt/$OS_ARCH
PLATFORM_VERSION=android-14
setup_paths
build_aac
# build_lame
build_x264


#x86
# EABIARCH=i686-linux-android
# ARCH=x86
# OPTIMIZE_CFLAGS="-m32"
# PREFIX=$(pwd)/ffmpeg-build/x86
# OUT_LIBRARY=$PREFIX/libffmpeg.so
# ADDITIONAL_CONFIGURE_FLAG=--disable-asm
# SONAME=libffmpeg.so
# PREBUILT=$ANDROID_NDK_HOME/toolchains/x86-$COMPILATOR_VERSION/prebuilt/$OS_ARCH
# PLATFORM_VERSION=android-14
# setup_paths
# build_aac
# build_lame
# build_x264
# build_ffmpeg
# build_one

#mips
# EABIARCH=mipsel-linux-android
# ARCH=mips
# OPTIMIZE_CFLAGS="-EL -march=mips32 -mips32 -mhard-float"
# PREFIX=$(pwd)/ffmpeg-build/mips
# OUT_LIBRARY=$PREFIX/libffmpeg.so
# ADDITIONAL_CONFIGURE_FLAG="--disable-mips32r2"
# SONAME=libffmpeg.so
# PREBUILT=$ANDROID_NDK_HOME/toolchains/mipsel-linux-android-$COMPILATOR_VERSION/prebuilt/$OS_ARCH
# PLATFORM_VERSION=android-14
# setup_paths
# build_aac
# build_lame
# build_x264
# build_ffmpeg
# build_one


echo "BUILD SUCCESS"
