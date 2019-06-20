#! /bin/bash

FULL_ARGS=$@

set_uidgid () {
  # setup abc based on file perms
  PUID=$(stat -c %u "${INPUT_FILE}")
  PGID=$(stat -c %g "${INPUT_FILE}")
  groupmod -o -g "$PGID" abc
  usermod -o -u "$PUID" abc
}

run_ffmpeg () {
  # we do not have input file or it does not exist on disk just run as root
  if [ -z ${INPUT_FILE+x} ] || [ ! -f "${INPUT_FILE}" ]; then
    /usr/local/bin/ffmpeg ${FULL_ARGS}
  # we found the input file run as abc
  else
    set_uidgid
    s6-setuidgid abc \
      /usr/local/bin/ffmpeg ${FULL_ARGS}
  fi
  exit 0
}

# look for input file value
for i in "$@"
do
  if [ ${KILL+x} ]; then
    INPUT_FILE=$i
    break
  fi
  if [ "$i" == "-i" ]; then
    KILL=1
  fi
done

## hardware support ##
# check for the existence of a video device
if [ -e /dev/dri ]; then
  VIDEO_GID=$(stat -c '%g' /dev/dri/* | grep -v '^0$' | head -n 1)
  # just add abc to root if stuff in dri is root owned
  if [ -z "${VIDEO_GID}" ]; then
    usermod -a -G root abc
    run_ffmpeg
  fi
else
  run_ffmpeg
fi

# check if this GID matches the current abc user
ABCGID=$(getent group abc | awk -F: '{print $3}')
if [ "${ABCGID}" == "${VIDEO_GID}" ]; then
  run_ffmpeg
fi

# check if the GID is taken and swap to 65533
CURRENT=$(getent group ${VIDEO_GID} | awk -F: '{print $1}')
if [ -z "${CURRENT}" ] || [ "${CURRENT}" == 'video' ]; then
  groupmod -g ${VIDEO_GID} video
  usermod -a -G video abc
else
  groupmod -g 65533 ${CURRENT}
  groupmod -g ${VIDEO_GID} video
  usermod -a -G video abc
fi

run_ffmpeg

