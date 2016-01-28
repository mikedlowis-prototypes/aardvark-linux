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
rm -f "$AL_TOOLS/$AL_TGT/lib/libc.so"
[ ! -L "$AL_ROOT/sbin" ] && ln -sfv bin "$AL_ROOT/sbin"
[ ! -L "$AL_ROOT/usr" ] && ln -sfv . "$AL_ROOT/usr"
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

# Install sbase
gitclone http://git.suckless.org/sbase "$AL_SOURCES/sbase"
if [ ! -f "$AL_ROOT/bin/ls" ]; then
    cd "$AL_SOURCES/sbase"
    git checkout .
    git apply ../../patches/sbase.diff
    make $MAKEFLAGS CC="$CC" LD="$LD" LDFLAGS="$LDFLAGS"
    make $MAKEFLAGS PREFIX=$AL_ROOT install
    #rm -f "$AL_ROOT/bin/grep"
    cd $AL
fi

# Install ubase
gitclone http://git.suckless.org/ubase "$AL_SOURCES/ubase"
if [ ! -f "$AL_ROOT/bin/clear" ]; then
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

# Install shadow
fetch shadow-4.2.1.tar.xz http://pkg-shadow.alioth.debian.org/releases/ "$AL_SOURCES/shadow"
if [ ! -f "$AL_ROOT/bin/groups" ]; then
    cd "$AL_SOURCES/shadow"
    ./configure             \
        LDFLAGS="--static"  \
        --prefix="$AL_ROOT" \
        --exec-prefix="$AL_ROOT" \
        --sysconfdir="$AL_ROOT/etc"   \
        --with-group-name-max-length=32
    make $MAKEFLAGS install
    sed -i 's/yes/no/; s/bash/sh/' "$AL_ROOT/etc/default/useradd"
    cd $AL
fi

# Install Iana-Etc files
fetch iana-etc-2.30.tar.bz2 http://anduin.linuxfromscratch.org/sources/LFS/lfs-packages/conglomeration/iana-etc/ "$AL_SOURCES/iana-etc"
if [ ! -f "$AL_ROOT/etc/services" ]; then
    cd "$AL_SOURCES/iana-etc"
    make PREFIX="$AL_ROOT" install
    cd $AL
fi

#------------------------------------------------------------------------------
# Install GNU packages
#------------------------------------------------------------------------------
# These packages should be replaced with non-gnu versions when possible

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
    cp "$AL_SOURCES/gawk/gawk" "$AL_ROOT/bin/gawk"
    ln -sfv gawk "$AL_ROOT/bin/awk"
    cd $AL
fi

# Install GNU diffutils
fetch diffutils-3.3.tar.xz http://ftp.gnu.org/gnu/diffutils/ "$AL_SOURCES/diffutils"
if [ ! -f "$AL_ROOT/bin/diff" ]; then
    cd "$AL_SOURCES/diffutils"
    ./configure \
        --prefix="$AL_ROOT"
    make $MAKEFLAGS install
    cd $AL
fi

## Install GNU grep
#fetch grep-2.9.tar.xz http://ftp.gnu.org/gnu/grep/ "$AL_SOURCES/grep"
#if [ ! -f "$AL_ROOT/bin/grep" ]; then
#    cd "$AL_SOURCES/grep"
#    ./configure             \
#        LDFLAGS="--static"  \
#        --prefix="$AL_ROOT" \
#        --disable-threads   \
#        --disable-rpath     \
#        --disable-nls
#    make $MAKEFLAGS install
#    cd $AL
#fi

# Install GNU tar
#fetch tar-1.28.tar.xz http://ftp.gnu.org/gnu/tar/ "$AL_SOURCES/tar"
#if [ ! -f "$AL_ROOT/bin/tar" ]; then
#    cd "$AL_SOURCES/tar"
#    ./configure \
#        --prefix="$AL_ROOT"
#    make $MAKEFLAGS install
#    cd $AL
#fi

## Install GNU make
#fetch make-4.1.tar.gz http://ftp.gnu.org/gnu/make/ "$AL_SOURCES/make"
#if [ ! -f "$AL_ROOT/bin/make" ]; then
#    cd "$AL_SOURCES/make"
#    ./configure              \
#        LDFLAGS="--static"   \
#        --prefix="$AL_ROOT"  \
#        --without-guile
#    make $MAKEFLAGS install
#    cd $AL
#fi


# Install GNU inetutils
#fetch inetutils-1.9.4.tar.xz http://ftp.gnu.org/gnu/inetutils/ "$AL_SOURCES/inetutils"
#if [ ! -f "$AL_ROOT/bin/ping" ]; then
#    cd "$AL_SOURCES/inetutils"
#    ./configure              \
#        --prefix="$AL_ROOT"  \
#        --localstatedir=/var \
#        --disable-logger     \
#        --disable-rcp        \
#        --disable-rexec      \
#        --disable-rlogin     \
#        --disable-rsh        \
#        --disable-servers
#    make $MAKEFLAGS install
#    cd $AL
#fi

## Install GNU bc
#fetch bc-1.06.tar.gz http://ftp.gnu.org/gnu/bc/ "$AL_SOURCES/bc"
#if [ ! -f "$AL_ROOT/bin/bc" ]; then
#    cd "$AL_SOURCES/bc"
#    ./configure              \
#        LDFLAGS="--static"   \
#        --prefix="$AL_ROOT"
#    make $MAKEFLAGS install
#    cd $AL
#fi
#
## Install GNU gzip
#fetch gzip-1.6.tar.xz http://ftp.gnu.org/gnu/gzip/ "$AL_SOURCES/gzip"
#if [ ! -f "$AL_ROOT/bin/gzip" ]; then
#    cd "$AL_SOURCES/gzip"
#    ./configure              \
#        LDFLAGS="--static"   \
#        --prefix="$AL_ROOT"
#    make $MAKEFLAGS install
#    cd $AL
#fi
#
## Install GNU ncurses
#fetch ncurses-6.0.tar.gz http://ftp.gnu.org/gnu/ncurses/ "$AL_SOURCES/ncurses"
#if [ ! -f "$AL_ROOT/lib/ncurses" ]; then
#    cd "$AL_SOURCES/ncurses"
#    ./configure              \
#        LDFLAGS="--static"   \
#        --prefix="$AL_TOOLS/lib/gcc/$AL_TGT/5.3.0"  \
#        --without-shared     \
#        --without-debug      \
#        --without-ada        \
#        --enable-widec       \
#        --enable-overwrite
#    make $MAKEFLAGS install
#    cd $AL
#fi
#/tools/bin/../lib/gcc/x86_64-linux-musl/5.3.0/include
#
## Install Perl
#fetch perl-5.22.0.tar.bz2 http://www.cpan.org/src/5.0/ "$AL_SOURCES/perl"
#if [ ! -f "$AL_ROOT/bin/perl" ]; then
#    cd "$AL_SOURCES/perl"
#    ./Configure -des -Dprefix="$AL_ROOT"
#    make $MAKEFLAGS
#    cd $AL
#fi

###############################################################################
# Install Sources
###############################################################################
fetch    pkgsrc.tar.bz2      http://ftp.netbsd.org/pub/pkgsrc/stable/      "$AL_ROOT/pkgsrc/"

#fetch    musl-1.1.12.tar.gz  http://www.musl-libc.org/releases/            "$AL_ROOT/src/musl"
#gitclone                     http://git.suckless.org/sbase                 "$AL_ROOT/src/sbase"
#gitclone                     http://git.suckless.org/ubase                 "$AL_ROOT/src/ubase"
#fetch    mksh-R52b.tgz       https://www.mirbsd.org/MirOS/dist/mir/mksh/   "$AL_ROOT/src/mksh"
#fetch    make-4.1.tar.gz     http://ftp.gnu.org/gnu/make/                  "$AL_ROOT/src/make"
#fetch    grep-2.9.tar.xz     http://ftp.gnu.org/gnu/grep/                  "$AL_ROOT/src/grep"
#fetch    gawk-4.1.3.tar.xz   http://ftp.gnu.org/gnu/gawk/                  "$AL_ROOT/src/gawk"
#fetch    bc-1.06.tar.gz      http://ftp.gnu.org/gnu/bc/                    "$AL_ROOT/src/bc"
#fetch    gzip-1.6.tar.xz     http://ftp.gnu.org/gnu/gzip/                  "$AL_ROOT/src/gzip"
#fetch    ncurses-6.0.tar.gz  http://ftp.gnu.org/gnu/ncurses/               "$AL_ROOT/src/ncurses"
#fetch    perl-5.22.0.tar.bz2 http://www.cpan.org/src/5.0/                  "$AL_ROOT/src/perl"
#fetch    linux-4.4.tar.xz    https://cdn.kernel.org/pub/linux/kernel/v4.x/ "$AL_ROOT/src/linux"

###############################################################################
# Finalize the Chroot
###############################################################################
ln -sfv "$AL_TGT-addr2line"  "$AL_TOOLS/bin/addr2line"
ln -sfv "$AL_TGT-ar"         "$AL_TOOLS/bin/ar"
ln -sfv "$AL_TGT-as"         "$AL_TOOLS/bin/as"
ln -sfv "$AL_TGT-c++"        "$AL_TOOLS/bin/c++"
ln -sfv "$AL_TGT-c++filt"    "$AL_TOOLS/bin/c++filt"
ln -sfv "$AL_TGT-cpp"        "$AL_TOOLS/bin/cpp"
ln -sfv "$AL_TGT-elfedit"    "$AL_TOOLS/bin/elfedit"
ln -sfv "$AL_TGT-g++"        "$AL_TOOLS/bin/g++"
ln -sfv "$AL_TGT-gcc"        "$AL_TOOLS/bin/gcc"
ln -sfv "$AL_TGT-gcc-5.3.0"  "$AL_TOOLS/bin/gcc-5.3.0"
ln -sfv "$AL_TGT-gcc-ar"     "$AL_TOOLS/bin/gcc-ar"
ln -sfv "$AL_TGT-gcc-nm"     "$AL_TOOLS/bin/gcc-nm"
ln -sfv "$AL_TGT-gcc-ranlib" "$AL_TOOLS/bin/gcc-ranlib"
ln -sfv "$AL_TGT-gcov"       "$AL_TOOLS/bin/gcov"
ln -sfv "$AL_TGT-gcov-tool"  "$AL_TOOLS/bin/gcov-tool"
ln -sfv "$AL_TGT-gprof"      "$AL_TOOLS/bin/gprof"
ln -sfv "$AL_TGT-ld"         "$AL_TOOLS/bin/ld"
ln -sfv "$AL_TGT-ld.bfd"     "$AL_TOOLS/bin/ld.bfd"
ln -sfv "$AL_TGT-nm"         "$AL_TOOLS/bin/nm"
ln -sfv "$AL_TGT-objcopy"    "$AL_TOOLS/bin/objcopy"
ln -sfv "$AL_TGT-objdump"    "$AL_TOOLS/bin/objdump"
ln -sfv "$AL_TGT-ranlib"     "$AL_TOOLS/bin/ranlib"
ln -sfv "$AL_TGT-readelf"    "$AL_TOOLS/bin/readelf"
ln -sfv "$AL_TGT-size"       "$AL_TOOLS/bin/size"
ln -sfv "$AL_TGT-strings"    "$AL_TOOLS/bin/strings"
ln -sfv "$AL_TGT-strip"      "$AL_TOOLS/bin/strip"
#strip $AL_ROOT/bin/*
