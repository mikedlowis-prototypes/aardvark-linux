
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
gitclone(){
    if [ ! -d "$2" ]; then
        git clone --depth 1 $1 $2
    fi
}

###############################################################################
# Build the Cross-Compiler
###############################################################################
gitclone https://github.com/sabotage-linux/musl-cross.git "$AL_SOURCES/musl-cross"
cp toolchain-config.sh "$AL_SOURCES/musl-cross/config.sh"
cd "$AL_SOURCES/musl-cross"
./build.sh
cd "$AL"

