# Dockerfile to build qemu and slice-hss

## Install
```
git submodule --init
docker build --tag slice ./
```

## Run
```
docker run -it --privileged --cidfile cidfile.txt -v /dev:/dev slice
```
TODO(Remove privileged and /dev): Users currently need privileged and need to mount /dev into the container, in order to use `sgdisk` and `losetup` command. 

The container will run a qemu to emulate microchip Polarfire machine with a per-core reset device. By default, it uses an example slice configuration (2 slices, each uses 2 cores and 512 MB memory) provided in slice-boot/bypass-uboot/config/slice/config.yaml. The terminal is used for slice management. Try `slice help` to see how to view and change the slice configuration.

Open a new terminal and login into slice-1 as root (password is empty)

```
docker exec -it $(cat cidfile) telnet localhost 5432
```

An example is
```
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.

Welcome to Slice
guest-slice login: root
Jan  1 00:04:54 login[83]: root login on 'console'
~ #
```


Similarly, open a new terminal and login into slice-2

```
docker exec -it $(cat cidfile) telnet localhost 5431
```

## Verify the correctness
1. Check the /proc/cpuinfo
2. Run `slice dump` in the first terminal.
3. Run `slice reset $index; slice start $index` to reset slice-#index; index=1 or 2 in this example; This reset will use a per-core reset device provided by qemu;

## Limitations of using qemu
1. [Perf result is not useful since it is under qemu] Run benchmark `sh /usr/bin/coremark-pro.sh`
2. [Unimplemented cache controller] `slice cache` will always show zero value for cache controller registers


