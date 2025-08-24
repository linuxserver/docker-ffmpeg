# syntax=docker/dockerfile:1

# build stage
FROM ghcr.io/linuxserver/baseimage-ubuntu:noble AS buildstage

# set version label
ARG FFMPEG_VERSION

# common env
ENV \
  DEBIAN_FRONTEND="noninteractive" \
  MAKEFLAGS="-j4" \
  CMAKE_POLICY_VERSION_MINIMUM="3.5" \
  PATH="/root/.cargo/bin:${PATH}"

# versions
ENV \
  AOM=v3.12.1 \
  FDKAAC=2.0.3 \
  FFMPEG_HARD=8.0 \
  FONTCONFIG=2.16.0 \
  FREETYPE=2.13.3 \
  FRIBIDI=1.0.16 \
  GMMLIB=22.8.0 \
  HARFBUZZ=11.4.3 \
  IHD=25.2.6 \
  KVAZAAR=2.3.1 \
  LAME=3.100 \
  LIBASS=0.17.4 \
  LIBDAV1D=1.5.1 \
  LIBDOVI=2.3.1 \
  LIBDRM=2.4.125 \
  LIBGL=1.7.0 \
  LIBLC3=1.1.3 \
  LIBMFX=22.5.4 \
  LIBPLACEBO=7.351.0 \
  LIBPNG=1.6.50 \
  LIBVA=2.22.0 \
  LIBVDPAU=1.5 \
  LIBVIDSTAB=1.1.1 \
  LIBVMAF=3.0.0 \
  LIBVPL=2.15.0 \
  MESA=25.2.1 \
  NVCODEC=n13.0.19.0 \
  OGG=1.3.6 \
  OPENCOREAMR=0.1.6 \
  OPENJPEG=2.5.3 \
  OPUS=1.5.2 \
  RAV1E=0.8.1 \
  RIST=0.2.11 \
  SHADERC=v2025.3 \
  SRT=1.5.4 \
  SVTAV1=3.1.1 \
  THEORA=1.2.0 \
  VORBIS=1.3.7 \
  VPLGPURT=25.2.6 \
  VPX=1.15.2 \
  VULKANSDK=vulkan-sdk-1.4.321.0 \
  VVENC=1.13.1 \
  WEBP=1.6.0 \
  X265=4.1 \
  XVID=1.3.7 \
  ZIMG=3.0.6 \
  ZMQ=v4.3.5

RUN \
  echo "**** install build packages ****" && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    autoconf \
    automake \
    bindgen \
    bison \
    build-essential \
    bzip2 \
    cmake \
    clang \
    diffutils \
    doxygen \
    flex \
    g++ \
    gcc \
    git \
    gperf \
    i965-va-driver-shaders \
    libasound2-dev \
    libcairo2-dev \
    libclang-18-dev \
    libclang-cpp18-dev \
    libclc-18 \
    libclc-18-dev \
    libelf-dev \
    libexpat1-dev \
    libgcc-10-dev \
    libglib2.0-dev \
    libgomp1 \
    libllvmspirvlib-18-dev \
    libpciaccess-dev \
    libssl-dev \
    libtool \
    libv4l-dev \
    libwayland-dev \
    libwayland-egl-backend-dev \
    libx11-dev \
    libx11-xcb-dev \
    libxcb-dri2-0-dev \
    libxcb-dri3-dev \
    libxcb-glx0-dev \
    libxcb-present-dev \
    libxext-dev \
    libxfixes-dev \
    libxml2-dev \
    libxrandr-dev \
    libxshmfence-dev \
    libxxf86vm-dev \
    llvm-18-dev \
    llvm-spirv-18 \
    make \
    nasm \
    ocl-icd-opencl-dev \
    perl \
    pkg-config \
    python3-venv \
    x11proto-gl-dev \
    x11proto-xext-dev \
    xxd \
    yasm \
    zlib1g-dev && \
  mkdir -p /tmp/rust && \
  RUST_VERSION=$(curl -fsX GET https://api.github.com/repos/rust-lang/rust/releases/latest | jq -r '.tag_name') && \
  curl -fo /tmp/rust.tar.gz -L "https://static.rust-lang.org/dist/rust-${RUST_VERSION}-x86_64-unknown-linux-gnu.tar.gz" && \
  tar xf /tmp/rust.tar.gz -C /tmp/rust --strip-components=1 && \
  cd /tmp/rust && \
  ./install.sh && \
  cargo install bindgen-cli cargo-c cbindgen --locked && \
  python3 -m venv /lsiopy && \
  pip install -U --no-cache-dir \
    pip \
    setuptools \
    wheel && \
  pip install --no-cache-dir cmake==3.31.6 mako meson ninja packaging ply pyyaml

# compile 3rd party libs
RUN \
  echo "**** grabbing aom ****" && \
  mkdir -p /tmp/aom && \
  git clone \
    --branch ${AOM} \
    --depth 1 https://aomedia.googlesource.com/aom \
    /tmp/aom
RUN \
  echo "**** compiling aom ****" && \
  cd /tmp/aom && \
  rm -rf \
    CMakeCache.txt \
    CMakeFiles && \
  mkdir -p \
    aom_build && \
  cd aom_build && \
  cmake \
    -DBUILD_STATIC_LIBS=0 .. && \
  make && \
  make install
RUN \
  echo "**** grabbing fdk-aac ****" && \
  mkdir -p /tmp/fdk-aac && \
  curl -Lf \
    https://github.com/mstorsjo/fdk-aac/archive/v${FDKAAC}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/fdk-aac
RUN \
  echo "**** compiling fdk-aac ****" && \
  cd /tmp/fdk-aac && \
  autoreconf -fiv && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install && \
  strip -d /usr/local/lib/libfdk-aac.so
RUN \
  echo "**** grabbing ffnvcodec ****" && \
  mkdir -p /tmp/ffnvcodec && \
  git clone \
    --branch ${NVCODEC} \
    --depth 1 https://github.com/FFmpeg/nv-codec-headers.git \
    /tmp/ffnvcodec
RUN \
  echo "**** compiling ffnvcodec ****" && \
  cd /tmp/ffnvcodec && \
  make install
RUN \
  echo "**** grabbing freetype ****" && \
  mkdir -p /tmp/freetype && \
  curl -Lf \
    https://downloads.sourceforge.net/project/freetype/freetype2/${FREETYPE}/freetype-${FREETYPE}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/freetype
RUN \
  echo "**** compiling freetype ****" && \
  cd /tmp/freetype && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install && \
  strip -d /usr/local/lib/libfreetype.so
RUN \
  echo "**** grabbing fontconfig ****" && \
  mkdir -p /tmp/fontconfig && \
  curl -Lf \
    https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG}.tar.xz | \
    tar -xJ --strip-components=1 -C /tmp/fontconfig
RUN \
  echo "**** compiling fontconfig ****" && \
  cd /tmp/fontconfig && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install && \
  strip -d /usr/local/lib/libfontconfig.so
RUN \
  echo "**** grabbing fribidi ****" && \
  mkdir -p /tmp/fribidi && \
  curl -Lf \
    https://github.com/fribidi/fribidi/archive/v${FRIBIDI}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/fribidi
RUN \
  echo "**** compiling fribidi ****" && \
  cd /tmp/fribidi && \
  ./autogen.sh && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make -j 1 && \
  make install && \
  strip -d /usr/local/lib/libfribidi.so
RUN \
  echo "**** grabbing harfbuzz ****" && \
  mkdir -p /tmp/harfbuzz && \
  curl -Lf \
    https://github.com/harfbuzz/harfbuzz/archive/${HARFBUZZ}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/harfbuzz
RUN \
  echo "**** compiling harfbuzz ****" && \
  cd /tmp/harfbuzz && \
  meson build && \
  ninja -C build install && \
  strip -d /usr/local/lib/x86_64-linux-gnu/libharfbuzz*.so
RUN \
  echo "**** grabbing kvazaar ****" && \
  mkdir -p /tmp/kvazaar && \
  curl -Lf \
    https://github.com/ultravideo/kvazaar/archive/v${KVAZAAR}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/kvazaar
RUN \
  echo "**** compiling kvazaar ****" && \
  cd /tmp/kvazaar && \
  ./autogen.sh && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install && \
  strip -d /usr/local/lib/libkvazaar.so
RUN \
  echo "**** grabbing lame ****" && \
  mkdir -p /tmp/lame && \
  curl -Lf \
    http://downloads.sourceforge.net/project/lame/lame/${LAME}/lame-${LAME}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/lame
RUN \
  echo "**** compiling lame ****" && \
  cd /tmp/lame && \
  cp \
    /usr/share/automake-1.16/config.guess \
    config.guess && \
  cp \
    /usr/share/automake-1.16/config.sub \
    config.sub && \
  ./configure \
    --disable-frontend \
    --disable-static \
    --enable-nasm \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing libass ****" && \
  mkdir -p /tmp/libass && \
  curl -Lf \
    https://github.com/libass/libass/archive/${LIBASS}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/libass
RUN \
  echo "**** compiling libass ****" && \
  cd /tmp/libass && \
  ./autogen.sh && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install && \
  strip -d /usr/local/lib/libass.so
RUN \
  echo "**** grabbing libdav1d ****" && \
  mkdir -p /tmp/libdav1d && \
  git clone \
    --branch ${LIBDAV1D} \
    https://code.videolan.org/videolan/dav1d \
    /tmp/libdav1d
RUN \
  echo "**** compiling libdav1d ****" && \
  mkdir -p /tmp/libdav1d/build && \
  cd /tmp/libdav1d/build && \
  meson setup .. && \
  ninja install
RUN \
  echo "**** grabbing libgl ****" && \
  mkdir -p /tmp/libgl && \
  curl -Lf \
  https://gitlab.freedesktop.org/glvnd/libglvnd/-/archive/v${LIBGL}/libglvnd-v${LIBGL}.tar.gz | \
    tar -xz --strip-components=1 -C /tmp/libgl
RUN \
  echo "**** compiling libgl ****" && \
  cd /tmp/libgl && \
  meson setup \
    --buildtype=release \
    build && \
  ninja -C build install && \
  strip -d \
    /usr/local/lib/x86_64-linux-gnu/libEGL.so \
    /usr/local/lib/x86_64-linux-gnu/libGLdispatch.so \
    /usr/local/lib/x86_64-linux-gnu/libGLESv1_CM.so \
    /usr/local/lib/x86_64-linux-gnu/libGLESv2.so \
    /usr/local/lib/x86_64-linux-gnu/libGL.so \
    /usr/local/lib/x86_64-linux-gnu/libGLX.so \
    /usr/local/lib/x86_64-linux-gnu/libOpenGL.so
RUN \
  echo "**** grabbing libdrm ****" && \
  mkdir -p /tmp/libdrm && \
  curl -Lf \
    https://dri.freedesktop.org/libdrm/libdrm-${LIBDRM}.tar.xz | \
    tar -xJ --strip-components=1 -C /tmp/libdrm
RUN \
  echo "**** compiling libdrm ****" && \
  cd /tmp/libdrm && \
  meson setup \
    --prefix=/usr --libdir=/usr/local/lib/x86_64-linux-gnu \
    -Dvalgrind=disabled \
    . build && \
  ninja -C build && \
  ninja -C build install && \
  strip -d /usr/local/lib/x86_64-linux-gnu/libdrm*.so
RUN \
  echo "**** grabbing liblc3 ****" && \
  mkdir -p /tmp/liblc3 && \
  git clone \
    --branch v${LIBLC3} \
    --depth 1 \
    https://github.com/google/liblc3.git \
    /tmp/liblc3
RUN \
    echo "**** compiling liblc3 ****" && \
    cd /tmp/liblc3 && \
    meson setup build && \
    meson install -C build --strip
RUN \
  echo "**** grabbing libva ****" && \
  mkdir -p /tmp/libva && \
  curl -Lf \
    https://github.com/intel/libva/archive/${LIBVA}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/libva
RUN \
  echo "**** compiling libva ****" && \
  cd /tmp/libva && \
  ./autogen.sh && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install && \
  strip -d \
    /usr/local/lib/libva.so \
    /usr/local/lib/libva-drm.so \
    /usr/local/lib/libva-glx.so \
    /usr/local/lib/libva-wayland.so \
    /usr/local/lib/libva-x11.so
RUN \
  echo "**** grabbing libvdpau ****" && \
  mkdir -p /tmp/libvdpau && \
  git clone \
    --branch ${LIBVDPAU} \
    --depth 1 https://gitlab.freedesktop.org/vdpau/libvdpau.git \
    /tmp/libvdpau
RUN \
  echo "**** compiling libvdpau ****" && \
  cd /tmp/libvdpau && \
  meson setup \
    --prefix=/usr --libdir=/usr/local/lib \
    -Ddocumentation=false \
    build && \
  ninja -C build install && \
  strip -d /usr/local/lib/libvdpau.so
RUN \
    echo "**** grabbing shaderc ****" && \
    mkdir -p /tmp/shaderc && \
    git clone \
      --branch ${SHADERC} \
      --depth 1 https://github.com/google/shaderc.git \
      /tmp/shaderc
RUN \
    echo "**** compiling shaderc ****" && \
    cd /tmp/shaderc && \
    ./utils/git-sync-deps && \
    mkdir -p build && \
    cd build && \
    cmake -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      .. && \
    ninja install
RUN \
  echo "**** grabbing mesa ****" && \
  mkdir -p /tmp/mesa && \
  curl -Lf \
    https://archive.mesa3d.org/mesa-${MESA}.tar.xz | \
    tar -xJ --strip-components=1 -C /tmp/mesa
RUN \
  echo "**** compiling mesa ****" && \
  cd /tmp/mesa && \
  meson setup \
    -Dprefix="/usr/local" \
    -Dbuildtype=release \
    -Dvideo-codecs=all \
    builddir/ && \
  meson compile -C builddir/ && \
  meson install -C builddir/
RUN \
  echo "**** grabbing gmmlib ****" && \
  mkdir -p /tmp/gmmlib && \
  curl -Lf \
    https://github.com/intel/gmmlib/archive/refs/tags/intel-gmmlib-${GMMLIB}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/gmmlib
RUN \
  echo "**** compiling gmmlib ****" && \
  mkdir -p /tmp/gmmlib/build && \
  cd /tmp/gmmlib/build && \
  cmake \
    -DCMAKE_BUILD_TYPE=Release \
    .. && \
  make && \
  make install && \
  strip -d /usr/local/lib/libigdgmm.so
RUN \
  echo "**** grabbing IHD ****" && \
  mkdir -p /tmp/ihd && \
  curl -Lf \
    https://github.com/intel/media-driver/archive/refs/tags/intel-media-${IHD}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/ihd
RUN \
  echo "**** compiling IHD ****" && \
  mkdir -p /tmp/ihd/build && \
  cd /tmp/ihd/build && \
  cmake \
    -DLIBVA_DRIVERS_PATH=/usr/local/lib/x86_64-linux-gnu/dri/ \
    .. && \
  make && \
  make install && \
  strip -d /usr/local/lib/x86_64-linux-gnu/dri/iHD_drv_video.so
RUN \
  echo "**** grabbing libvpl ****" && \
  mkdir -p /tmp/libvpl && \
  curl -Lf \
    https://github.com/intel/libvpl/archive/refs/tags/v${LIBVPL}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/libvpl
RUN \
  echo "**** compiling libvpl ****" && \
  mkdir -p /tmp/libvpl/build && \
  cd /tmp/libvpl/build && \
  cmake .. && \
  cmake --build . --config Release && \
  cmake --build . --config Release --target install && \
  strip -d /usr/local/lib/libvpl.so
RUN \
  echo "**** grabbing vpl-gpu-rt ****" && \
  mkdir -p /tmp/vpl-gpu-rt && \
  curl -Lf \
    https://github.com/intel/vpl-gpu-rt/archive/refs/tags/intel-onevpl-${VPLGPURT}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/vpl-gpu-rt
RUN \
  echo "**** compiling vpl-gpu-rt ****" && \
  mkdir -p /tmp/vpl-gpu-rt/build && \
  cd /tmp/vpl-gpu-rt/build && \
  cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=/usr/local/lib \
    .. && \
  make && \
  make install && \
  strip -d /usr/local/lib/libmfx-gen.so
RUN \
  echo "**** grabbing libmfx ****" && \
  mkdir -p /tmp/libmfx && \
  curl -Lf \
    https://github.com/Intel-Media-SDK/MediaSDK/archive/refs/tags/intel-mediasdk-${LIBMFX}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/libmfx
RUN \
  echo "**** compiling libmfx ****" && \
  mkdir -p /tmp/libmfx/build && \
  cd /tmp/libmfx/build && \
  cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=/usr/local/lib \
    -DBUILD_SAMPLES=OFF \
    -DENABLE_X11_DRI3=ON \
    -DBUILD_DISPATCHER=OFF \
    -DBUILD_TUTORIALS=OFF \
    .. && \
  make && \
  make install && \
  strip -d \
    /usr/local/lib/libmfxhw64.so \
    /usr/local/lib/mfx/libmfx_*.so
RUN \
  echo "**** grabbing vmaf ****" && \
  mkdir -p /tmp/vmaf && \
  curl -Lf \
    https://github.com/Netflix/vmaf/archive/refs/tags/v${LIBVMAF}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/vmaf
RUN \
  echo "**** compiling libvmaf ****" && \
  cd /tmp/vmaf/libvmaf && \
  meson setup \
    --prefix=/usr --libdir=/usr/local/lib \
    --buildtype release \
    build && \
  ninja -vC build && \
  ninja -vC build install
RUN \
  echo "**** grabbing ogg ****" && \
  mkdir -p /tmp/ogg && \
  curl -Lf \
    http://downloads.xiph.org/releases/ogg/libogg-${OGG}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/ogg
RUN \
  echo "**** compiling ogg ****" && \
  cd /tmp/ogg && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing opencore-amr ****" && \
  mkdir -p /tmp/opencore-amr && \
  curl -Lf \
    http://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-${OPENCOREAMR}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/opencore-amr
RUN \
  echo "**** compiling opencore-amr ****" && \
  cd /tmp/opencore-amr && \
  ./configure \
    --disable-static \
    --enable-shared  && \
  make && \
  make install && \
  strip -d /usr/local/lib/libopencore-amr*.so
RUN \
  echo "**** grabbing openjpeg ****" && \
  mkdir -p /tmp/openjpeg && \
  curl -Lf \
    https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/openjpeg
RUN \
  echo "**** compiling openjpeg ****" && \
  cd /tmp/openjpeg && \
  rm -Rf \
    thirdparty/libpng/* && \
  curl -Lf \
    https://download.sourceforge.net/libpng/libpng-${LIBPNG}.tar.gz | \
    tar -zx --strip-components=1 -C thirdparty/libpng/ && \
  cmake \
    -DBUILD_STATIC_LIBS=0 \
    -DBUILD_THIRDPARTY:BOOL=ON . && \
  make && \
  make install
RUN \
  echo "**** grabbing opus ****" && \
  mkdir -p /tmp/opus && \
  curl -Lf \
    https://downloads.xiph.org/releases/opus/opus-${OPUS}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/opus
RUN \
  echo "**** compiling opus ****" && \
  cd /tmp/opus && \
  autoreconf -fiv && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install && \
  strip -d /usr/local/lib/libopus.so
RUN \
  echo "**** grabbing rav1e ****" && \
  mkdir -p /tmp/rav1e && \
  git clone \
    --branch v${RAV1E} \
    https://github.com/xiph/rav1e.git \
    /tmp/rav1e
RUN \
  echo "**** compiling rav1e ****" && \
  cd /tmp/rav1e && \
  cargo cinstall --release && \
  strip -d /usr/local/lib/x86_64-linux-gnu/librav1e.so
RUN \
  echo "**** grabbing libdovi ****" && \
  mkdir -p /tmp/libdovi && \
  git clone \
    --branch ${LIBDOVI} \
    https://github.com/quietvoid/dovi_tool.git \
    /tmp/libdovi
RUN \
  echo "**** compiling libdovi ****" && \
  cd /tmp/libdovi/dolby_vision && \
  cargo cinstall --release && \
  strip -d /usr/local/lib/x86_64-linux-gnu/libdovi.so
RUN \
  echo "**** grabbing libplacebo ****" && \
  mkdir -p /tmp/libplacebo && \
  git clone \
    --branch v${LIBPLACEBO} \
    --recursive https://code.videolan.org/videolan/libplacebo \
    /tmp/libplacebo
RUN \
  echo "**** compiling libplacebo ****" && \
  cd /tmp/libplacebo && \
  meson build --buildtype release && \
  ninja -C build install
RUN \
  echo "**** grabbing rist ****" && \
  mkdir -p /tmp/rist && \
  git clone \
    --branch v${RIST} \
    --depth 1 https://code.videolan.org/rist/librist.git \
    /tmp/rist
RUN \
  echo "**** compiling rist ****" && \
  cd /tmp/rist && \
  mkdir -p \
    rist_build && \
  cd rist_build && \
  meson setup \
    --default-library=shared .. && \
  ninja && \
  ninja install && \
  strip -d /usr/local/lib/librist.so
RUN \
  echo "**** grabbing srt ****" && \
  mkdir -p /tmp/srt && \
  git clone \
    --branch v${SRT} \
    --depth 1 https://github.com/Haivision/srt.git \
    /tmp/srt
RUN \
  echo "**** compiling srt ****" && \
  cd /tmp/srt && \
  mkdir -p \
    srt_build && \
  cd srt_build && \
  cmake \
    -DBUILD_SHARED_LIBS:BOOL=on .. && \
  make && \
  make install && \
  strip -d /usr/local/lib/libsrt.so
RUN \
  echo "**** grabbing SVT-AV1 ****" && \
  mkdir -p /tmp/svt-av1 && \
  curl -Lf \
    https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v${SVTAV1}/SVT-AV1-v${SVTAV1}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/svt-av1
RUN \
  echo "**** compiling SVT-AV1 ****" && \
  cd /tmp/svt-av1/Build && \
  cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release && \
  make && \
  make install
RUN \
  echo "**** grabbing theora ****" && \
  mkdir -p /tmp/theora && \
  curl -Lf \
    http://downloads.xiph.org/releases/theora/libtheora-${THEORA}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/theora
RUN \
  echo "**** compiling theora ****" && \
  cd /tmp/theora && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing vid.stab ****" && \
  mkdir -p /tmp/vid.stab && \
  curl -Lf \
    https://github.com/georgmartius/vid.stab/archive/v${LIBVIDSTAB}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/vid.stab
RUN \
  echo "**** compiling vid.stab ****" && \
  cd /tmp/vid.stab && \
  cmake \
    -DBUILD_STATIC_LIBS=0 . && \
  make && \
  make install
RUN \
  echo "**** grabbing vorbis ****" && \
  mkdir -p /tmp/vorbis && \
  curl -Lf \
    http://downloads.xiph.org/releases/vorbis/libvorbis-${VORBIS}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/vorbis
RUN \
  echo "**** compiling vorbis ****" && \
  cd /tmp/vorbis && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing vpx ****" && \
  mkdir -p /tmp/vpx && \
  curl -Lf \
  https://github.com/webmproject/libvpx/archive/v${VPX}.tar.gz | \
  tar -zx --strip-components=1 -C /tmp/vpx
RUN \
  echo "**** compiling vpx ****" && \
  cd /tmp/vpx && \
  ./configure \
    --disable-debug \
    --disable-docs \
    --disable-examples \
    --disable-install-bins \
    --disable-static \
    --disable-unit-tests \
    --enable-pic \
    --enable-shared \
    --enable-vp8 \
    --enable-vp9 \
    --enable-vp9-highbitdepth && \
  make && \
  make install
RUN \
  echo "**** grabbing vulkan headers ****" && \
  mkdir -p /tmp/vulkan-headers && \
  git clone \
    --branch ${VULKANSDK} \
    --depth 1 https://github.com/KhronosGroup/Vulkan-Headers.git \
    /tmp/vulkan-headers
RUN \
  echo "**** compiling vulkan headers ****" && \
  cd /tmp/vulkan-headers && \
  cmake -S . -B build/ && \
  cmake --install build --prefix /usr/local
RUN \
  echo "**** grabbing vulkan loader ****" && \
  mkdir -p /tmp/vulkan-loader && \
  git clone \
    --branch ${VULKANSDK} \
    --depth 1 https://github.com/KhronosGroup/Vulkan-Loader.git \
    /tmp/vulkan-loader
RUN \
  echo "**** compiling vulkan loader ****" && \
  cd /tmp/vulkan-loader && \
  mkdir -p build && \
  cd build && \
  cmake \
    -D CMAKE_BUILD_TYPE=Release \
    -D VULKAN_HEADERS_INSTALL_DIR=/usr/local/lib/x86_64-linux-gnu \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    .. && \
  make && \
  make install
RUN \
  echo "**** grabbing vvenc ****" && \
  mkdir -p /tmp/vvenc && \
  git clone \
    --branch v${VVENC} \
    --depth 1 https://github.com/fraunhoferhhi/vvenc.git \
    /tmp/vvenc
RUN \
  echo "**** compiling vvenc ****" && \
  cd /tmp/vvenc && \
  make install install-prefix=/usr/local && \
  strip -d /usr/local/lib/libvvenc.so
RUN \
  echo "**** grabbing webp ****" && \
  mkdir -p /tmp/webp && \
  curl -Lf \
    https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${WEBP}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/webp
RUN \
  echo "**** compiling webp ****" && \
  cd /tmp/webp && \
  ./configure && \
  make && \
  make install && \
  strip -d /usr/local/lib/libweb*.so
RUN \
  echo "**** grabbing x264 ****" && \
  mkdir -p /tmp/x264 && \
  curl -Lf \
    https://code.videolan.org/videolan/x264/-/archive/master/x264-stable.tar.bz2 | \
    tar -jx --strip-components=1 -C /tmp/x264
RUN \
  echo "**** compiling x264 ****" && \
  cd /tmp/x264 && \
  ./configure \
    --disable-cli \
    --disable-static \
    --enable-pic \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing x265 ****" && \
  mkdir -p /tmp/x265 && \
  curl -Lf \
    https://bitbucket.org/multicoreware/x265_git/downloads/x265_${X265}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/x265
RUN \
  echo "**** compiling x265 ****" && \
  cd /tmp/x265/build/linux && \
  ./multilib.sh && \
  make -C 8bit install
RUN \
  echo "**** grabbing xvid ****" && \
  mkdir -p /tmp/xvid && \
  curl -Lf \
    https://downloads.xvid.com/downloads/xvidcore-${XVID}.tar.gz | \
    tar -zx --strip-components=1 -C /tmp/xvid
RUN \
  echo "**** compiling xvid ****" && \
  cd /tmp/xvid/build/generic && \
  ./configure && \
  make && \
  make install
RUN \
  echo "**** grabbing zimg ****" && \
  mkdir -p /tmp/zimg && \
  git clone \
    --branch release-${ZIMG} --depth 1 \
    https://github.com/sekrit-twc/zimg.git \
    /tmp/zimg
RUN \
  echo "**** compiling zimg ****" && \
  cd /tmp/zimg && \
  ./autogen.sh && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install
RUN \
  echo "**** grabbing zmq ****" && \
  mkdir -p /tmp/zmq && \
  git clone \
    --branch ${ZMQ} --depth 1 \
    https://github.com/zeromq/libzmq.git \
    /tmp/zmq
RUN \
  echo "**** compiling zmq ****" && \
  cd /tmp/zmq && \
  ./autogen.sh && \
  ./configure \
    --disable-static \
    --enable-shared && \
  make && \
  make install-strip

# main ffmpeg build
RUN \
  echo "**** Versioning ****" && \
  if [ -z ${FFMPEG_VERSION+x} ]; then \
    FFMPEG=${FFMPEG_HARD}; \
  else \
    FFMPEG=${FFMPEG_VERSION%-cli}; \
  fi && \
  echo "**** grabbing ffmpeg ****" && \
  mkdir -p /tmp/ffmpeg && \
  echo "https://ffmpeg.org/releases/ffmpeg-${FFMPEG}.tar.bz2" && \
  curl -Lf \
    https://ffmpeg.org/releases/ffmpeg-${FFMPEG}.tar.bz2 | \
    tar -jx --strip-components=1 -C /tmp/ffmpeg

RUN \
  echo "**** compiling ffmpeg ****" && \
  cd /tmp/ffmpeg && \
  ./configure \
    --disable-debug \
    --disable-doc \
    --disable-ffplay \
    --enable-alsa \
    --enable-cuda-llvm \
    --enable-cuvid \
    --enable-ffprobe \
    --enable-gpl \
    --enable-libaom \
    --enable-libass \
    --enable-libdav1d \
    --enable-libfdk_aac \
    --enable-libfontconfig \
    --enable-libfreetype \
    --enable-libfribidi \
    --enable-libharfbuzz \
    --enable-libkvazaar \
    --enable-liblc3 \
    --enable-libmp3lame \
    --enable-libopencore-amrnb \
    --enable-libopencore-amrwb \
    --enable-libopenjpeg \
    --enable-libopus \
    --enable-libplacebo \
    --enable-librav1e \
    --enable-librist \
    --enable-libshaderc \
    --enable-libsrt \
    --enable-libsvtav1 \
    --enable-libtheora \
    --enable-libv4l2 \
    --enable-libvidstab \
    --enable-libvmaf \
    --enable-libvorbis \
    --enable-libvpl \
    --enable-libvpx \
    --enable-libvvenc \
    --enable-libwebp \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libxml2 \
    --enable-libxvid \
    --enable-libzimg \
    --enable-libzmq \
    --enable-nonfree \
    --enable-nvdec \
    --enable-nvenc \
    --enable-opencl \
    --enable-openssl \
    --enable-stripping \
    --enable-vaapi \
    --enable-vdpau \
    --enable-version3 \
    --enable-vulkan \
    && \
  make

RUN \
  echo "**** arrange files ****" && \
  /usr/local/lib/rustlib/uninstall.sh && \
  ldconfig && \
  mkdir -p \
    /buildout/usr/local/bin \
    /buildout/usr/local/etc/fonts \
    /buildout/usr/local/lib/libmfx-gen \
    /buildout/usr/local/lib/mfx \
    /buildout/usr/local/lib/x86_64-linux-gnu/dri \
    /buildout/usr/local/lib/x86_64-linux-gnu/vdpau \
    /buildout/usr/local/share/vulkan \
    /buildout/usr/share/fonts \
    /buildout/usr/share/libdrm \
    /buildout/etc/OpenCL/vendors && \
  cp \
    /tmp/ffmpeg/ffmpeg \
    /buildout/usr/local/bin && \
  cp \
    /tmp/ffmpeg/ffprobe \
    /buildout/usr/local/bin && \
  cp -a \
    /usr/local/etc/fonts/* \
    /buildout/usr/local/etc/fonts/ && \
  cp -a \
    /usr/local/lib/lib*so* \
    /buildout/usr/local/lib/ && \
  cp -a \
    /usr/local/lib/libmfx-gen/*.so \
    /buildout/usr/local/lib/libmfx-gen/ && \
  cp -a \
    /usr/local/lib/mfx/*.so \
    /buildout/usr/local/lib/mfx/ && \
  cp -a \
    /usr/local/lib/x86_64-linux-gnu/lib*so* \
    /buildout/usr/local/lib/x86_64-linux-gnu/ && \
  cp -a \
    /usr/local/lib/x86_64-linux-gnu/dri/*.so \
    /buildout/usr/local/lib/x86_64-linux-gnu/dri/ && \
  cp -a \
    /usr/local/lib/x86_64-linux-gnu/vdpau/*.so \
    /buildout/usr/local/lib/x86_64-linux-gnu/vdpau/ && \
  cp -a \
    /usr/lib/x86_64-linux-gnu/dri/i965* \
    /buildout/usr/local/lib/x86_64-linux-gnu/dri/ && \
  cp -a \
    /usr/share/libdrm/amdgpu.ids \
    /buildout/usr/share/libdrm/ && \
  cp -a \
    /usr/share/fonts/* \
    /buildout/usr/share/fonts/ && \
  cp -a \
    /usr/local/share/vulkan/* \
    /buildout/usr/local/share/vulkan/ && \
  echo \
    'libnvidia-opencl.so.1' > \
    /buildout/etc/OpenCL/vendors/nvidia.icd

# runtime stage
FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

# Add files from binstage
COPY --from=buildstage /buildout/ /

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

ARG DEBIAN_FRONTEND="noninteractive"

# hardware env
ENV \
  LIBVA_DRIVERS_PATH="/usr/local/lib/x86_64-linux-gnu/dri" \
  LD_LIBRARY_PATH="/usr/local/lib" \
  NVIDIA_DRIVER_CAPABILITIES="compute,video,utility" \
  NVIDIA_VISIBLE_DEVICES="all"

RUN \
  echo "**** install runtime ****" && \
    apt-get update && \
    apt-get install -y \
    libasound2t64 \
    libedit2 \
    libelf1 \
    libexpat1 \
    libglib2.0-0 \
    libgomp1 \
    libllvm18 \
    libpciaccess0 \
    libv4l-0 \
    libwayland-client0 \
    libx11-6 \
    libx11-xcb1 \
    libxcb-dri2-0 \
    libxcb-dri3-0 \
    libxcb-present0 \
    libxcb-randr0 \
    libxcb-shape0 \
    libxcb-shm0 \
    libxcb-sync1 \
    libxcb-xfixes0 \
    libxcb1 \
    libxext6 \
    libxfixes3 \
    libxshmfence1 \
    libxml2 \
    ocl-icd-libopencl1 && \
  echo "**** clean up ****" && \
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* && \
  echo "**** quick test ffmpeg ****" && \
  ldd /usr/local/bin/ffmpeg && \
  /usr/local/bin/ffmpeg -version

COPY /root /

ENTRYPOINT ["/ffmpegwrapper.sh"]
