#!/bin/bash

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

echo
echo "Sanity Check : LFS: $LFS"

while true; do
    read -p "Proceed (y/n) ? " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo

cd $LFS/sources

echo "Compiling Binutils (1 SBU) ... "
if ! [ -e $LFS_LOCKS/binutils_p1.plock ]; then
    echo "Calculating 1 SBU ... "
    time { su lfs $LFS_AUTOSCRIPTS/scripts/packages/binutils_p1.sh > $LFS_DEBUG/binutils_p1.log 2>&1; }
    echo "Time tracking complete."
    touch $LFS_LOCKS/binutils_p1.plock
else
    echo "Package lock exists. Skipping ..."
fi
echo

