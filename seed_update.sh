#!/bin/bash

set -e

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
        exit 12
    fi
}

update_seed()
{
    rm -rf $LFS_AUTOSCRIPTS/scripts
    mkdir $LFS_AUTOSCRIPTS/scripts
    cp -Rv ./automation/scripts/* $LFS_AUTOSCRIPTS/
    chmod a+wt ./automation/scripts
}

# Entry Point

echo "Automated LFS Seed-Update Script"
echo "LFS Version 11.2, Script Version 1.2"
echo "Copyright(C) ChlorineLabs, 2022, Internal Use Only"
echo

echo "Please ensure that the target partition (/mnt/lfs) is mounted."
echo "This script is meant to preserve build locks and is meant for developer-use only."
echo "This also means you might experience broken behaviour."

while true; do
    read -p "Are you sure you want to proceed (y/n) ? " yn
    case $yn in
        [Yy]* ) update_seed; break;;
        [Nn]* ) exit 12;;
        * ) echo "Please answer yes or no.";;
    esac
done