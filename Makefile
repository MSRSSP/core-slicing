dimage=slice-ubuntu
target=/root/slice
RISCV=${target}/install/rv64
DOCKER_RUN=docker run -v ${PWD}/:${target} -e RISCV=${RISCV} -e TOP=${target}

#RUN=echo "$1 $2" ${dimage} $3;

RUN=${DOCKER_RUN} -w ${target}/$1 $2 ${dimage} bash -c "$3";

slice-ubuntu:
	docker build docker/ --tag ${dimage}
qemu/build:
	#cd qemu && ./configure --target-list=riscv64-softmmu && make -j `nproc`
	@$(call RUN,qemu,-e GIT_SSL_NO_VERIFY=true,./configure --target-list=riscv64-softmmu&&make -j `nproc`)
	#${DOCKER_RUN} -w ${target}/qemu ${dimage} bash -c "export GIT_SSL_NO_VERIFY=true; ./configure --target-list=riscv64-softmmu&&make -j `nproc`"

linux-5.15-rc4:
	wget https://github.com/torvalds/linux/archive/refs/tags/v5.15-rc4.zip
	unzip v5.15-rc4.zip
	cd linux-5.15-rc4
	patch -s -p0 < ../0001-Add-microchip-specific-clock-and-devices.patch;
linux-build-tmp: linux-5.15-rc4
	mkdir -p linux-build-tmp
	cp kernelconfig linux-build-tmp/.config

linux-riscv-build: linux-build-tmp linux-5.15-rc4
	#${DOCKER_RUN} \
	#-w ${target}/linux-5.15-rc4 ${dimage} \
	#bash -c "source /root/slice/install/env.sh; make O=../linux-build-tmp ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- CONFIG_INITRAMFS_SOURCE=/root/slice/rootfs.cpio -j `expr $(nproc) - 4` ;"
	@$(call RUN,linux-5.15-rc4,,source /root/slice/install/env.sh && make O=../linux-build-tmp ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- CONFIG_INITRAMFS_SOURCE=/root/slice/rootfs.cpio -j `expr $(nproc) - 4`)
	ln -s linux-build-tmp linux-riscv-build

slice-hss/.config: slice-hss/boards/slice/slice_config_attest
	cp $< $@

slice-hss/Default-qemu: slice-hss/.config
	@$(call RUN,slice-hss,,source /root/slice/install/env.sh; sh make-qemu.sh)
	#${DOCKER_RUN}  -w ${target}/slice-hss  ${dimage} bash -c  "source /root/slice/install/env.sh; sh make-qemu.sh"

payload-build: slice-hss/Default-qemu linux-riscv-build
	@$(call RUN,slice-hss/bypass-uboot,-v /dev:/dev --privileged,make -C dts; make qemu)
	#${DOCKER_RUN}  -v /dev:/dev --privileged -w ${target}/slice-hss/bypass-uboot   ${dimage} \
	#bash -c  "make -C dts; make qemu"
	touch payload-build
run: qemu/build payload-build
	rm -rf cidfile.txt
	@$(call RUN,slice-hss/bypass-uboot,-v /dev:/dev --privileged --cidfile cidfile.txt -it,bash)
	#${DOCKER_RUN} -v /dev:/dev --privileged --cidfile cidfile.txt -w ${target}/slice-hss/bypass-uboot  -it ${dimage} bash
	#docker run -v /root/slice:/root/slice -v /dev:/dev --privileged --cidfile cidfile.txt -w ${target}/slice-hss/bypass-uboot  -it ${dimage} bash
	#-c "./qemu.sh build/slice-qemu-sd.img"

riscv-gnu-toolchain:
	git clone https://github.com/riscv/riscv-gnu-toolchain
	git checkout 2022.01.17
	${DOCKER_RUN} \
	-w /slice/ ${dimage} sh -c "cd riscv-gnu-toolchain; ./configure --prefix=${target}/riscv-install -with-arch=rv64imafdc --with-abi=lp64d"
riscv_install: riscv-gnu-toolchain
	mkdir -p riscv-install
	${DOCKER_RUN}  -w ${target} ${dimage}  bash -c "cd riscv-gnu-toolchain; make linux -j `nproc`"


