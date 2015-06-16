#!/bin/sh

# Turn off command hashing and make the script exit when a command errors.
set -e

# Load the configuration
. ./config

# Setup the path to use new tools as they become available
export PATH=$LFS_TOOLS/bin:$PATH

download(){
    mkdir -p "$LFS_TARBALLS"
    if [ ! -f "$LFS_TARBALLS/$1" ]; then
        curl "$2/$1" > "$LFS_TARBALLS/$1"
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

# Extract the tarballs
extract "$LFS_TARBALLS/binutils-2.25.tar.bz2" "$LFS_TARBALLS/binutils"
extract "$LFS_TARBALLS/llvm-3.6.1.src.tar.xz" "$LFS_TARBALLS/llvm"
extract "$LFS_TARBALLS/cfe-3.6.1.src.tar.xz" "$LFS_TARBALLS/llvm/tools/clang"

# Build binutils and install it in the tools prefix
mkdir -p "$LFS_TARBALLS/binutils/build"
cd "$LFS_TARBALLS/binutils/build"
if [ ! -f Makefile ]; then
    ../configure --disable-shared --with-sysroot --prefix="$LFS_TOOLS"
fi
if [ ! -f "$LFS_TOOLS/bin/ar" ]; then
    make
    make install
fi
cd $LFS

# Test that the new linker works
echo 'int main(int argc, char** argv) { return 0; }' > test.c
cc -o test test.c
rm test test.c

# Build clang and install it in the
mkdir -p "$LFS_TARBALLS/llvm/build"
cd "$LFS_TARBALLS/llvm/build"
if [ ! -f Makefile ]; then
    cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$LFS_TOOLS" ../
fi
if [ ! -f "$LFS_TOOLS/bin/clang" ]; then
    make clang
    make install
fi

# Test that the new clang binary works
echo 'int main(int argc, char** argv) { return 0; }' > test.c
clang -o test test.c
rm test test.c

