FROM ubuntu:20.04 AS env
  
RUN apt-get update

RUN apt-get install -y --no-install-recommends \  
        make \  
        perl \  
        python3 \  
        gcc \  
        libc-dev \  
        pkgconf \  
        libglib2.0-dev
Run apt-get install -y --no-install-recommends \ 
        zlib1g-dev \  
        build-essential \  
        libpixman-1-dev

RUN apt-get install -y --no-install-recommends git \ 
        patch \  
        bash \  
        device-tree-compiler \  
        bison \  
        flex

RUN apt-get update && apt-get install -y --no-install-recommends \
    gawk \
    expat \
    telnet \
    libyaml-dev \
    libelf-dev \
    gdisk \
    parted \
    libssl-dev \
    bc \
    sudo \
    ninja-build


RUN apt-get install -y --no-install-recommends \
    autoconf automake autotools-dev curl \
    libmpc-dev libmpfr-dev libgmp-dev \
    gperf libtool patchutils libexpat-dev \
    libfdt-dev \
    libpng-dev \
    libslirp-dev \
    libpulse-dev

RUN apt-get autoremove
RUN apt-get clean && \  
    rm -rf /var/lib/apt/lists/* 

  


