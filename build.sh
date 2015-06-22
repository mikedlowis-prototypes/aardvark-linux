#!/bin/sh

# Turn off command hashing and make the script exit when a command errors.
set -e

# Load the configuration
. ./config

# Setup the path to use new tools as they become available
export PATH=$AL_TOOLS/bin:$PATH

download(){
    mkdir -p "$AL_TARBALLS"
    if [ ! -f "$AL_TARBALLS/$1" ]; then
        curl "$2/$1" > "$AL_TARBALLS/$1"
    fi
}

extract(){
    if [ ! -d "$2" ]; then
        mkdir -p "$2"
        tar -xvf "$1" -C "$2" --strip-components 1
    fi
}

# Download tarballs
download binutils-2.25.tar.bz2 http://ftp.gnu.org/gnu/binutils/
download cfe-3.6.1.src.tar.xz http://llvm.org/releases/3.6.1/
download llvm-3.6.1.src.tar.xz http://llvm.org/releases/3.6.1/
#download musl-1.1.10.tar.gz http://www.musl-libc.org/releases/

# Extract the tarballs
extract "$AL_TARBALLS/binutils-2.25.tar.bz2" "$AL_TARBALLS/binutils"
extract "$AL_TARBALLS/llvm-3.6.1.src.tar.xz" "$AL_TARBALLS/llvm"
extract "$AL_TARBALLS/cfe-3.6.1.src.tar.xz" "$AL_TARBALLS/llvm/tools/clang"

# Build binutils and install it in the tools prefix
mkdir -p "$AL_TARBALLS/binutils/build"
cd "$AL_TARBALLS/binutils/build"
if [ ! -f Makefile ]; then
    ../configure \
        LDFLAGS="--static" \
        --prefix="$AL_TOOLS" \
        --with-sysroot="$AL" \
        --with-lib-path="$AL_TOOLS" \
        --target="$AL_TGT" \
        --disable-shared \
        --disable-nls \
        --disable-werror
fi
if [ ! -f "$AL_TOOLS/bin/$AL_TGT-ar" ]; then
    make
    make install
fi
cd $AL

# Build clang and install it in the
mkdir -p "$AL_TARBALLS/llvm/build"
cd "$AL_TARBALLS/llvm/build"
if [ ! -f Makefile ]; then
    LDFLAGS="-static" cmake -G"Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$AL_TOOLS" \
        -DBUILD_SHARED_LIBS=OFF \
        -DLLVM_BUILD_TOOLS=OFF \
        -DLLVM_BUILD_EXAMPLES=OFF \
        -DLLVM_BUILD_TESTS=OFF \
        ../
fi
if [ ! -f "$AL_TOOLS/bin/clang" ]; then
    make LDFLAGS="-static" clang
    make install
fi

# Test that the new clang binary works
echo 'int main(int argc, char** argv) { return 0; }' > cctest.c
clang -static -target $AL_TGT -o cctest cctest.c
if [ "0" -ne "`readelf -d cctest | grep -c '0x'`" ]; then
    rm cctest cctest.c
    echo "Expected toolchain to compile statically but target was dynamically linked."
    exit 1
else
    rm cctest cctest.c
fi
