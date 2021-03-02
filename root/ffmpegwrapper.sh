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
    /usr/local/bin/ffmpeg "${FULL_ARGS}"
  # we found the input file run as abc
  else
    set_uidgid
    s6-setuidgid abc \
      /usr/local/bin/ffmpeg "${FULL_ARGS}"
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
FILES=$(find /dev/dri -type c -print 2>/dev/null)
for i in $FILES
do
  VIDEO_GID=$(stat -c '%g' "$i")
  if id -G abc | grep -qw "$VIDEO_GID"; then
    touch /groupadd
  else
    if [ ! "${VIDEO_GID}" == '0' ]; then
      VIDEO_NAME=$(getent group "${VIDEO_GID}" | awk -F: '{print $1}')
      if [ -z "${VIDEO_NAME}" ]; then
        VIDEO_NAME="video$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c8)"
        groupadd "$VIDEO_NAME"
        groupmod -g "$VIDEO_GID" "$VIDEO_NAME"
      fi
      usermod -a -G "$VIDEO_NAME" abc
      touch /groupadd
    fi
  fi
done
if [ -n "${FILES}" ] && [ ! -f "/groupadd" ]; then
  usermod -a -G root abc
fi


run_ffmpeg

