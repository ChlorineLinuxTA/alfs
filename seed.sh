#!/bin/bash

setvars()
{
    echo "Setting variables ..."
    export LFS=/mnt/lfs
    export LFS_AUTOSCRIPTS=$LFS/automation
    export LFS_LOCKS=$LFS_AUTOSCRIPTS/locks
    export LFS_DEBUG=$LFS_AUTOSCRIPTS/debug
}

check_root()
{
    if [ "$EUID" -ne 0 ]
    then 
        echo "Please execute this script as root. Now exiting."
        exit
    fi
}

seed_script()
{
    setvars
    check_root

    echo "Removing build traces ... "
    rm -rf $LFS/*

    echo "Seeding new build ... "
    mkdir $LFS_AUTOSCRIPTS
    mkdir $LFS_LOCKS
    mkdir $LFS_DEBUG

    cp ./build.sh $LFS/

    cp -R ./automation/* $LFS_AUTOSCRIPTS/

    echo "Sources cache detected. Seeding cache ... "
    if [ -d "sources_cache" ]; then
        mkdir $LFS/sources
        chmod a+wt $LFS/sources

        cp -R ./sources_cache/* $LFS/sources

        touch $LFS_LOCKS/checkpoint2.lock
    fi

    if grep "lfs" /etc/passwd >/dev/null 2>&1; then
        echo "User 'lfs' already present. Removing user..."
        sudo deluser lfs
    fi


    echo "New build seed ready. Please run 'build.sh' in $LFS"
}

# Entry Point

echo "Automated LFS Seeding Script"
echo "LFS Version 11.2, Script Version 1.2"
echo "Copyright(C) ChlorineLabs, 2022, Internal Use Only"
echo

echo "Please ensure that the target partition (/mnt/lfs) is mounted and empty."
echo "This script will wipe any files present on the target."
echo "Ensure you are running as root."
echo

while true; do
    read -p "Are you sure you want to procede (y/n) ? " yn
    case $yn in
        [Yy]* ) seed_script; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done