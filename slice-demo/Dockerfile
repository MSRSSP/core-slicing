FROM slice-ubuntu
WORKDIR /root/slice/
RUN curl -k -L -o linux-riscv-build.tar.gz https://github.com/MSRSSP/core-slicing/releases/download/prebuilt/linux-riscv-build.tar.gz
RUN curl -k -L -o sliceloader.tar.gz https://github.com/MSRSSP/core-slicing/releases/download/prebuilt/sliceloader.tar.gz
RUN curl -k -L -o qemu-build.tar.gz https://github.com/MSRSSP/core-slicing/releases/download/prebuilt/qemu-build.tar.gz
RUN curl -k -L -o slice-payload.tar.gz https://github.com/MSRSSP/core-slicing/releases/download/prebuilt/slice-payload.tar.gz
RUN tar xvzf linux-riscv-build.tar.gz
RUN tar xvzf sliceloader.tar.gz
RUN tar xvzf qemu-build.tar.gz
RUN tar xvzf slice-payload.tar.gz
RUN cp -r linux-riscv-build linux-riscv-build2
WORKDIR /root/slice/slice-hss/bypass-uboot
ENTRYPOINT make qemu; export TOP=/root/slice/ && ./qemu.sh build/slice-qemu-sd.img && echo "Run `docker exec -it $containerid telnet 5433/5432` to login into  slice-1/slice-2; user = "root", password is empty"
