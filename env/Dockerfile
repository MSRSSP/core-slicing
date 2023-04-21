
FROM alpine
RUN apk update
RUN apk upgrade

# required by qemu
RUN apk add --no-cache \
 make\
 samurai\
 perl\
 python3\
 gcc\
 libc-dev\
 pkgconf\
 linux-headers\
 glib-dev glib-static\
 zlib-dev zlib-static
RUN apk add build-base git python3 glib-dev pixman-dev 

# additional
RUN apk add git patch bash
RUN apk add dtc
 
COPY gdisk /usr/bin/
COPY parted /usr/bin/
RUN rm -rf /var/cache/apk/*
