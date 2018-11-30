#!/bin/bash -e
#

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
	export LDFLAGS="-Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib -nostdlib -lc -lm -ldl -llog"
	export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig/
	export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/

	if [ ! -f "${CROSS_COMPILE}gcc" ]; then
		echo "Gcc does not exists in path: ${CROSS_COMPILE}gcc"
		exit 1;
	fi

	if [ ! -f "${PKG_CONFIG}" ]; then
		echo "Pkg config does not exists in path: ${PKG_CONFIG} - Probably BUG in NDK but..."
		set +e
		SYS_PKG_CONFIG=$(which pkg-config)
		if [ "$?" -ne 0 ]; then
			echo "This system does not contain system pkg-config, so we can do anything"
			exit 1
		fi
		set -e
		cat > $PKG_CONFIG << EOF
#!/bin/bash
pkg-config \$*
EOF
		chmod u+x $PKG_CONFIG
		echo "Because we have local pkg-config we will create it in ${PKG_CONFIG} directory using ${SYS_PKG_CONFIG}"
	fi
}

function build_x264
{
	echo "Starting build x264 for $ARCH"
	cd x264
	./configure --prefix=$PREFIX --host=$ARCH-linux --enable-static $ADDITIONAL_CONFIGURE_FLAG

	make clean
	make -j4 install
	make clean
	cd ..
	echo "FINISHED x264 for $ARCH"
}

function build_aac
{
	echo "Starting build aac for $ARCH"
	cd vo-aacenc
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



#arm v5
# EABIARCH=arm-linux-androideabi
# ARCH=arm
# CPU=armv5
# OPTIMIZE_CFLAGS="-marm -march=$CPU"
# PREFIX=$(pwd)/build/android/ffmpeg-armv5/output
# ADDITIONAL_CONFIGURE_FLAG=
# PREBUILT=$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-$COMPILATOR_VERSION/prebuilt/$OS_ARCH
# PLATFORM_VERSION=android-5
# setup_paths
# build_x264
# build_aac


#x86
# EABIARCH=i686-linux-android
# ARCH=x86
# OPTIMIZE_CFLAGS="-m32"
# PREFIX=$(pwd)/build/android/ffmpeg-x86/output
# ADDITIONAL_CONFIGURE_FLAG=--disable-asm
# PREBUILT=$ANDROID_NDK_HOME/toolchains/x86-$COMPILATOR_VERSION/prebuilt/$OS_ARCH
# PLATFORM_VERSION=android-9
# setup_paths
# setup_paths
# build_x264
# build_aac


#arm v7
EABIARCH=arm-linux-androideabi
ARCH=arm
CPU=armv7-a
OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=neon -marm -march=$CPU -mtune=cortex-a8 -mthumb -D__thumb__ "
PREFIX=$(pwd)/build/android/ffmpeg-armv7a/output
ADDITIONAL_CONFIGURE_FLAG=--enable-neon
PREBUILT=$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-$COMPILATOR_VERSION/prebuilt/$OS_ARCH
PLATFORM_VERSION=android-9
setup_paths
build_x264
build_aac

echo "BUILD SUCCESS"
