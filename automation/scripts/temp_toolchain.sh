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

compile()
{
    echo "Compiling $1 ($2)"
    if ! [ -e $LFS_LOCKS/$1.plock ]; then
        bash $TTSCRIPTS/$1.sh > $LFS_DEBUG/temp_$1.log 2>&1
        touch $LFS_LOCKS/$1.plock
    else
        echo "Package lock exists. Skipping ..."
        echo
    fi
}

setvars

echo
echo "Sanity Check : LFS: $LFS"

while true; do
    read -p "Proceed (y/n) ? " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit 12;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo

cd $LFS/sources

echo "Removing possible build traces ..."
rm -R */

TTSCRIPTS="$LFS_AUTOSCRIPTS/scripts/packages/temptools"

echo "Compiling Binutils Pass 1 (1 SBU) ... "
if ! [ -e $LFS_LOCKS/binutils_p1.plock ]; then
    echo "Calculating 1 SBU ... "
    time { bash $TTSCRIPTS/binutils_p1.sh > $LFS_DEBUG/temp_binutils_p1.log 2>&1; }
    echo "Time tracking complete."
    touch $LFS_LOCKS/binutils_p1.plock
else
    echo "Package lock exists. Skipping ..."
    echo
fi
echo

compile gcc_p1 "12 SBU"
compile linux_api "0.1 SBU"
compile glibc "4.4 SBU"

echo
echo "---------------------------------------------"

echo "Performing imperative sanity check ... "
echo "Output: "
bash $TTSCRIPTS/glibc_test.sh 2>&1 | tee $LFS_DEBUG/glibc_sanity_check.log

while true; do
    read -p "Proceed (y/n) ? " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit 12;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "---------------------------------------------"
echo

compile libstdcpp "0.4 SBU"
compile m4 "0.2 SBU"
compile ncurses "0.7 SBU"
compile bash "0.5 SBU"
compile coreutils "0.6 SBU"
compile diffutils "0.2 SBU"
compile file "0.2 SBU"
compile findutils "0.2 SBU"
compile gawk "0.2 SBU"
compile grep "0.2 SBU"
compile gzip "0.1 SBU"
compile make "0.1 SBU"
compile patch "0.1 SBU"
compile sed "0.1 SBU"
compile tar "0.2 SBU"
compile xz "0.1 SBU"
compile binutils_p2 "1.4 SBU"
compile gcc_p2 "15 SBU"

touch $LFS_LOCKS/temp_toolchain.lock