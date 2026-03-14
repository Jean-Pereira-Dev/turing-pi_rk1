ARG FEDORA_VERSION=43
FROM registry.fedoraproject.org/fedora:${FEDORA_VERSION}

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    ARMBIAN_RUNNING_IN_CONTAINER=yes \
    NO_HOST_RELEASE_CHECK=yes \
    PRE_PREPARED_HOST=yes \
    CCACHE_PATH=/usr/bin:/usr/local/bin

RUN dnf -y upgrade --refresh && \
    dnf -y install \
      ImageMagick \
      aria2 \
      arch-test \
      axel \
      bc \
      binutils-aarch64-linux-gnu \
      binutils-arm-linux-gnu \
      binutils-riscv64-linux-gnu \
      binwalk \
      bison \
      btrfs-progs \
      ca-certificates \
      ccache \
      cargo \
      cpio \
      cryptsetup \
      curl \
      dialog \
      dh-autoreconf \
      dosfstools \
      dpkg \
      dpkg-dev \
      dtc \
      dwarves \
      e2fsprogs \
      elfutils-libelf-devel \
      expect \
      f2fs-tools \
      file \
      findutils \
      flex \
      flex-devel \
      gcc \
      gcc-aarch64-linux-gnu \
      gcc-arm-linux-gnu \
      gcc-c++ \
      gcc-riscv64-linux-gnu \
      gdisk \
      gettext \
      git \
      glibc-devel \
      glibc-langpack-en \
      glibc-locale-source \
      gnutls-devel \
      gawk \
      gnupg2 \
      gzip \
      jq \
      libfdt-devel \
      libffi-devel \
      libmpc-devel \
      libusb1-devel \
      libuuid-devel \
      lvm2 \
      lzop \
      make \
      ncurses-devel \
      nilfs-utils \
      ntpsec \
      openssh-clients \
      openssl-devel \
      parallel \
      parted \
      patchutils \
      pbzip2 \
      perl-File-FcntlLock \
      pigz \
      pkgconf-pkg-config \
      psmisc \
      pv \
      python3 \
      python3-pip \
      python3-devel \
      qemu-img \
      qemu-user-static \
      rdfind \
      rsync \
      rust \
      swig \
      systemd-udev \
      tar \
      tree \
      uboot-tools \
      unzip \
      util-linux \
      wget \
      which \
      xfsprogs \
      xz \
      zip \
      zerofree \
      zlib-devel \
      zstd && \
    dnf clean all && \
    rm -rf /var/cache/dnf

COPY docker/fedora/bin/ansi2txt /usr/local/bin/ansi2txt
COPY docker/fedora/bin/linux-version /usr/local/bin/linux-version
COPY docker/fedora/bin/locale-gen /usr/local/bin/locale-gen
COPY docker/fedora/bin/pipetty /usr/local/bin/pipetty

RUN chmod 0755 /usr/local/bin/ansi2txt /usr/local/bin/linux-version /usr/local/bin/locale-gen /usr/local/bin/pipetty && \
    for tool in /usr/bin/arm-linux-gnu-*; do \
      name="$(basename "${tool}")"; \
      ln -sf "${tool}" "/usr/local/bin/${name/arm-linux-gnu-/arm-linux-gnueabi-}"; \
    done

WORKDIR /workspace
