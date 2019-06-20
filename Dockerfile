FROM lsiobase/ffmpeg:bin as binstage
FROM lsiobase/alpine:3.9

# Add files from binstage
COPY --from=binstage / /

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# hardware env
ENV \
 LIBVA_DRIVERS_PATH="/usr/lib/dri" \
 NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

RUN \
 echo "**** install packages ****" && \
 apk add --no-cache \
	libgomp \
	libpng \
	libxext \
	libva-intel-driver \
	libxml2 \
	mesa-dri-ati \
	mesa-dri-nouveau \
	mesa-vulkan-ati \
	v4l-utils-libs

COPY /root /

ENTRYPOINT ["/ffmpegwrapper.sh"]
