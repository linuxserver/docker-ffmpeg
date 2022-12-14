#! /bin/bash

FULL_ARGS=( "$@" )

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
    /usr/local/bin/ffmpeg "${FULL_ARGS[@]}"
  # we found the input file run as abc
  else
    set_uidgid
    s6-setuidgid abc \
      /usr/local/bin/ffmpeg "${FULL_ARGS[@]}"
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
FILES=$(find /dev/dri /dev/dvb -type c -print 2>/dev/null)

for i in $FILES
do
    VIDEO_GID=$(stat -c '%g' "${i}")
    VIDEO_UID=$(stat -c '%u' "${i}")
    # check if user matches device
    if id -u abc | grep -qw "${VIDEO_UID}"; then
        echo "**** permissions for ${i} are good ****"
    else
        # check if group matches and that device has group rw
        if id -G abc | grep -qw "${VIDEO_GID}" && [ $(stat -c '%A' "${i}" | cut -b 5,6) = "rw" ]; then
            echo "**** permissions for ${i} are good ****"
        # check if device needs to be added to video group
        elif ! id -G abc | grep -qw "${VIDEO_GID}"; then
            # check if video group needs to be created
            VIDEO_NAME=$(getent group "${VIDEO_GID}" | awk -F: '{print $1}')
            if [ -z "${VIDEO_NAME}" ]; then
                VIDEO_NAME="video$(head /dev/urandom | tr -dc 'a-z0-9' | head -c4)"
                groupadd "${VIDEO_NAME}"
                groupmod -g "${VIDEO_GID}" "${VIDEO_NAME}"
                echo "**** creating video group ${VIDEO_NAME} with id ${VIDEO_GID} ****"
            fi
            echo "**** adding ${i} to video group ${VIDEO_NAME} with id ${VIDEO_GID} ****"
            usermod -a -G "${VIDEO_NAME}" abc
        fi
        # check if device has group rw
        if [ $(stat -c '%A' "${i}" | cut -b 5,6) != "rw" ]; then
            echo -e "**** The device ${i} does not have group read/write permissions, attempting to fix inside the container. ****"
            chmod g+rw "${i}"
        fi
    fi
done

run_ffmpeg
