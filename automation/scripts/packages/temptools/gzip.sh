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

tar -xf gzip-*.tar.xz
cd gzip-*/

./configure --prefix=/usr --host=$LFS_TGT

make 

make DESTDIR=$LFS install

cd ..
rm -rf gzip-*/