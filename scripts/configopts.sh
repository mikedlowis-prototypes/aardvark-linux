#!/bin/sh
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_ZLIB=OFF \
    -DLLVM_TARGETS_TO_BUILD=X86 \
    -DLLVM_ENABLE_THREADS=OFF \
    -DLLVM_ENABLE_PIC=ON \
    -DLLVM_ENABLE_ZLIB=OFF \
    -G"Unix Makefiles" \
    ../
