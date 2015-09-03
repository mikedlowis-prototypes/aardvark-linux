###############################################################################
# Musl-Cross Compiler Build Settings
###############################################################################

# Tell make how many threads you want it to use
MAKEFLAGS=-j8

# Tell the build scripts where the cross compiler should go
CC_BASE_PREFIX="$PWD/../../root/tools/"

# If you use arm, you may need more fine-tuning:
# arm hardfloat v7
#TRIPLE=arm-linux-musleabihf
#GCC_BOOTSTRAP_CONFFLAGS="--with-arch=armv7-a --with-float=hard --with-fpu=vfpv3-d16"
#GCC_CONFFLAGS="--with-arch=armv7-a --with-float=hard --with-fpu=vfpv3-d16"

# arm softfp
#TRIPLE=arm-linux-musleabi
#GCC_BOOTSTRAP_CONFFLAGS="--with-arch=armv7-a --with-float=softfp"
#GCC_CONFFLAGS="--with-arch=armv7-a --with-float=softfp"

# Enable this to build the bootstrap gcc (thrown away) without optimization, to reduce build time
GCC_STAGE1_NOOPT=1

# Build gmp, mpfr, and mpc along with GCC rather than using the system libs
GCC_BUILTIN_PREREQS=yes

