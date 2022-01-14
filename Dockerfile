FROM ubuntu:20.04 AS env
RUN DEBIAN_FRONTEND=noninteractive apt update 
RUN apt install -y autoconf automake autotools-dev curl python3 
RUN DEBIAN_FRONTEND=noninteractive apt install -y libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex
RUN DEBIAN_FRONTEND=noninteractive apt install -y gperf libtool patchutils bc zlib1g-dev libexpat-dev
RUN DEBIAN_FRONTEND=noninteractive apt install -y libglib2.0-dev libfdt-dev libpixman-1-dev
RUN apt clean
RUN apt update && apt install -y git ninja-build
FROM env AS toolchain
RUN apt update && apt install -y git && apt clean
RUN git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
RUN apt install -y texinfo
FROM toolchain AS toolchain-build
WORKDIR /riscv-gnu-toolchain
RUN ./configure --prefix=/opt/riscv && make linux -j `nproc`

FROM env AS qemu
COPY .git /slice/.git
COPY qemu /slice/qemu
#RUN git clone --depth 1 https:github.com/MSRSSP/qemu.git
WORKDIR /slice/qemu
#RUN git pull && git checkout 18044a19108ce6e1714d5b22364c193d0979b079
#FROM qemu-env AS qemu
RUN ./configure --target-list=riscv64-softmmu && make -j `nproc`

FROM env as slice-env
COPY --from=toolchain-build /opt/riscv /opt/riscv
COPY --from=qemu /slice/qemu/build/qemu-system-riscv64 /slice/qemu/build/
RUN cp /opt/riscv/sysroot/usr/include/gnu/stubs-lp64d.h  /opt/riscv/sysroot/usr/include/gnu/stubs-lp64.h
RUN ln -s /opt/riscv/bin/* /usr/local/bin/
RUN apt install -y git libyaml-dev libelf-dev device-tree-compiler gdisk parted

FROM slice-env as linux
##### Download a tested linux kernel #######
WORKDIR /slice
RUN git clone https://github.com/torvalds/linux
COPY 0001-Add-microchip-specific-clock-and-devices.patch /slice/
WORKDIR /slice/linux
RUN git checkout v5.15-rc4
RUN git config --global user.email "slice-user@unknown.com"
RUN git config --global user.name "slice-user"
RUN git am ../0001-Add-microchip-specific-clock-and-devices.patch
COPY kernelconfig .config
#WORKDIR /slice/slice-hss/thirdparty
#FROM linux as buildroot
#RUN git clone https://github.com/buildroot/buildroot.git
#RUN mkdir buildroot/build
#RUN cp buildroot.config buildroot/build/.config
#WORKDIR /slice/slice-hss/thirdparty/buildroot
#RUN git checkout 2021.11-rc2
#RUN apt install -y wget cpio unzip rsync
#COPY busybox-slice.config package/busybox/busybox-slice.config
#RUN ln -s /opt/riscv/* /slice/slice-hss/thirdparty/buildroot/build/host/riscv64-buildroot-linux-gnu/
#RUN make CROSS_COMPILE=riscv64-unknown-linux-gnu- O=build -j$(nproc)
#RUN make -f Makefile.kernel

##### Build kernel image with a tested rootfs ######
WORKDIR /slice/linux
COPY rootfs.cpio /slice/rootfs.cpio
RUN make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- \
   CONFIG_INITRAMFS_SOURCE=/slice/rootfs.cpio -j$(nproc);

FROM slice-env as slice
COPY --from=linux /slice/linux/arch/riscv/boot/Image /slice/linux/arch/riscv/boot/Image 
WORKDIR /slice
COPY ./.git /slice/.git
COPY ./slice-boot /slice/slice-boot
#RUN git clone -b isolate-sbi https://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@github.com/MSRSSP/slice-hss.git
WORKDIR /slice/slice-boot
#RUN sed -i "s/github.com/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@github.com/g" .gitmodules
#RUN git submodule update --init --recursive
COPY def_config_slice /slice/slice-boot/.config
RUN cp boards/slice/def_config_slice .config
RUN mkdir Default-qemu
RUN sh make-qemu.sh

##### Build slice boot payload and create SD card image ########

WORKDIR /slice/slice-boot/bypass-uboot
RUN cd dts && make && cd .. && mkdir build
RUN sed -i "s/sudo//g" Makefile
#RUN make qemu EXAMPLE=slice
ENV TOP=/slice
RUN apt install -y telnet
##### Run .qemu.sh build/{image}.img to launch 2 slices ########
ENTRYPOINT make qemu && ./qemu.sh build/slice-qemu-sd.img && echo "Run `docker exec -it $containerid telnet 5433/5432` to login into  slice-1/slice-2; user = "root", password is empty"
#### Login into two slices:
#### docker exec -it $containerid telnet 5432
#### docker exec -it $containerid telnet 5433 
