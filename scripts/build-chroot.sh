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
# Fetch Dependencies
###############################################################################
gitclone http://git.suckless.org/sbase "$AL_SOURCES/sbase"
gitclone http://git.suckless.org/ubase "$AL_SOURCES/ubase"
fetch dash-0.5.8.tar.gz http://gondor.apana.org.au/~herbert/dash/files/ "$AL_SOURCES/dash"

###############################################################################
# Install Base Software
###############################################################################
cd "$AL_SOURCES/sbase"
make CC=$CC CFLAGS=$CFLAGS LDFLAGS=$LDFLAGS -j8
make PREFIX=$AL_ROOT install
cd "$AL"

#cd "$AL_SOURCES/ubase"
#make CC=$CC CFLAGS=$CFLAGS LDFLAGS=$LDFLAGS -j8
#make PREFIX=$AL_ROOT install
#cd "$AL"

cd "$AL_SOURCES/dash"
./configure --prefix=$AL_ROOT
make -j8
make install
cd $AL

