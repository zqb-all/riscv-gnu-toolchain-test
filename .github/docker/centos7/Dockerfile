FROM centos:centos7

LABEL maintainer="riscv-gnu-toolchain"
LABEL description="Build environment for RISC-V GNU toolchain on CentOS 7 (glibc 2.17)"

# CentOS 7 is EOL; pin to 7.9.2009 and list mirrors for fallback.
COPY Centos-7.repo /etc/yum.repos.d/CentOS-Base.repo

# ---------------------------------------------------------------------------
# LAYER ORDER: the GCC 11.5 build in layer 2 takes ~1 hour. Keep it early so
# that later edits (e.g. adding a package below) hit cache and skip the wait.
# Add new packages AFTER the GCC layer, never before.
# ---------------------------------------------------------------------------

# Layer 1 — packages required before building GCC.
# CentOS 7 ships GCC 4.8, which cannot build GCC 16.x (needs C++14).
RUN yum -y install \
        sudo file zip unzip tree bzip2 xz tar vim which wget \
        autoconf automake libtool pkgconfig \
        gawk gperf bc m4 bison flex texinfo patch patchutils \
        gcc gcc-c++ make zlib-devel expat-devel \
        openssl-devel perl-devel perl-ExtUtils-MakeMaker \
        ca-certificates curl-devel gettext gettext-devel \
        git python3 && \
    yum clean all

# Layer 2 — host GCC 11.5 (~1 hour; replaces system GCC 4.8).
RUN cd /tmp && \
    wget -q https://mirrors.aliyun.com/gnu/gcc/gcc-11.5.0/gcc-11.5.0.tar.gz && \
    tar -zxf gcc-11.5.0.tar.gz && \
    cd gcc-11.5.0 && \
    ./contrib/download_prerequisites && \
    mkdir build && cd build && \
    ../configure --enable-checking=release --enable-languages=c,c++ \
        --disable-multilib --prefix=/usr && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && rm -rf gcc-11.5.0* && \
    gcc --version

# Layer 3 — remaining tools; edit freely without invalidating layer 2.

# GNU Make 4.3 — CentOS 7 ships 3.82, which some sub-projects reject.
RUN cd /tmp && \
    wget -q https://mirrors.aliyun.com/gnu/make/make-4.3.tar.gz && \
    tar -xf make-4.3.tar.gz && \
    cd make-4.3 && \
    ./configure --prefix=/usr/local/make && \
    make -j$(nproc) && make install && \
    rm -f /usr/bin/make && \
    ln -sv /usr/local/make/bin/make /usr/bin/make && \
    cd /tmp && rm -rf make-4.3* && \
    make --version | head -1

# Git 2.25 — CentOS 7 ships 1.8, which cannot clone some submodules.
RUN cd /tmp && \
    wget -q https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.25.0.tar.xz && \
    tar -xf git-2.25.0.tar.xz && \
    cd git-2.25.0 && \
    make prefix=/usr -j$(nproc) install && \
    cd /tmp && rm -rf git-2.25.0* && \
    git --version

# Python 3.8 — CentOS 7 ships 3.6; meson requires >=3.7.
# --enable-shared is required because GDB links against libpython.
# /usr/local/lib must be registered so the dynamic loader finds the .so.
RUN yum -y install libffi-devel bzip2-devel && \
    cd /tmp && \
    wget -q https://mirrors.aliyun.com/python-release/source/Python-3.8.1.tgz && \
    tar -xzf Python-3.8.1.tgz && \
    cd Python-3.8.1 && \
    CFLAGS=-fPIC ./configure --enable-optimizations --enable-shared && \
    make -j$(nproc) && make install && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/local-lib.conf && \
    ldconfig && \
    cd /tmp && rm -rf Python-3.8.1* && \
    python3 --version

# CMake 3.23 — required by the LLVM build and by ccache.
RUN cd /tmp && \
    wget -q https://cmake.org/files/v3.23/cmake-3.23.0.tar.gz && \
    tar -xzf cmake-3.23.0.tar.gz && \
    cd cmake-3.23.0 && \
    ./bootstrap --parallel=$(nproc) && \
    make -j$(nproc) && make install && \
    ln -sf /usr/local/bin/cmake /usr/bin/cmake && \
    cd /tmp && rm -rf cmake-3.23.0* && \
    cmake --version | head -1

# Ninja — LLVM's preferred generator.
RUN cd /tmp && \
    git clone --depth 1 https://github.com/ninja-build/ninja.git && \
    cd ninja && \
    ./configure.py --bootstrap && \
    cp ninja /usr/bin/ && \
    cd /tmp && rm -rf ninja && \
    ninja --version

# re2c — required by several sub-projects.
RUN cd /tmp && \
    git clone --depth 1 https://github.com/skvadrik/re2c.git && \
    cd re2c && \
    mkdir -p m4 && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make -j$(nproc) install && \
    cd /tmp && rm -rf re2c && \
    re2c --version

# dtc — device tree compiler, needed for QEMU.
RUN cd /tmp && \
    git clone --depth 1 https://kernel.googlesource.com/pub/scm/utils/dtc/dtc && \
    cd dtc && \
    make -j$(nproc) && \
    cp dtc /usr/bin/ && \
    cd /tmp && rm -rf dtc && \
    dtc --version

# libzstd (optional) — lets binutils handle zstd-compressed debug sections.
RUN yum -y install epel-release || echo "epel-release unavailable, continuing"; \
    yum -y install libzstd libzstd-devel libzstd-static || \
        echo "libzstd unavailable -- binutils will build without zstd support"; \
    yum clean all

# Tcl/Tk and DejaGnu for GDB TUI and test suites.
RUN yum -y install tk tk-devel tcl tcl-devel dejagnu && \
    yum clean all

# Automake 1.14 — some sub-projects pin this exact version.
RUN cd /tmp && \
    wget -q https://ftp.gnu.org/gnu/automake/automake-1.14.tar.gz && \
    tar xzf automake-1.14.tar.gz && \
    cd automake-1.14 && \
    ./configure && \
    make -j$(nproc) && make install && \
    rm -f /usr/bin/automake && \
    ln -sf /usr/local/bin/automake-1.14 /usr/bin/automake && \
    cd /tmp && rm -rf automake-1.14* && \
    automake --version | head -1

RUN cd /tmp && \
    wget -q https://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.gz && \
    tar -zxf libtool-2.4.6.tar.gz && \
    cd libtool-2.4.6 && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && make install && \
    ldconfig && \
    cd /tmp && rm -rf libtool-2.4.6* && \
    libtool --version | head -1

RUN cd /tmp && \
    wget -q https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz && \
    tar -zxf pkg-config-0.29.2.tar.gz && \
    cd pkg-config-0.29.2 && \
    ./configure --with-internal-glib && \
    make -j$(nproc) && make install && \
    ldconfig && \
    cd /tmp && rm -rf pkg-config-0.29.2* && \
    pkg-config --version

RUN mkdir -p /usr/local/share/aclocal && \
    cp -fpr /usr/share/aclocal/* /usr/local/share/aclocal/ 2>/dev/null || true

# ncurses 6.5 — GDB requires a modern ncurses for its TUI.
RUN cd /tmp && \
    wget -q https://ftp.gnu.org/gnu/ncurses/ncurses-6.5.tar.gz && \
    tar -zxf ncurses-6.5.tar.gz && \
    cd ncurses-6.5 && \
    CFLAGS="-fPIC" CXXFLAGS="-fPIC" ./configure \
        --without-debug --without-ada --enable-overwrite && \
    make -j$(nproc) && make install && \
    ldconfig && \
    cd /tmp && rm -rf ncurses-6.5*

RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir psutil meson

# ccache — must come after CMake.
RUN cd /tmp && \
    wget -q https://github.com/ccache/ccache/releases/download/v4.10.2/ccache-4.10.2.tar.gz && \
    tar -xzf ccache-4.10.2.tar.gz && \
    cd ccache-4.10.2 && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc) && make install && \
    cd /tmp && rm -rf ccache-4.10.2* && \
    ccache --version | head -1

# Host copies of gmp/mpfr/mpc let configure link them rather than rebuilding.
RUN yum -y install \
        gmp-devel mpfr-devel libmpc-devel \
        glib2-devel expat-devel \
        python3-pyelftools || \
    python3 -m pip install --no-cache-dir pyelftools; \
    yum clean all && ldconfig

RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER builder
WORKDIR /home/builder

ENV PATH="/usr/local/bin:/usr/lib64/ccache:${PATH}"
ENV CCACHE_DIR="/home/builder/.ccache"
ENV CCACHE_MAXSIZE="2G"

RUN set -e; \
    gcc --version | head -1; \
    make --version | head -1; \
    git --version; \
    python3 --version; \
    cmake --version | head -1; \
    ninja --version; \
    ccache --version | head -1; \
    echo "--- CentOS 7 build image OK ---"

CMD ["/bin/bash"]
