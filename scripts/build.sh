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

