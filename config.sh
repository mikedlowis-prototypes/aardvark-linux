###############################################################################
# Aardvark Linux Build Config
###############################################################################
# Define a variable to point to the root of the project
export AL=$PWD

# Set the locale to be UTF-8
export LC_ALL=en_US.UTF-8
export LANG=$LC_ALL
export LANGUAGE=$LC_ALL

# Variable pointing to the target root directory
export AL_ROOT=$AL/root

# Variable pointing to the toolchain directory
export AL_TOOLS=$AL/tools

# Variable pointing to the tarballs directory
export AL_TARBALLS=$AL/tarballs

# Variable pointing to the sources directory
export AL_SOURCES=$AL/sources

# Choose the target triple. This will select the prebuilt cross compiler to use.
export AL_TGT=$(uname -m)-linux-musl

# Options to use for every invocation of make
export MAKEFLAGS="-j4"

###############################################################################
# Build Environment Settings
###############################################################################
# These settings should not have to change from the defaults. They are mainly
# here for informational purposes.
export PATH="$AL_TOOLS/bin:$PATH"
export CC="$AL_TGT-gcc"
export CXX="$AL_TGT-g++"
export AR="$AL_TGT-ar"
export AS="$AL_TGT-as"
export LD="$AL_TGT-ld"
export RANLIB="$AL_TGT-ranlib"
export READELF="$AL_TGT-readelf"
export STRIP="$AL_TGT-strip"
export LDFLAGS="--static"
