FROM ubuntu:20.04 AS env
  
RUN apt-get update && \  
    apt-get upgrade -y 
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
RUN apt-get install -y --no-install-recommends gawk 
RUN apt-get install -y --no-install-recommends expat  
RUN apt-get install -y --no-install-recommends telnet
RUN apt-get install -y --no-install-recommends libyaml-dev libelf-dev gdisk parted
RUN apt-get install -y --no-install-recommends libssl-dev  
RUN apt-get install -y --no-install-recommends bc  
RUN apt-get install -y --no-install-recommends sudo  
RUN apt-get install -y --no-install-recommends ninja-build

RUN apt-get install -y --no-install-recommends  autoconf automake autotools-dev curl python3 
RUN apt-get install -y --no-install-recommends  libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex
RUN apt-get install -y --no-install-recommends gperf libtool patchutils bc zlib1g-dev libexpat-dev
RUN apt-get install -y --no-install-recommends libglib2.0-dev libfdt-dev libpixman-1-dev
RUN apt-get install -y --no-install-recommends libpng-dev
RUN apt-get install -y --no-install-recommends libslirp-dev
RUN apt-get install -y --no-install-recommends libpulse-dev
RUN apt-get autoremove
RUN apt-get clean
RUN apt-get install -y --no-install-recommends openssh-client
RUN apt-get clean && \  
    rm -rf /var/lib/apt/lists/* 

  


