#!/bin/bash

### Description:
# This script is for installing `nvptx-tools` version 0.20240423-1 from source on Ubuntu 22.04 which is newer than the system package.

UBUNTU_VERSION=jammy
TMP_DIR=$PWD/tmp

### Install dependencies (uncomment if you need the dependencies)
# sudo apt update
# sudo apt install -y build-essential software-properties-common fakeroot debhelper autotools-dev help2man
# wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
# sudo apt-add-repository "deb http://apt.llvm.org//$UBUNTU_VERSION/ llvm-toolchain-$UBUNTU_VERSION-18 main"
# sudo apt update
# sudo apt install -y llvm-18-tools

### Create temporary build directory
mkdir -p $TMP_DIR

### Download and prepare source
cd $TMP_DIR
wget http://archive.ubuntu.com/ubuntu/pool/universe/n/nvptx-tools/nvptx-tools_0.20240423.orig.tar.xz
tar -xf nvptx-tools_0.20240423.orig.tar.xz
wget http://archive.ubuntu.com/ubuntu/pool/universe/n/nvptx-tools/nvptx-tools_0.20240423-1.debian.tar.xz
tar -xf nvptx-tools_0.20240423-1.debian.tar.xz
mv debian ./nvptx-tools-0.20240423/

### Build package
cd $TMP_DIR/nvptx-tools-0.20240423/
dpkg-buildpackage -rfakeroot -b -uc

### Install package
cd $TMP_DIR
sudo dpkg -i ./nvptx-tools_0.20240423-1_amd64.deb

### Destroy temporary build directory
rm -rf $TMP_DIR
