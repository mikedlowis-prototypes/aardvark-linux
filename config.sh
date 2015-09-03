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
export AL_TOOLS=$AL_ROOT/tools

# Variable pointing to the tarballs directory
export AL_TARBALLS=$AL/tarballs

# Variable pointing to the sources directory
export AL_SOURCES=$AL/sources

###############################################################################
# Build Environment Settings
###############################################################################

# Setup the path to use the cross-tools when they're available
export PATH=$AL_ROOT/tools/$(uname -m)-linux-musl/bin:$PATH

