#!/bin/bash

### Description:
# Install the Nvidia drivers

lspci | grep -i NVIDIA > /dev/null
if [ $? -ne 0 ]; then
    echo "No Nvidia GPU found. Aborting Nvidia driver installation."
    exit 1
fi
echo "Installing Nvidia driver."

sudo apt update
sudo apt install -y ubuntu-drivers-common
sudo ubuntu-drivers install nvidia:535
