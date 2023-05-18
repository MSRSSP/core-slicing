dimage=slice-ubuntu
target=/root/slice
RISCV=${target}/install/rv64
DOCKER_RUN=docker run -v ${PWD}/:${target} -e RISCV=${RISCV} -e TOP=${target}
USE_DOCKER?=true
RUN=if ${USE_DOCKER}; then ${DOCKER_RUN} -w ${target}/$1 $2 ${dimage} bash -c "$3"; else cd ${PWD}/$1 && export RISCV=${RISCV} && export TOP=${target} && export GIT_SSL_NO_VERIFY=true && bash -c "$3";fi
#RUN=cd ${target}/$1 && export RISCV=${RISCV} && export TOP=${target} && $3
totalcores=$(shell nproc)
ncores=$$(($(totalcores)/2))
setup:
	git submodule update --init --progress slice-hss qemu
	cd slice-hss && git submodule update --init --recursive  --progress
all: slice-ubuntu run
install:
	wget https://github.com/MSRSSP/slice-docker-env/releases/download/prebuilt/riscv-tools.tar.gz
	tar xvzf riscv-tools.tar.gz
slice-ubuntu:
	docker build docker/ --tag ${dimage}
qemu/build:
	#cd qemu && ./configure --target-list=riscv64-softmmu && make -j `nproc`
	@$(call RUN,qemu,-e GIT_SSL_NO_VERIFY=true,git config --global --add safe.directory ./ &&./configure --target-list=riscv64-softmmu&&make -j `nproc`)
	#${DOCKER_RUN} -w ${target}/qemu ${dimage} bash -c "export GIT_SSL_NO_VERIFY=true; ./configure --target-list=riscv64-softmmu&&make -j `nproc`"

qemu: qemu/build

linux-5.15-rc4: install
	git clone https://github.com/torvalds/linux --branch v5.15-rc4 --depth 1 linux-5.15-rc4
	cd linux-5.15-rc4 && git apply ../0001-Add-microchip-specific-clock-and-devices.patch
linux-build-tmp: linux-5.15-rc4
	mkdir -p linux-build-tmp
	cp kernelconfig linux-build-tmp/.config

linux-build-tmp/arch/riscv/boot/Image: linux-build-tmp
	@$(call RUN,linux-5.15-rc4,,source ../install/env.sh && make O=../linux-build-tmp ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- CONFIG_INITRAMFS_SOURCE=/root/slice/rootfs.cpio -j${ncores})

linux-riscv-build/arch/riscv/boot/Image: linux-build-tmp/arch/riscv/boot/Image
	mkdir -p linux-riscv-build/arch/riscv/boot/
	cp linux-build-tmp/arch/riscv/boot/Image linux-riscv-build/arch/riscv/boot/Image

linux-riscv-build2/arch/riscv/boot/Image: linux-build-tmp/arch/riscv/boot/Image
	mkdir -p linux-riscv-build2/arch/riscv/boot/
	cp linux-build-tmp/arch/riscv/boot/Image linux-riscv-build2/arch/riscv/boot/Image

linux-riscv-build: linux-riscv-build/arch/riscv/boot/Image

linux-riscv-build2: linux-riscv-build2/arch/riscv/boot/Image

linux-riscv-rebuild: linux-build-tmp linux-5.15-rc4
	@$(call RUN,linux-5.15-rc4,,source /root/slice/install/env.sh && make O=../linux-build-tmp ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- CONFIG_INITRAMFS_SOURCE=../rootfs.cpio -j${ncores})

slice-hss/.config: slice-hss/boards/slice/slice_config_attest
	cp $< $@

slice-hss/Default-qemu/hss-envm-wrapper.bin: slice-hss/.config
	@$(call RUN,slice-hss,,source ../install/env.sh; sh make-qemu.sh; sh make-qemu.sh)
	#${DOCKER_RUN}  -w ${target}/slice-hss  ${dimage} bash -c  "source ../install/env.sh; sh make-qemu.sh"

slice-hss/bypass-uboot/build/slice-qemu-sd.img: slice-hss/Default-qemu/hss-envm-wrapper.bin
	@$(call RUN,slice-hss/bypass-uboot,-v /dev:/dev --privileged,make -C dts; make qemu)
	#${DOCKER_RUN}  -v /dev:/dev --privileged -w ${target}/slice-hss/bypass-uboot   ${dimage} \
	#bash -c  "make -C dts; make qemu"

payload-build: linux-riscv-build linux-riscv-build2 slice-hss/bypass-uboot/build/slice-qemu-sd.img
	touch payload-build
run: qemu payload-build
	rm -rf cidfile.txt
	@$(call RUN,slice-hss/bypass-uboot,-v /dev:/dev --privileged --cidfile cidfile.txt -it, ./qemu.sh build/slice-qemu-sd.img)
	#${DOCKER_RUN} -v /dev:/dev --privileged --cidfile cidfile.txt -w ${target}/slice-hss/bypass-uboot  -it ${dimage} bash 
	#docker run -v /root/slice:/root/slice -v /dev:/dev --privileged --cidfile cidfile.txt -w ${target}/slice-hss/bypass-uboot  -it ${dimage} bash
	#-c "./qemu.sh build/slice-qemu-sd.img"

clean:
	rm -r slice-hss/Default-qemu
	find -type f -name "*.o" -delete
