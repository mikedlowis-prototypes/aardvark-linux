#!/bin/sh

###############################################################################
# Configuration Settings
###############################################################################

# Turn off command hashing and make the script exit when a command errors.
set -e

# Load the config settings
. ./config.sh

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
# Build the Cross-Compiler
###############################################################################
if [ ! -d "$AL_TOOLS/$(uname -m)-linux-musl" ]; then
    mkdir -vp $AL_TOOLS
    gitclone https://github.com/sabotage-linux/musl-cross.git "$AL_SOURCES/musl-cross"
    cd "$AL_SOURCES/musl-cross"
    cp "$AL/musl-cross-config.sh" config.sh
    ./build.sh
    cd "$AL"
fi

################################################################################
## Setup the Build Environment
################################################################################
export CC="$(uname -m)-linux-musl-gcc"
export CXX="$(uname -m)-linux-musl-g++"
export AR="$(uname -m)-linux-musl-ar"
export AS="$(uname -m)-linux-musl-as"
export LD="$(uname -m)-linux-musl-ld"
export RANLIB="$(uname -m)-linux-musl-ranlib"
export READELF="$(uname -m)-linux-musl-readelf"
export STRIP="$(uname -m)-linux-musl-strip"
export LDFLAGS="--static"

################################################################################
## Setup the Build Environment
################################################################################

# Install sbase
gitclone http://git.suckless.org/sbase "$AL_SOURCES/sbase"
cd "$AL_SOURCES/sbase"
make CC="$CC" LD="$LD" LDFLAGS="$LDFLAGS" -j8
make PREFIX=$AL_ROOT install
cd $AL

# Install ubase
gitclone http://git.suckless.org/ubase "$AL_SOURCES/ubase"
cd "$AL_SOURCES/ubase"
make CC="$CC" LD="$LD" LDFLAGS="$LDFLAGS" -j8
make PREFIX=$AL_ROOT install
cd $AL

# Install mksh
fetch mksh-R52b.tgz https://www.mirbsd.org/MirOS/dist/mir/mksh/ "$AL_SOURCES/mksh"
cd "$AL_SOURCES/mksh"
if [ ! -f mksh ]; then
    chmod +x Build.sh
    ./Build.sh
fi
mkdir -p "$AL_ROOT/etc/" "$AL_ROOT/share/doc/mksh/examples"
cp -f mksh "$AL_ROOT/bin/"
chmod 555 "$AL_ROOT/bin/mksh"
cp -f dot.mkshrc "$AL_ROOT/share/doc/mksh/examples"
ln -svf mksh "$AL_ROOT/bin/sh"
cd $AL

# Install make
fetch make-4.1.tar.gz http://ftp.gnu.org/gnu/make/ "$AL_ROOT/src/make"
#cd "$AL_SOURCES/make"
#if [ ! -f "$AL_ROOT/bin/make" ]; then
#    ./configure               \
#        --prefix="$AL_TOOLS/" \
#        --without-guile       \
#        --without-dmalloc     \
#        --disable-nls         \
#        --disable-rpath       \
#        --disable-largefile   \
#        --disable-job-server  \
#        --disable-load
#    make -j8
#    make install
#fi
#cd "$AL"

# Install kernel sources
fetch linux-4.4.tar.xz https://cdn.kernel.org/pub/linux/kernel/v4.x/ "$AL_ROOT/src/linux"

