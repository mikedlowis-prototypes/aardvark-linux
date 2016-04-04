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
            echo fetching "$2/$1"
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

symlink(){
    target=$1
    dest=$2
    if [ ! -L "$dest" ]; then
        ln -sfv "$target" "$dest"
    fi
}

###############################################################################
# Install the Toolchain
###############################################################################
# Fetch the prebuilt cross compiler
fetch crossx86-x86_64-linux-musl-1.1.12.tar.xz \
      https://e82b27f594c813a5a4ea5b07b06f16c3777c3b8c.googledrive.com/host/0BwnS5DMB0YQ6bDhPZkpOYVFhbk0/musl-1.1.12/ \
      "$AL_TOOLS"
rm -f "$AL_TOOLS/x86_64-linux-musl/lib/libc.so"
#symlink bin "$AL_ROOT/sbin"
#symlink .   "$AL_ROOT/usr"
mkdir -pv "$AL_ROOT/bin"
mkdir -pv "$AL_ROOT/dev"
mkdir -pv "$AL_ROOT/etc"
mkdir -pv "$AL_ROOT/proc"
mkdir -pv "$AL_ROOT/sys"
mkdir -pv "$AL_ROOT/tmp"
mkdir -pv "$AL_ROOT/root"
mkdir -pv "$AL_ROOT/var"
cp etc/* "$AL_ROOT/etc/"
cp bin/* "$AL_ROOT/bin/"

# Install musl
fetch musl-1.1.12.tar.gz http://www.musl-libc.org/releases/ "$AL_ROOT/src/musl"
if [ ! -f "$AL_ROOT/lib/libc.a" ]; then
    cd "$AL_ROOT/src/musl"
    ./configure --prefix="$AL_ROOT" --disable-shared
    make $MAKEFLAGS install
    make clean
    cd $AL
fi

# Install pcc
gitclone https://github.com/antoineL/pcc.git "$AL_ROOT/src/pcc"
if [ ! -f "$AL_ROOT/bin/cc" ]; then
    cd "$AL_ROOT/src/pcc/"
    cp "$AL/cc.c" "$AL_ROOT/src/pcc/cc/cc/"
    cp "$AL/ccconfig.h" "$AL_ROOT/src/pcc/os/linux/"
    ./configure                      \
        --prefix="$AL_ROOT"          \
        --exec-prefix="$AL_ROOT"     \
        --sbindir="$AL_ROOT/bin"     \
        --libexecdir="$AL_ROOT/bin"  \
        --with-libdir="/lib"         \
        --enable-native
    make $MAKEFLAGS
    make install
    cp cc/cc/cc "$AL_ROOT/bin"
    chmod 755 "$AL_ROOT/bin/cc"
    make clean
    cd $AL
fi

# Install binutils
fetch binutils-2.25.tar.bz2 http://ftp.gnu.org/gnu/binutils/ "$AL_ROOT/src/binutils"
if [ ! -f "$AL_ROOT/bin/as" ]; then
    cd "$AL_ROOT/src/binutils/"
    ./configure \
        --prefix="$AL_ROOT"       \
        --exec-prefix="$AL_ROOT"  \
        --disable-shared
    make $MAKEFLAGS
    make install
    make clean
    cd $AL
fi

# Install byacc
fetch byacc.tar.gz http://invisible-island.net/datafiles/release/ "$AL_ROOT/src/byacc"
if [ ! -f "$AL_ROOT/bin/yacc" ]; then
    cd "$AL_ROOT/src/byacc/"
    ./configure \
        --prefix="$AL_ROOT"      \
        --exec-prefix="$AL_ROOT"
    make $MAKEFLAGS
    make install
    make clean
    cd $AL
fi

###############################################################################
# Install the Base Packages
###############################################################################
# Install sbase
gitclone http://git.suckless.org/sbase "$AL_ROOT/src/sbase"
if [ ! -f "$AL_ROOT/bin/ls" ]; then
    cd "$AL_ROOT/src/sbase"
    git checkout .
    #git apply ../../../patches/sbase.diff
    make $MAKEFLAGS CC="$CC" LD="$LD" LDFLAGS="$LDFLAGS"
    make $MAKEFLAGS PREFIX=$AL_ROOT install
    make clean
    cd $AL
fi

# Install ubase
gitclone http://git.suckless.org/ubase "$AL_ROOT/src/ubase"
if [ ! -f "$AL_ROOT/bin/clear" ]; then
    cd "$AL_ROOT/src/ubase"
    make $MAKEFLAGS CC="$CC" LD="$LD" LDFLAGS="$LDFLAGS"
    make $MAKEFLAGS PREFIX=$AL_ROOT install
    make clean
    cd $AL
fi

# Install mksh
fetch mksh-R52b.tgz https://www.mirbsd.org/MirOS/dist/mir/mksh/ "$AL_ROOT/src/mksh"
if [ ! -f "$AL_ROOT/bin/mksh" ]; then
    cd "$AL_ROOT/src/mksh"
    chmod +x Build.sh
    ./Build.sh
    mkdir -p "$AL_ROOT/etc/" "$AL_ROOT/share/doc/mksh/examples"
    cp -f mksh "$AL_ROOT/bin/"
    chmod 555 "$AL_ROOT/bin/mksh"
    cp -f dot.mkshrc "$AL_ROOT/share/doc/mksh/examples"
    ln -svf mksh "$AL_ROOT/bin/sh"
    cd $AL
fi

# Install shadow
fetch shadow-4.2.1.tar.xz http://pkg-shadow.alioth.debian.org/releases/ "$AL_ROOT/src/shadow"
if [ ! -f "$AL_ROOT/bin/groups" ]; then
    cd "$AL_ROOT/src/shadow"
    ./configure             \
        LDFLAGS="--static"  \
        --prefix="$AL_ROOT" \
        --exec-prefix="$AL_ROOT" \
        --sbindir="$AL_ROOT/bin" \
        --sysconfdir="$AL_ROOT/etc"   \
        --with-group-name-max-length=32
    make $MAKEFLAGS install
    make clean
    sed -i 's/yes/no/; s/bash/sh/' "$AL_ROOT/etc/default/useradd"
    cd $AL
fi

# Install Iana-Etc files
fetch iana-etc-2.30.tar.bz2 http://anduin.linuxfromscratch.org/sources/LFS/lfs-packages/conglomeration/iana-etc/ "$AL_ROOT/src/iana-etc"
if [ ! -f "$AL_ROOT/etc/services" ]; then
    cd "$AL_ROOT/src/iana-etc"
    make PREFIX="$AL_ROOT" install
    make clean
    cd $AL
fi

# Install curses
gitclone https://github.com/sabotage-linux/netbsd-curses.git "$AL_ROOT/src/curses"
if [ ! -f "$AL_ROOT/lib/libcurses.a" ]; then
    cd "$AL_ROOT/src/curses/"
    make $MAKE_FLAGS LDFLAGS=-static PREFIX=$AL_ROOT all-static install-static
    make clean
    cd $AL
fi

# Install sandy
gitclone http://git.suckless.org/sandy "$AL_ROOT/src/sandy"
if [ ! -f "$AL_ROOT/bin/sandy" ]; then
    cd "$AL_ROOT/src/sandy/"
    make $MAKE_FLAGS CC=$CC LD=$LD INCS="-I. -I$AL_ROOT/include" LIBS="-L$AL_ROOT/lib -lncurses -lterminfo"
    make PREFIX=$AL_ROOT install
    make clean
    cd $AL
fi

#------------------------------------------------------------------------------
# Install GNU packages
#------------------------------------------------------------------------------
# These packages should be replaced with non-gnu versions when possible

# Install GNU awk
fetch gawk-4.1.3.tar.xz http://ftp.gnu.org/gnu/gawk/ "$AL_ROOT/src/gawk"
if [ ! -f "$AL_ROOT/bin/gawk" ]; then
    cd "$AL_ROOT/src/gawk"
    ./configure              \
        LDFLAGS="--static"   \
        --prefix="$AL_ROOT"  \
        --disable-extensions \
        --disable-rpath      \
        --disable-nls        \
        --without-readline
    make $MAKEFLAGS gawk
    cp "$AL_ROOT/src/gawk/gawk" "$AL_ROOT/bin/gawk"
    ln -sfv gawk "$AL_ROOT/bin/awk"
    make clean || true # gawks makefile is busted :(
    cd $AL
fi

# Install GNU diffutils
fetch diffutils-3.3.tar.xz http://ftp.gnu.org/gnu/diffutils/ "$AL_ROOT/src/diffutils"
if [ ! -f "$AL_ROOT/bin/diff" ]; then
    cd "$AL_ROOT/src/diffutils"
    ./configure \
        --prefix="$AL_ROOT"
    make $MAKEFLAGS install
    make clean
    cd $AL
fi

# Install GNU make
fetch make-4.1.tar.gz http://ftp.gnu.org/gnu/make/ "$AL_ROOT/src/make"
if [ ! -f "$AL_ROOT/bin/make" ]; then
    cd "$AL_ROOT/src/make"
    ./configure              \
        LDFLAGS="--static"   \
        --prefix="$AL_ROOT"  \
        --without-guile
    make $MAKEFLAGS install
    make clean
    cd $AL
fi

