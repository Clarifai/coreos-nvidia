#!/bin/bash
#
# Build NVIDIA drivers for a given CoreOS version
#

KEEP_CONTAINER=false
EMERGE_SOURCES=""
while :; do
  case $1 in
    --keep)
      KEEP_CONTAINER=true
      ;;
    --emerge-sources)
      EMERGE_SOURCES=$1
      ;;
    -?*)
      echo Unknown flag $1
      exit 1
      ;;
    *)
      break
  esac
  shift
done

echo "Keeping container around after build: ${KEEP_CONTAINER}"
echo "Additional flags: ${EMERGE_SOURCES}"

COREOS_TRACK_DEFAULT=beta
COREOS_VERSION_DEFAULT=1185.5.0
# If we are on CoreOS by default build for the current CoreOS version
if [[ -f /etc/lsb-release && -f /etc/coreos/update.conf ]]; then
    source /etc/lsb-release
    source /etc/coreos/update.conf
    
    COREOS_TRACK_DEFAULT=$GROUP
    COREOS_VERSION_DEFAULT=$DISTRIB_RELEASE
fi

DRIVER_VERSION=${1:-375.20}
COREOS_TRACK=${2:-$COREOS_TRACK_DEFAULT}
COREOS_VERSION=${3:-$COREOS_VERSION_DEFAULT}

DRIVER_ARCHIVE=NVIDIA-Linux-x86_64-${DRIVER_VERSION}
DRIVER_ARCHIVE_PATH=${PWD}/nvidia_installers/${DRIVER_ARCHIVE}.run
DEV_CONTAINER=coreos_developer_container.bin.${COREOS_VERSION}
WORK_DIR=pkg/run_files/${COREOS_VERSION}
ORIGINAL_DIR=${PWD}

function onerr {
  echo Caught error
  finish
}

function onexit {
  finish
}

function finish {
  if [ "${KEEP_CONTAINER}" != "true" ]
  then
    cd ${ORIGINAL_DIR}
    echo Cleaning up
    sudo rm -Rf ${DEV_CONTAINER} ${WORK_DIR}/${DRIVER_ARCHIVE} tmp
  fi
  exit
}

set -e
trap onerr ERR
trap onexit exit

if [ ! -f ${DEV_CONTAINER} ]
then
  echo Downloading CoreOS ${COREOS_TRACK} developer image ${COREOS_VERSION}
  SITE=${COREOS_TRACK}.release.core-os.net/amd64-usr
  curl -s -L https://${SITE}/${COREOS_VERSION}/coreos_developer_container.bin.bz2 \
    -z ${DEV_CONTAINER}.bz2 \
    -o ${DEV_CONTAINER}.bz2
  echo Decompressing
  bunzip2 -k ${DEV_CONTAINER}.bz2
fi

if [ ! -f ${DRIVER_ARCHIVE_PATH} ]
then
  echo Downloading NVIDIA Linux drivers version ${DRIVER_VERSION}
  mkdir -p nvidia_installers
  SITE=us.download.nvidia.com/XFree86/Linux-x86_64
  curl -s -L http://${SITE}/${DRIVER_VERSION}/${DRIVER_ARCHIVE}.run \
    -z ${DRIVER_ARCHIVE_PATH} \
    -o ${DRIVER_ARCHIVE_PATH}
fi

rm -Rf ${PWD}/tmp
mkdir -p ${PWD}/tmp ${WORK_DIR}
cp -ul ${DRIVER_ARCHIVE_PATH} ${WORK_DIR}

cd ${WORK_DIR}
chmod +x ${DRIVER_ARCHIVE}.run
sudo rm -Rf ./${DRIVER_ARCHIVE}
./${DRIVER_ARCHIVE}.run -x -s
cd ${ORIGINAL_DIR}

# Ignore errors just for nspawn
set +e
trap ":" ERR
sudo systemd-nspawn -i ${DEV_CONTAINER} \
  --bind=${PWD}/_container_build.sh:/build.sh \
  --bind=${PWD}/${WORK_DIR}:/nvidia_installers \
  /bin/bash -x /build.sh ${EMERGE_SOURCES} ${DRIVER_VERSION}
trap onerr ERR
set -e

sudo chown -R ${UID}:${GROUPS[0]} ${PWD}/${WORK_DIR}

bash -x _export.sh ${WORK_DIR}/*-${DRIVER_VERSION} \
  ${DRIVER_VERSION} ${COREOS_VERSION}-${DRIVER_VERSION}
