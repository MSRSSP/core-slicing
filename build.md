# Build from source code

Clone the slice-docker-env repository and navigate to the osdi-artifact branch:

```
git clone https://github.com/MSRSSP/slice-docker-env.git --branch osdi-artifact
cd slice-docker-env
make setup
```

## Quick build

Use quick build so that you do not need to compile different repositories step by step [Step-by-step build](#build).

* Option1: [~5 min] Run the following command to build slicevisor and sliceloader with prebuilt qemu + guest linux.
  ```
  make quick-build
  ```

* Option2: [~15min] Run the following command to build qemu, linux, slicevisor, and sliceloder
  ```
  make clean
  make all
  ```

After compilation completes, start the slicevisor with the default guest slice config
```
make run
```

### Test slice functions

See :point_right: [Step2](quick-start.md#)

## Build

> NOTE: this section explains the build process in `make quick-build` and `make all`. You do not need to read them.

Build qemu, linux, and sliceloader separately

### Create a Docker image with build dependencies
Run the following command to create a Docker image with build dependencies:

```
make slice-ubuntu
```

Our tutorials include pre-built binaries that are designed to work seamlessly with the Docker image.

### Build RISC-V toolchain

#### Option1: Use our pre-built toolchain

Download and extract our pre-built RISC-V toolchain using the following command:

```
make riscv-install
```

#### Option2: Install from source code

> NOTE: this step takes over hours. It does not worth to compile it.

We **do not** recommend installing a new RISC-V toolchain from source code as it
can take several hours to complete. However, if you wish to proceed with this
option, please refer to [RISCV-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain):

To use our tutorial, please put your riscv toolchain in
`install/rv64` path


### Build Guest Linux

#### Option1: Use our pre-built images

```
make guest-linux-prebuilt
```


#### Option2: Build from Linux source code

Run the following commands to download and build Linux:

```
make linux-5.15-rc4
make linux-riscv-build
make linux-riscv-build2
```

We have two guest Images for two guest slices. Here we lazily use one build for two. Feel free to build two different images if you want to run two different guest kernels

### Build our modified qemu

#### Option2: Use our pre-built qemu

```
make qemu-prebuilt
```

#### Option1: Install from our modified qemu source code

```
make qemu
```

## Build Slice firmware and create payload

Run the following command to build Slice firmware and create a payload:

```
make payload-build
```

> NOTE: [slice-hss/bypass-uboot/conf/slice/config.yaml](slice-hss/bypass-uboot/conf/slice/config.yaml) defines the default guest slice configuration. Update it properly if you want to use different config when at the begining.

## Run
We will use a RISC-V board emulated by QEMU with 4 normal processors and 1 monitor processor. 

### Step1: Boot slice-0

Run the following command to boot Slice-0 and two pre-configured guest slices.

```
make run
```


