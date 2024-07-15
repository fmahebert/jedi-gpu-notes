# Setting up a Ubuntu 22.04 development environment

## 1. Nvidia Drivers Installtion
I followed these instructions: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/n-series-driver-setup#ubuntu. And these instructions have some useful additional details https://ubuntu.com/server/docs/nvidia-drivers-installation. But I have also documented the process below:

### Check Current System
- Check for the presence of an Nvidia GPU (should display name of GPU): `lspci | grep -i NVIDIA`
- Check the version of the current installed Nvidia driver (if there is one, it should display the version): `cat /proc/driver/nvidia/version`

### Installation
1. Install Ubuntu drivers utility: `sudo apt update && sudo apt install -y ubuntu-drivers-common`
1. Install latest Nvidia drivers: `sudo ubuntu-drivers install`
    - Or you can install a specific version using: `sudo ubuntu-drivers install nvidia:535`
1. **Reboot** machine.

### Verification
- Check that the driver is working (should report info about GPU): `nvidia-smi`

## 2. System Packages Installation

### Installation

1. The following script installs the required system packages: 
```
sudo su
apt-get update
apt-get upgrade

# Compilers
apt install -y gcc-11 g++-11 gfortran-11

# Debuggers
apt install -y gdb-11

# GCC Build Dependency
apt install -y flex

# Environment module support
# Note: lmod is available in 22.04, but is out of date: https://github.com/JCSDA/spack-stack/issues/593
apt install -y environment-modules

# Misc
apt install -y build-essential
apt install -y libkrb5-dev
apt install -y m4
apt install -y git
apt install -y git-lfs
apt install -y bzip2
apt install -y unzip
apt install -y automake
apt install -y autopoint
apt install -y gettext
apt install -y xterm
apt install -y texlive
apt install -y libcurl4-openssl-dev
apt install -y libssl-dev
apt install -y meson

# Note - only needed for running JCSDA's JEDI-Skylab system (using R2D2 localhost)
apt install -y mysql-server
apt install -y libmysqlclient-dev

# Python
apt install -y python3-dev python3-pip

# Exit root session
exit
```

## 3. CUDA Toolkit Installation

Assuming that you have Nvidia drivers install

1. Add Nvidia package repository:
    ```
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
    sudo apt install -y ./cuda-keyring_1.1-1_all.deb
    sudo apt update
    ```
1. Install CUDA Toolkit: `sudo apt -y install cuda-toolkit-12-2`
1. Set-up paths (you may want to add these to `.profile` or `.bashrc` etc):
    ```
    export PATH=/usr/local/cuda/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
    ```

## 4. Build GCC Suite with Offload Support

...

## 5. Set-Up Spack-Stack

...

