# Build from source code

Clone the slice-docker-env repository and navigate to the osdi-artifact branch:

```
git clone https://github.com/MSRSSP/slice-docker-env.git --branch osdi-artifact
cd slice-docker-env
make setup
```

## (Option1) Quick build

Use quick build so that you do not need to compile different repositories step by step [Option 2](#option-2-build).

Run the following command to build all at once.
```
make all
```

After compilation completes, it would automatically launch the slicevisor.


### Test slice functions

See :point_right: [Step2](quick-start.md#)

## (Option 2) Build
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
wget https://github.com/MSRSSP/slice-docker-env/releases/download/prebuilt/riscv-tools.tar.gz
tar xvzf riscv-tools.tar.gz
```

#### Option2: Install from source code

We **do not** recommend installing a new RISC-V toolchain from source code as it
can take several hours to complete. However, if you wish to proceed with this
option, please refer to [RISCV-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain):

To use our tutorial, please put your riscv toolchain in
`install/rv64` path


### Build Guest linux

#### Option1: Build from Linux source code

Run the following commands to download and build Linux:

```
make linux-riscv-build
make linux-riscv-build2
```

We have two guest Images for two guest slices. Here we lazily use one build for two.

#### Option2: Use our pre-built images

```
wget https://github.com/MSRSSP/slice-docker-env/releases/download/prebuilt/linux-riscv-build.tar.gz
tar xvzf linux-riscv-build.tar.gz
cp -r linux-riscv-build linux-riscv-build2
```

### Build our modified qemu

#### Option1: Install from our modified qemu source code

Run the following command to create a Docker image with build dependencies:

```
make qemu
```

#### Option2: Use our pre-built qemu

```
curl -L -O https://github.com/MSRSSP/slice-docker-env/releases/download/prebuilt/qemu-build.tar.gz
tar xvzf qemu-build.tar.gz
```

## Build Slice firmware and create payload

Run the following command to build Slice firmware and create a payload:

```
make payload-build
```

Note: If the build fails, retry the command.

## Run
We will use a RISC-V board emulated by QEMU with 4 normal processors and 1 monitor processor. 

### Step1: Boot slice-0

Run the following command to boot Slice-0 and two pre-configured guest slices.

```
make run
```


