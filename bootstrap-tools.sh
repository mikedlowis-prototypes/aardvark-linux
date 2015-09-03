#!/bin/sh

###############################################################################
# Configuration Settings
###############################################################################

# Turn off command hashing and make the script exit when a command errors.
set -e

# Load the config settings
. ./config

# Make sure CFLAGS isnt set
unset CFLAGS

###############################################################################
# Helper Functions
###############################################################################
fetch(){
    if [ ! -d "$3" ]; then
        mkdir -p "$AL_TARBALLS"
        if [ ! -f "$AL_TARBALLS/$1" ]; then
            echo curl -L --retry 5 "$2/$1" > "$AL_TARBALLS/$1"
            curl -L --retry 5 "$2/$1" > "$AL_TARBALLS/$1"
        fi
        mkdir -p "$3"
        tar -xvf "$AL_TARBALLS/$1" -C "$3" --strip-components 1
    fi
}

gitclone(){
    if [ ! -d "$2" ]; then
        git clone --depth 1 $1 $2
    fi
}

###############################################################################
# Check Command Requirements
###############################################################################

cmds="git curl make xz"
echo Checking for required commands:
for cmd in $cmds; do
    type $cmd || echo Required command not found: $cmd
done

###############################################################################
# Fetch and Extract Dependencies
###############################################################################
fetch linux-4.2.tar.xz      http://www.kernel.org/pub/linux/kernel/v4.x/    "$AL_SOURCES/linux"
fetch binutils-2.25.tar.bz2 http://ftp.gnu.org/gnu/binutils/                "$AL_SOURCES/binutils"
fetch gcc-5.2.0.tar.bz2     http://ftp.gnu.org/gnu/gcc/gcc-5.2.0/           "$AL_SOURCES/gcc"
fetch gmp-6.0.0a.tar.xz     http://ftp.gnu.org/gnu/gmp/                     "$AL_SOURCES/gcc/gmp"
fetch mpc-1.0.3.tar.gz      http://ftp.gnu.org/gnu/mpc/                     "$AL_SOURCES/gcc/mpc"
fetch mpfr-3.1.3.tar.xz     http://ftp.gnu.org/gnu/mpfr/                    "$AL_SOURCES/gcc/mpfr"
fetch musl-1.1.10.tar.gz    http://www.musl-libc.org/releases/              "$AL_SOURCES/musl"
fetch dash-0.5.8.tar.gz     http://gondor.apana.org.au/~herbert/dash/files/ "$AL_SOURCES/dash"

###############################################################################
# Build the Cross-Compiler
###############################################################################

# Create a sysroot directory and link its usr directory to itself
mkdir -vp "$AL_TOOLS/$AL_TGT"
if [ ! -e "$AL_TOOLS/$AL_TGT/usr" ]; then
    ln -sfv . "$AL_TOOLS/$AL_TGT/usr"
fi

# Install the linux headers
cd "$AL_SOURCES/linux"
make mrproper
make ARCH=$AL_ARCH headers_check
make ARCH=$AL_ARCH INSTALL_HDR_PATH=$AL_TOOLS/$AL_TGT headers_install
cd "$AL"

# Install binutils
mkdir -p "$AL_SOURCES/binutils-build"
cd "$AL_SOURCES/binutils-build"
if [ ! -f Makefile ]; then
    ../binutils/configure                  \
        CFLAGS="-static"                   \
        LDFLAGS="--static"                 \
        --prefix="$AL_TOOLS"               \
        --target="$AL_TGT"                 \
        --with-sysroot="$AL_TOOLS/$AL_TGT" \
        --disable-nls                      \
        --disable-multilib                 \
        --disable-shared
fi
make configure-host
make -j8
make install
cd $AL

# Compile initial GCC
mkdir -p "$AL_SOURCES/gcc-build"
cd "$AL_SOURCES/gcc-build"
if [ ! -f Makefile ]; then
    ../gcc/configure                     \
        CFLAGS="-static"                 \
        LDFLAGS="--static"               \
        --prefix=$AL_TOOLS               \
        --build=$AL_HOST                 \
        --host=$AL_HOST                  \
        --target=$AL_TGT                 \
        --with-sysroot=$AL_TOOLS/$AL_TGT \
        --disable-nls                    \
        --disable-shared                 \
        --without-headers                \
        --with-newlib                    \
        --disable-nls                    \
        --disable-shared                 \
        --disable-multilib               \
        --disable-decimal-float          \
        --disable-threads                \
        --disable-libatomic              \
        --disable-libgomp                \
        --disable-libquadmath            \
        --disable-libssp                 \
        --disable-libvtv                 \
        --disable-libstdcxx              \
        --enable-languages=c
fi
make -j8
make install

# Compile the musl libc for the cross compiler
cd "$AL_SOURCES/musl"
if [ ! -f config.mak ]; then
    CC=$AL_TGT-gcc ./configure \
        --prefix=/ \
        --target=$AL_TGT \
        --disable-shared
fi
CC=$AL_TGT-gcc make -j8
DESTDIR=$AL_TOOLS/$AL_TGT make install
cd $AL

# Recompile GCC using the initial GCC and musl libc
mkdir -p "$AL_SOURCES/gcc-final"
cd "$AL_SOURCES/gcc-final"
if [ ! -f Makefile ]; then
    ../gcc/configure                     \
        CFLAGS="-static"                 \
        LDFLAGS="--static"               \
        --prefix=$AL_TOOLS               \
        --build=$AL_HOST                 \
        --host=$AL_HOST                  \
        --target=$AL_TGT                 \
        --with-sysroot=$AL_TOOLS/$AL_TGT \
        --disable-nls                    \
        --disable-shared                 \
        --disable-multilib               \
        --enable-languages=c
fi
make -j8
make install

###############################################################################
# Build the Chroot System
###############################################################################

# Setup to use the cross compiler
export CC="$AL_TGT-gcc"
export CXX="$AL_TGT-g++"
export AR="$AL_TGT-ar"
export AS="$AL_TGT-as"
export LD="$AL_TGT-ld"
export RANLIB="$AL_TGT-ranlib"
export READELF="$AL_TGT-readelf"
export STRIP="$AL_TGT-strip"

# Install sbase
gitclone http://git.suckless.org/sbase $AL_SOURCES/sbase
cd "$AL_SOURCES/sbase"
make CC=$CC -j8
make PREFIX=$AL_ROOT install
cd $AL

# Install ubase
gitclone http://git.suckless.org/ubase $AL_SOURCES/ubase
cd "$AL_SOURCES/ubase"
make CC=$CC -j8
make PREFIX=$AL_ROOT install
cd $AL

# Install dash
cd "$AL_SOURCES/dash"
if [ ! -f Makefile ]; then
    ./configure --prefix=$AL_ROOT
fi
make -j8
make install
cd $AL

mkdir -p $AL_ROOT/$AL_TOOLS

