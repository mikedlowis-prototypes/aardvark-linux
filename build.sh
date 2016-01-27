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
        mkdir -p "$AL_SOURCES"
        if [ ! -f "$AL_SOURCES/$1" ]; then
            echo curl -L --retry 5 "$2/$1" > "$AL_SOURCES/$1"
            curl -L --retry 5 "$2/$1" > "$AL_SOURCES/$1"
        fi
        mkdir -p "$3"
        tar -xvf "$AL_SOURCES/$1" -C "$3" --strip-components 1
    fi
}

gitclone(){
    if [ ! -d "$2" ]; then
        git clone --depth 1 $1 $2
    fi
}

###############################################################################
# Install the Base Packages
###############################################################################
# Fetch the prebuilt cross compiler
fetch crossx86-x86_64-linux-musl-1.1.12.tar.xz \
      https://e82b27f594c813a5a4ea5b07b06f16c3777c3b8c.googledrive.com/host/0BwnS5DMB0YQ6bDhPZkpOYVFhbk0/musl-1.1.12/ \
      "$AL_TOOLS"

# Install sbase
gitclone http://git.suckless.org/sbase "$AL_SOURCES/sbase"
if [ ! -f "$AL_ROOT/bin/ls" ]; then
    cd "$AL_SOURCES/sbase"
    make $MAKEFLAGS CC="$CC" LD="$LD" LDFLAGS="$LDFLAGS"
    make $MAKEFLAGS PREFIX=$AL_ROOT install
    rm -f "$AL_ROOT/bin/grep"
    cd $AL
fi

# Install ubase
gitclone http://git.suckless.org/ubase "$AL_SOURCES/ubase"
if [ ! -f "$AL_ROOT/bin/clear" ]; then
    echo ubase
    cd "$AL_SOURCES/ubase"
    make $MAKEFLAGS CC="$CC" LD="$LD" LDFLAGS="$LDFLAGS"
    make $MAKEFLAGS PREFIX=$AL_ROOT install
    cd $AL
fi

# Install mksh
fetch mksh-R52b.tgz https://www.mirbsd.org/MirOS/dist/mir/mksh/ "$AL_SOURCES/mksh"
if [ ! -f "$AL_ROOT/bin/mksh" ]; then
    cd "$AL_SOURCES/mksh"
    chmod +x Build.sh
    ./Build.sh
    mkdir -p "$AL_ROOT/etc/" "$AL_ROOT/share/doc/mksh/examples"
    cp -f mksh "$AL_ROOT/bin/"
    chmod 555 "$AL_ROOT/bin/mksh"
    cp -f dot.mkshrc "$AL_ROOT/share/doc/mksh/examples"
    ln -svf mksh "$AL_ROOT/bin/sh"
    cd $AL
fi

# Install GNU grep
fetch grep-2.9.tar.xz http://ftp.gnu.org/gnu/grep/ "$AL_SOURCES/grep"
if [ ! -f "$AL_ROOT/bin/grep" ]; then
    cd "$AL_SOURCES/grep"
    ./configure             \
        LDFLAGS="--static"  \
        --prefix="$AL_ROOT" \
        --disable-threads   \
        --disable-rpath     \
        --disable-nls
    make $MAKEFLAGS install
    cd $AL
fi

# Install GNU awk
fetch gawk-4.1.3.tar.xz http://ftp.gnu.org/gnu/gawk/ "$AL_SOURCES/gawk"
if [ ! -f "$AL_ROOT/bin/gawk" ]; then
    cd "$AL_SOURCES/gawk"
    ./configure              \
        LDFLAGS="--static"   \
        --prefix="$AL_ROOT"  \
        --disable-extensions \
        --disable-rpath      \
        --disable-nls        \
        --without-readline
    make $MAKEFLAGS gawk
    cp "$AL_SOURCES/gawk/gawk" "$AL_ROOT/bin"
    cd $AL
fi

# Install GNU make
fetch make-4.1.tar.gz http://ftp.gnu.org/gnu/make/ "$AL_SOURCES/make"
if [ ! -f "$AL_ROOT/bin/make" ]; then
    cd "$AL_SOURCES/make"
    ./configure              \
        LDFLAGS="--static"   \
        --prefix="$AL_ROOT"  \
        --without-guile
    make $MAKEFLAGS install
    cd $AL
fi

###############################################################################
# Install Sources
###############################################################################
fetch linux-4.4.tar.xz https://cdn.kernel.org/pub/linux/kernel/v4.x/ "$AL_ROOT/src/linux"
#fetch make-4.1.tar.gz http://ftp.gnu.org/gnu/make/ "$AL_ROOT/src/make"
#fetch musl-1.1.12.tar.gz http://www.musl-libc.org/releases/ "$AL_SOURCES/musl"

###############################################################################
# Finalize the Chroot
###############################################################################
mkdir -pv "$AL_ROOT/dev"
mkdir -pv "$AL_ROOT/proc"
mkdir -pv "$AL_ROOT/sys"
mkdir -pv "$AL_ROOT/tmp"
mkdir -pv "$AL_ROOT/root"
