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

tar -xf binutils-2.39.tar.xz
cd binutils-2.39/

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
rm -rf binutils-2.39

echo
echo Done.