FROM ubuntu:bionic as ct-ng

# Install dependencies to build toolchain
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends\
        gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
        python3-dev libtool automake libtool-bin gawk wget rsync git patch \
        unzip xz-utils bzip2 ca-certificates && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Install autoconf
RUN wget https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz -O- | tar xz && \
    cd autoconf-2.71 && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    autoconf --version

# Add a user called `develop` and add him to the sudo group
RUN useradd -m develop && \
    echo "develop:develop" | chpasswd && \
    adduser develop sudo

USER develop
WORKDIR /home/develop

# Download and install the latest version of crosstool-ng
RUN git clone -b master --single-branch --depth 1 \
        https://github.com/crosstool-ng/crosstool-ng.git
WORKDIR /home/develop/crosstool-ng
RUN git show --summary && \
    ./bootstrap && \
    mkdir build && cd build && \
    ../configure --prefix=/home/develop/.local && \
    make -j$(($(nproc) * 2)) && \
    make install &&  \
    cd .. && rm -rf build

ENV PATH=/home/develop/.local/bin:$PATH
WORKDIR /home/develop 

# Patches
# https://www.raspberrypi.org/forums/viewtopic.php?f=91&t=280707&p=1700861#p1700861
RUN mkdir binutils && cd binutils && \
    wget https://ftp.debian.org/debian/pool/main/b/binutils/binutils-source_2.39-8_all.deb && \
    ar x binutils-source_2.39-8_all.deb && \
    tar xf data.tar.xz && \
    mkdir -p ../patches/binutils/2.39 && \
    cp usr/src/binutils/patches/129_multiarch_libpath.patch \
        ../patches/binutils/2.39 && \
    cd .. && \
    rm -rf binutils
