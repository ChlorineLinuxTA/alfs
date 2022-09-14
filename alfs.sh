#!/bin/bash

set -e

LFS_WGETLIST_LINK="https://www.linuxfromscratch.org/lfs/downloads/stable/wget-list"

disp_license()
{
    cat ./LICENSE
}

disp_help()
{
    echo "Work in Progress"
}

check_root()
{
    if [ "$EUID" -ne 0 ]
    then 
        echo "Command '$1' requires root priveleges. Please execute this command as root. Now exiting."
        exit 12
    fi
}

setvars()
{
    echo "Setting variables ..."
    export LFS=/mnt/lfs
    export LFS_AUTOSCRIPTS=$LFS/automation
    export LFS_LOCKS=$LFS_AUTOSCRIPTS/locks
    export LFS_DEBUG=$LFS_AUTOSCRIPTS/debug
}

seed()
{
    check_root "seed"

    setvars
    echo "Please ensure that the target partition (/mnt/lfs) is mounted and empty."
    echo "This script will wipe any files present on the target."
    while true; do
        read -p "Are you sure you want to procede (y/n) ? " yn
        case $yn in
            [Yy]* ) seed_script; break;;
            [Nn]* ) exit 12;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    echo
    echo "Removing build traces ... "
    rm -rf $LFS/*

    echo "Seeding new build ... "
    mkdir $LFS_AUTOSCRIPTS
    mkdir $LFS_LOCKS
    mkdir $LFS_DEBUG

    cp ./alfs.sh $LFS/
    chmod +x $LFS/alfs.sh

    cp -R ./automation/* $LFS_AUTOSCRIPTS/

    chown lfs $LFS_AUTOSCRIPTS
    chown lfs $LFS_AUTOSCRIPTS/*
    chown lfs $LFS_LOCKS
    chown lfs $LFS_DEBUG

    if [ -d "./sources_cache" ]; then
        echo "Sources cache detected. Seeding cache ... "
        mkdir $LFS/sources
        chmod a+wt $LFS/sources

        cp -R ./sources_cache/* $LFS/sources

        touch $LFS_LOCKS/checkpoint2.lock
    fi

    if grep "lfs" /etc/passwd >/dev/null 2>&1; then
        echo "User 'lfs' already present. Removing user..."
        sudo deluser lfs
    fi

    echo "New build seed ready. Please run './alfs.sh build' in $LFS"
}

update_seed()
{
    check_root "update-seed"

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

    rm -rf $LFS_AUTOSCRIPTS/scripts
    mkdir $LFS_AUTOSCRIPTS/scripts
    cp -Rv ./automation/scripts/* $LFS_AUTOSCRIPTS/
    chmod a+wt ./automation/scripts

    chown lfs $LFS_AUTOSCRIPTS
    chown lfs $LFS_AUTOSCRIPTS/*
    chown lfs $LFS_LOCKS
    chown lfs $LFS_LOCKS/*
    chown lfs $LFS_DEBUG
    chown lfs $LFS_DEBUG/*

    echo "Seed updated."
}

check_host()
{

# Write the version check script

    cat > version-check.sh << "EOF"
    #!/bin/bash
    # Simple script to list version numbers of critical development tools
    export LC_ALL=C
    bash --version | head -n1 | cut -d" " -f2-4
    MYSH=$(readlink -f /bin/sh)
    echo "/bin/sh -> $MYSH"
    echo $MYSH | grep -q bash || echo "ERROR: /bin/sh does not point to bash"
    unset MYSH

    echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
    bison --version | head -n1

    if [ -h /usr/bin/yacc ]; then
    echo "/usr/bin/yacc -> `readlink -f /usr/bin/yacc`";
    elif [ -x /usr/bin/yacc ]; then
    echo yacc is `/usr/bin/yacc --version | head -n1`
    else
    echo "yacc not found"
    fi

    echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2
    diff --version | head -n1
    find --version | head -n1
    gawk --version | head -n1

    if [ -h /usr/bin/awk ]; then
    echo "/usr/bin/awk -> `readlink -f /usr/bin/awk`";
    elif [ -x /usr/bin/awk ]; then
    echo awk is `/usr/bin/awk --version | head -n1`
    else
    echo "awk not found"
    fi

    gcc --version | head -n1
    g++ --version | head -n1
    grep --version | head -n1
    gzip --version | head -n1
    cat /proc/version
    m4 --version | head -n1
    make --version | head -n1
    patch --version | head -n1
    echo Perl `perl -V:version`
    python3 --version
    sed --version | head -n1
    tar --version | head -n1
    makeinfo --version | head -n1  # texinfo version
    xz --version | head -n1

    echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
    if [ -x dummy ]
    then echo "g++ compilation OK";
    else echo "g++ compilation failed"; fi
    rm -f dummy.c dummy
EOF

    touch $LFS_DEBUG/host_system_libs.log
    bash version-check.sh 2>&1 | tee $LFS_DEBUG/host_system_libs.log

    while true; do
        read -p "Please confirm that the above output is compliant (y/n) ? " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit 12;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    echo "Host System Requirements Check Passed."

    rm version-check.sh
    touch $LFS_LOCKS/checkpoint1.lock
}

fetch_sources()
{
    mkdir -v $LFS/sources
    chmod -v a+wt $LFS/sources

    wget $LFS_WGETLIST_LINK
    wget --input-file=wget-list --continue --directory-prefix=$LFS/sources

    touch $LFS_LOCKS/checkpoint2.lock
}

prepare_lfs_fs()
{
    touch $LFS_DEBUG/prepare_lfs_fs.log

    mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin} 2>&1 >> $LFS_DEBUG/prepare_lfs_fs.log

    for i in bin lib sbin; do
        ln -sv usr/$i $LFS/$i 2>&1 >> $LFS_DEBUG/prepare_lfs_fs.log
    done

    case $(uname -m) in
        x86_64) mkdir -pv $LFS/lib64 2>&1 >> $LFS_DEBUG/prepare_lfs_fs.log ;;
    esac

    mkdir -pv $LFS/tools

    echo "Creating user 'lfs' ..."

    groupadd lfs 2>&1 >> $LFS_DEBUG/prepare_lfs_fs.log
    useradd -s /bin/bash -g lfs -m -k /dev/null lfs 2>&1 >> $LFS_DEBUG/prepare_lfs_fs.log

    echo "Enter a new password for user 'lfs' ..."
    passwd lfs

    chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools} 2>&1 >> $LFS_DEBUG/prepare_lfs_fs.log
    case $(uname -m) in
        x86_64) chown -v lfs $LFS/lib64 2>&1 >> $LFS_DEBUG/prepare_lfs_fs.log ;;
    esac

    chown -Rv lfs $LFS_AUTOSCRIPTS 2>&1 >> $LFS_DEBUG/prepare_lfs_fs.log
    chown -v lfs ./build.sh 2>&1 >> $LFS_DEBUG/prepare_lfs_fs.log

    [ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE 2>&1 >> $LFS_DEBUG/prepare_lfs_fs.log

    touch $LFS_LOCKS/checkpoint3.lock
}

routine1()
{
    if [ -e $LFS_LOCKS/checkpoint1.lock ]
    then
        echo "Skipping host system check ... "
        echo
    else
        check_root "build"
        echo "Host system check ... "
        echo
        check_host
    fi

    if [ -e $LFS_LOCKS/checkpoint2.lock ]
    then
        echo "Skipping fetching sources ... "
        echo
    else
        check_root "build"
        echo "Fetching sources ... "
        echo
        fetch_sources 2>&1 > $LFS_DEBUG/fetching_sources.log
    fi

    if [ -e $LFS_LOCKS/checkpoint3.lock ]
    then
        echo "Skipping LFS filesystem preparation ... "
        echo
    else
        check_root "build"
        echo "Preparing LFS filesystem ... "
        echo
        prepare_lfs_fs 2>&1 > $LFS_DEBUG/prepare_lfs_fs.log
    fi
    
    touch $LFS_LOCKS/routine1.lock
}

build_tt()
{
    bash $LFS_AUTOSCRIPTS/scripts/temp_toolchain.sh
}

routine2()
{
    if ! [ -e $LFS_LOCKS/userprofile.lock ]
    then
        su lfs "$LFS_AUTOSCRIPTS/scripts/setuser.sh"
    fi
    
    if [ -e $LFS_LOCKS/redirect_r2.lock ]
    then
        echo "-------------------------------------------------------------------"
        echo "Please ensure you are NOT running as root."
        echo "-------------------------------------------------------------------"
        echo
        while true; do
            read -p "Proceed (y/n) ? " yn
            case $yn in
                [Yy]* ) build_tt; break;;
                [Nn]* ) exit 12;;
                * ) echo "Please answer yes or no.";;
            esac
        done
        rm $LFS_LOCKS/redirect_r2.lock
    fi

    if ! [ -e $LFS_LOCKS/temp_toolchain.lock ]
    then
        touch $LFS_LOCKS/redirect_r2.lock
        echo "-------------------------------------------------------------------------------------------------------------------"
        echo "[KNOWN BUG]"
        echo "Due to a few packages (like GCC) failing to build with 'lfs' user in a script with root privleges, "
        echo "we recommend a better method. This build script will now exit. Please enter the following commands to follow: "
        echo "su - lfs"
        echo "cd $LFS"
        echo "bash build.sh"
        echo ", to re-enter this script again."
        echo "-------------------------------------------------------------------------------------------------------------------"
        exit 0
    fi

    touch $LFS_LOCKS/routine2.lock
}

build_all() 
{
    setvars

    if ! [ -e $LFS_LOCKS/routine1.lock ]
    then
        routine1
    fi
    
    if ! [ -e $LFS_LOCKS/routine2.lock ]
    then
        routine2
    fi

    echo "Done. LFS is built!"
}

# Entry Point

echo "Automated Linux from Scratch Build Script"
echo "Build ID: ALFS 1.3 for LFS 11.2"
echo "Copyright(C) 2022, ChlorinePentoxide"
echo "Licensed under Apache 2.0"
echo 
echo "This software comes with ABSOLUTELY NO WARRANTY."
echo "Type './alfs license' to display the full license."
echo 

if [ "$1" = "" ]; then
    echo Empty
elif [ "$1" = "license" ]; then
    disp_license
elif [ "$1" = "seed" ]; then 
    seed
elif [ "$1" = "update-seed" ]; then
    update_seed
elif [ "$1" = "build" ]; then
    build_all
fi
