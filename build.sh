#!/bin/sh

###############################################################################
# Configuration Settings
###############################################################################

# Turn off command hashing and make the script exit when a command errors.
set -e

# Load the config settings
. ./config.sh

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
# Build the Cross-Compiler
###############################################################################
mkdir -vp $AL_TOOLS
gitclone https://github.com/sabotage-linux/musl-cross.git "$AL_SOURCES/musl-cross"
cd "$AL_SOURCES/musl-cross"
cp "$AL/musl-cross-config.sh" config.sh
./build.sh
cd "$AL"

################################################################################
## Setup the Build Environment
################################################################################
#export CC="$(uname -m)-linux-musl-gcc"
#export CXX="$(uname -m)-linux-musl-g++"
#export AR="$(uname -m)-linux-musl-ar"
#export AS="$(uname -m)-linux-musl-as"
#export LD="$(uname -m)-linux-musl-ld"
#export RANLIB="$(uname -m)-linux-musl-ranlib"
#export READELF="$(uname -m)-linux-musl-readelf"
#export STRIP="$(uname -m)-linux-musl-strip"
#export CFLAGS="-static"
#export LDFLAGS="-static"
#
################################################################################
## Setup the Build Environment
################################################################################
#
## Install sbase
#gitclone http://git.suckless.org/sbase $AL_SOURCES/sbase
#cd "$AL_SOURCES/sbase"
#make CC=$CC -j8
#make PREFIX=$AL_ROOT install
#cd $AL

