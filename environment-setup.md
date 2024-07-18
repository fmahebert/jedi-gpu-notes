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
1. (optional) use `update-alternatives` to manage GCC installation:
    ```
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 110 --slave /usr/bin/g++ g++ /usr/bin/g++-11 --slave /usr/bin/gcov gcov /usr/bin/gcov-11 --slave /usr/bin/gfortran gfortran /usr/bin/gfortran-11
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

1. (**Warning: this is a work-in-progress**) Build GCC Suite with Offload support using the following script. Ensure that you update the build parameters appropriately, under the constraint that `WORKING_DIR` and `INSTALL_DIR` should not be equal or nested inside the other.
    ```
    #!/bin/sh
    # Build GCC with support for OpenMP offloading to NVIDIA GPUs.
    
    # --- Build parameters ---
    N_PROCS=12
    WORKING_DIR=/home/azureuser/tools/build-gcc-12.4
    INSTALL_DIR=/usr/local/gcc-12.4
    CUDA=/usr/local/cuda-12.2
    
    # --- Create the working directory ---
    mkdir -p $WORKING_DIR
    
    # --- Build assembler and linking tools ---
    git clone https://github.com/MentorEmbedded/nvptx-tools $WORKING_DIR/nvptx-tools
    mkdir $WORKING_DIR/build-nvptx-tools
    cd $WORKING_DIR/build-nvptx-tools
    ../nvptx-tools/configure \
        --with-cuda-driver-include=$CUDA/include \
        --with-cuda-driver-lib=$CUDA/lib64 \
        --prefix=$INSTALL_DIR
    make -j$N_PROCS || exit 1
    cd $WORKING_DIR
    
    # --- set up the GCC source tree ---
    git clone -b newlib-4.3.0 git://sourceware.org/git/newlib-cygwin.git $WORKING_DIR/nvptx-newlib
    git clone -b releases/gcc-12 git://gcc.gnu.org/git/gcc.git $WORKING_DIR/gcc
    cd $WORKING_DIR/gcc
    contrib/download_prerequisites
    ln -s ../nvptx-newlib/newlib newlib
    cd $WORKING_DIR
    target=$(gcc/config.guess)
    
    # --- Build nvptx GCC ---
    mkdir $WORKING_DIR/build-nvptx-gcc
    cd $WORKING_DIR/build-nvptx-gcc
    ../gcc/configure \
        --target=nvptx-none --with-build-time-tools=$INSTALL_DIR/nvptx-none/bin \
        --enable-as-accelerator-for=$target \
        --disable-sjlj-exceptions \
        --enable-newlib-io-long-long \
        --enable-languages="c,c++,fortran,lto" \
        --prefix=$INSTALL_DIR \
        --bindir=$INSTALL_DIR/libexec # These executables are internal tools and so should be inside libexec
    make -j$N_PROCS || exit 1
    cd $WORKING_DIR
    
    # --- Build host GCC ---
    mkdir $WORKING_DIR/build-host-gcc
    cd $WORKING_DIR/build-host-gcc
    ../gcc/configure \
        --enable-offload-targets=nvptx-none \
        --with-cuda-driver-include=$CUDA/include \
        --with-cuda-driver-lib=$CUDA/lib64 \
        --disable-bootstrap \
        --disable-multilib \
        --enable-languages="c,c++,fortran,lto" \
        --prefix=$INSTALL_DIR
    make -j$N_PROCS || exit 1
    cd $WORKING_DIR
    ```
1. Install the built GCC suite using the following script.
    ```
    #!/bin/sh
    # Install GCC with support for OpenMP offloading to NVIDIA GPUs.
    
    # --- Build parameters ---
    N_PROCS=12
    WORKING_DIR=/home/azureuser/tools/build-gcc-12.4

    # --- Install ---
    cd $WORKING_DIR/build-nvptx-tools
    make -j$N_PROCS install || exit 1
    
    cd $WORKING_DIR/build-nvptx-gcc
    make -j$N_PROCS install || exit 1
    
    cd $WORKING_DIR/build-host-gcc
    make -j$N_PROCS install || exit 1
    ```
1. Make sure that the newly installed compilers are on the path. One could use `update-alternatives` to the manage GCC installation:
    ```
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/local/gcc-12.4/bin/gcc 120 --slave /usr/bin/g++ g++ /usr/local/gcc-12.4/bin/g++ --slave /usr/bin/gcov gcov /usr/local/gcc-12.4/bin/gcov --slave /usr/bin/gfortran gfortran /usr/local/gcc-12.4/bin/gfortran
    ```

## 5. Set-Up Spack-Stack

Set-up Spack-Stack as per its [documentation](https://spack-stack.readthedocs.io/en/1.7.0/NewSiteConfigs.html#id3), with the following modifications:

- **(optional) modified step 1**:
    1. Clone spack-stack:
    ```git clone --recurse-submodules https://github.com/jcsda/spack-stack.git && cd spack-stack```
    1. create a new spack-stack meta package that is a modified version of `jedi-base-env` which removes the `ecmwf-atlas` dependency, and adds dependencies on `ectrans` and `qhull`. To do this one can place the following `package.py` file at `./spack-stack/spack-ext/repos/spack-stack/packages/custom-jedi-base-env/package.py`.
        ```
        # package.py
        
        # Copyright 2013-2022 Lawrence Livermore National Security, LLC and other
        # Spack Project Developers. See the top-level COPYRIGHT file for details.
        #
        # SPDX-License-Identifier: (Apache-2.0 OR MIT)
        
        from spack.package import *
        
        class CustomJediBaseEnv(BundlePackage):
            """Custom basic development environment for JEDI applications (removes ecmwf-atlas dependency and adds ectrans and qhull dependencies relative to jedi-base-env)."""
        
            homepage = "https://github.com/jcsda/spack-stack"
            git = "https://github.com/jcsda/spack-stack.git"
        
            maintainers("none")
        
            version("1.0.0")
        
            # Variants defining packages that we cannot distribute publicly
            # Need to find a free fftw provider for fftw-api ...
            variant("fftw", default=True, description="Build fftw")
            variant("hdf4", default=True, description="Build hdf4 library and python hdf module")
        
            depends_on("base-env", type="run")
            depends_on("bison", type="run")
            depends_on("blas", type="run")
            depends_on("boost", type="run")
            depends_on("bufr", type="run")
            # Force users to load manually
            # depends_on("crtm@v2.4.1-jedi", type="run")
            depends_on("ecbuild", type="run")
            depends_on("eccodes", type="run")
            depends_on("eckit", type="run")
            # depends_on("ecmwf-atlas", type="run") # removed dependency
            depends_on("ectrans", type="run") # added dependency
            depends_on("qhull", type="run") # added dependency
            depends_on("eigen", type="run")
            depends_on("fckit", type="run")
            depends_on("fftw-api", when="+fftw", type="run")
            depends_on("flex", type="run")
            depends_on("git-lfs", type="run")
            depends_on("gsibec", type="run")
            depends_on("gsl-lite", type="run")
            depends_on("hdf", when="+hdf4", type="run")
            depends_on("jedi-cmake", type="run")
            depends_on("netcdf-cxx4", type="run")
            depends_on("ncview", type="run")
            depends_on("nlohmann-json", type="run")
            depends_on("nlohmann-json-schema-validator", type="run")
            depends_on("odc", type="run")
            depends_on("sp", type="run", when="^ip@:4")
            depends_on("udunits", type="run")
        
            # Python packages
            depends_on("py-eccodes", type="run")
            depends_on("py-f90nml", type="run")
            depends_on("py-h5py", type="run")
            depends_on("py-netcdf4", type="run")
            depends_on("py-pandas", type="run")
            depends_on("py-pycodestyle", type="run")
            depends_on("py-pybind11", type="run")
            depends_on("py-pyhdf", when="+hdf4", type="run")
            depends_on("py-python-dateutil", type="run")
            depends_on("py-pyyaml", type="run")
            depends_on("py-scipy", type="run")
            depends_on("py-xarray", type="run")
        
            conflicts(
                "%gcc platform=darwin",
                msg="custom-jedi-base-env does not build with gcc on macOS, use apple-clang",
            )
        
            # There is no need for install() since there is no code.
        ```
    1. Enter the spack-stack directory and setup environment:
    ```cd spack-stack && source setup.py```
- **modified step 10**:
    1. modify the `definitions` section of `spack.yaml`. If you added the `custom-jedi-base-env` modify the defintion of the spack.yaml file to have the following form
        ```
          definitions:
          - compilers: ['%gcc']
          - packages:
            - custom-jedi-base-env
        ```
        otherwise modify it to have the form,
        ```
          definitions:
          - compilers: ['%gcc']
          - packages:
            - jedi-base-env
        ```
    1. modify the `specs` section of `spack.yaml` by removing the following:
        ```
            exclude:
                # py-torch in ai-env doesn't build with Intel
            - ai-env%intel
        ```

