#!/bin/bash

set -e

setvars()
{
    echo "Setting variables ..."
    export LFS=/mnt/lfs
    export LFS_AUTOSCRIPTS=$LFS/automation
    export LFS_LOCKS=$LFS_AUTOSCRIPTS/locks
    export LFS_DEBUG=$LFS_AUTOSCRIPTS/debug
    
    export MAKEFLAGS='-j4'
}

setvars

tar -xf binutils-*.tar.xz
cd binutils-*/

mkdir build
cd build

../configure --prefix=$LFS/tools \
            --with-sysroot=$LFS \
            --target=$LFS_TGT   \
            --disable-nls       \
            --enable-gprofng=no \
            --disable-werror

make
make install

cd ../..
rm -rf binutils-*/