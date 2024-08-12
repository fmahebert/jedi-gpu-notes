# Notes for JEDI Branch *feature/gpu-offload-example*

## 1. Set-Up Environment

Follow the instructions provided in `environment-setup-ubuntu2204.md` to set-up a Ubuntu 22.04 JEDI developement environment.

## 2. Build JEDI

Clone and build the jedi-bundle on branch `feature/gpu-offload-example`; this adds in-bundle atlas, trims the bundle to the repos needed to demonstrate GPU offload in saber, and sets up the GPU offload build environment.

```
mkdir jedi && cd jedi
git clone -b feature/gpu-offload-example https://github.com/JCSDA-internal/jedi-bundle
mkdir build && cd build
ecbuild ../jedi-bundle
make -j6
ctest
```

**Note**: the atlas ctest `atlas_fctest_field_host` is expected to fail because of a bug in the test itself (atlas issue #216)

In this branch, the oops helper `util::multiplyFieldSet` is offloaded to GPU. This code is exercised, for example, in the ctest `saber_test_dirac_stddev_1_1-1`. One way to verify the offload is occurring is to run the ctest through Nvidia's kernel profiler (Nsight-Compute), as below.

```
cd /path/to/jedi/build/saber/test
sudo OMP_NUM_THREADS=1 /usr/local/cuda/bin/ncu /path/to/jedi/build/bin/saber_quench_error_covariance_toolbox.x testinput/dirac_stddev_1.yaml
```

When the OpenMP kernel is offloaded, the profiler will output diagnostics during and after the run that should look more-or-less like this,

```
  _ZN4util16multiplyFieldSetERN5atlas8FieldSetERKd$_omp_fn$0 (240, 1, 1)x(32, 8, 1), Context 1, Stream 7, Device 0, CC 7.0
    Section: GPU Speed Of Light Throughput
    ----------------------- ------------- ------------
    Metric Name               Metric Unit Metric Value
    ----------------------- ------------- ------------
    DRAM Frequency          cycle/usecond       855.35
    SM Frequency            cycle/nsecond         1.22
    Elapsed Cycles                  cycle      1000999
    Memory Throughput                   %         3.39
    DRAM Throughput                     %         2.28
    Duration                      usecond       820.10
    L1/TEX Cache Throughput             %         4.19
    L2 Cache Throughput                 %         2.63
    SM Active Cycles                cycle    810280.62
    Compute (SM) Throughput             %         8.21
    ----------------------- ------------- ------------
<snip>
```
