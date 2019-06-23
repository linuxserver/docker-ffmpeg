FROM lsiobase/ffmpeg:bin as binstage
FROM lsiobase/cloud9:files as c9files
FROM lsiobase/ubuntu:bionic

# Add files from stages
COPY --from=binstage / /
COPY --from=c9files /buildout/ /

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# hardware env
ENV \
 LIBVA_DRIVERS_PATH="/usr/lib/x86_64-linux-gnu/dri" \
 NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

RUN \
 echo "**** install build-deps ffmpeg-web ****" && \
 apt-get update && \
 apt-get install -y \
	python3-pip && \
 echo "**** install runtime ffmpeg-web ****" && \
 apt-get install -y \
        python3 && \
 echo "**** install runtime ffmpeg ****" && \
 apt-get install -y \
	i965-va-driver \
	libexpat1 \
	libgl1-mesa-dri \
	libglib2.0-0 \
	libgomp1 \
	libharfbuzz0b \
	libv4l-0 \
	libx11-6 \
	libxcb1 \
	libxext6 \
	libxml2 && \
 echo "**** install stuff specific to the dev container ****" && \
 apt-get install -y \
	git \
	npm \
	sudo && \
 npm install -g nodemon && \
 echo "**** install web app from git ****" && \
 git clone \
	https://github.com/linuxserver/docker-ffmpeg.git \
	/app/ffmpeg-web && \
 cd /app/ffmpeg-web && \
 git \
	checkout -f web && \
 pip3 install \
	-r requirements.txt && \
 echo "**** permissions ****" && \
 mkdir -p \
	/applogs \
	/c9sdk/build/standalone && \
 chown -R abc:abc \
	/app/ffmpeg-web \
	/applogs \
	/c9sdk/build/standalone \
	/c9bins && \
 usermod -aG sudo \
	abc && \
 chsh abc -s /bin/bash && \
 sed -e '/%sudo/c\%sudo ALL=(ALL:ALL) NOPASSWD: ALL' \
	-i /etc/sudoers && \
 sed -e 's/^wheel:\(.*\)/wheel:\1,abc/g' -i /etc/group && \
 echo "**** clean up ****" && \
 rm -rf \
	/root \
	/var/lib/apt/lists/* \
	/var/tmp/* && \
 mkdir /root

# add local files
COPY /root /

# ports
EXPOSE 8787 8000
