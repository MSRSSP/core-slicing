dimage=slice-ubuntu
target=/root/slice
RISCV=${target}/install/rv64
DOCKER_RUN=docker run -v ${PWD}/:${target} -e RISCV=${RISCV} -e TOP=${target}
USE_DOCKER?=true
RUN=if ${USE_DOCKER}; then ${DOCKER_RUN} -w ${target}/$1 $2 ${dimage} bash -c "$3"; else cd ${PWD}/$1 && export RISCV=${RISCV} && export TOP=${target} && export GIT_SSL_NO_VERIFY=true && bash -c "$3";fi
#RUN=cd ${target}/$1 && export RISCV=${RISCV} && export TOP=${target} && $3
totalcores=$(shell nproc)
#ncores=$$(($(totalcores)*3/4))
ncores=${totalcores}
setup:
	git submodule update --init --progress slice-hss qemu
	cd slice-hss && git submodule update --init --recursive  --progress

all: slice-ubuntu linux-5.15-rc4 payload-build qemu

quick-build: slice-ubuntu qemu-prebuilt guest-linux-prebuilt payload-build

riscv-install: install

install:
	wget https://github.com/MSRSSP/slice-docker-env/releases/download/prebuilt/riscv-tools.tar.gz
	tar xvzf riscv-tools.tar.gz
	chmod +x install/rv64/bin/*

slice-ubuntu:
	docker build docker/ --tag ${dimage}
qemu/build:
	@$(call RUN,qemu,-e GIT_SSL_NO_VERIFY=true,git config --global --add safe.directory '*' && scripts/git-submodule.sh update  ui/keycodemapdb meson tests/fp/berkeley-testfloat-3 tests/fp/berkeley-softfloat-3 dtc capstone slirp &&./configure --with-git-submodules=ignore --target-list=riscv64-softmmu &&make -j `nproc`)

qemu-prebuilt:
	curl -L -O https://github.com/MSRSSP/slice-docker-env/releases/download/prebuilt/qemu-build.tar.gz
	tar xvzf qemu-build.tar.gz
	touch qemu/build

qemu: qemu/build

linux-5.15-rc4: install
	git clone https://github.com/torvalds/linux --branch v5.15-rc4 --depth 1 linux-5.15-rc4
	cd linux-5.15-rc4 && git apply ../0001-Add-microchip-specific-clock-and-devices.patch
linux-build-tmp/.config:
	mkdir -p linux-build-tmp
	cp kernelconfig linux-build-tmp/.config

linux-build-tmp/arch/riscv/boot/Image: linux-build-tmp/.config
	@$(call RUN,linux-5.15-rc4,,source ../install/env.sh && which riscv64-unknown-linux-gnu-gcc && make O=../linux-build-tmp ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- CONFIG_INITRAMFS_SOURCE=../rootfs.cpio -j${ncores})

linux-riscv-build/arch/riscv/boot/Image: linux-build-tmp/arch/riscv/boot/Image
	mkdir -p linux-riscv-build/arch/riscv/boot/
	cp linux-build-tmp/arch/riscv/boot/Image linux-riscv-build/arch/riscv/boot/Image

linux-riscv-build2/arch/riscv/boot/Image: linux-build-tmp/arch/riscv/boot/Image
	mkdir -p linux-riscv-build2/arch/riscv/boot/
	cp linux-build-tmp/arch/riscv/boot/Image linux-riscv-build2/arch/riscv/boot/Image

linux-riscv-build: linux-riscv-build/arch/riscv/boot/Image

linux-riscv-build2: linux-riscv-build2/arch/riscv/boot/Image

linux-riscv-rebuild: linux-build-tmp linux-5.15-rc4
	@$(call RUN,linux-5.15-rc4,,source ../install/env.sh && make O=../linux-build-tmp ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- CONFIG_INITRAMFS_SOURCE=../rootfs.cpio -j${ncores})

guest-linux-prebuilt:
	wget https://github.com/MSRSSP/slice-docker-env/releases/download/prebuilt/linux-riscv-build.tar.gz
	tar xvzf linux-riscv-build.tar.gz
	mkdir -p linux-build-tmp
	mkdir -p linux-riscv-build2
	cp kernelconfig linux-build-tmp/.config
	cp -r linux-riscv-build/* linux-build-tmp/
	cp -r linux-riscv-build/* linux-riscv-build2/
	touch linux-build-tmp/arch/riscv/boot/Image
	touch linux-riscv-build2/arch/riscv/boot/Image
	touch linux-riscv-build/arch/riscv/boot/Image


slice-hss/.config: slice-hss/boards/slice/slice_config_attest
	cp $< $@

slice-hss/Default-qemu/hss-envm-wrapper.bin: slice-hss/.config install
	@$(call RUN,slice-hss,,source ../install/env.sh; sh make-qemu.sh)

slice-hss/bypass-uboot/build/slice-qemu-sd.img: slice-hss/Default-qemu/hss-envm-wrapper.bin linux-riscv-build linux-riscv-build2
	@$(call RUN,slice-hss/bypass-uboot,-v /dev:/dev --privileged,make -C dts; make qemu)

payload-build: slice-hss/bypass-uboot/build/slice-qemu-sd.img
	touch payload-build
run: payload-build qemu
	rm -rf cidfile.txt
	@$(call RUN,slice-hss/bypass-uboot,-v /dev:/dev --privileged --cidfile cidfile.txt -it, ./qemu.sh build/slice-qemu-sd.img)

clean:
	rm -r slice-hss/Default-qemu
	rm -r linux-build-tmp
	find -type f -name "*.o" -delete
