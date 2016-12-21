#!/bin/bash
#
# Build NVIDIA drivers for a given CoreOS version
#

if [ x"$1" == x"--keep" ]
then
  KEEP_CONTAINER=1
  shift
fi

DRIVER_VERSION=${1:-367.57}
COREOS_TRACK=${2:-beta}
COREOS_VERSION=${3:-1185.5.0}

DRIVER_ARCHIVE=NVIDIA-Linux-x86_64-${DRIVER_VERSION}
DRIVER_ARCHIVE_PATH=${PWD}/nvidia_installers/${DRIVER_ARCHIVE}.run
DEV_CONTAINER=coreos_developer_container.bin.${COREOS_VERSION}
WORK_DIR=pkg/run_files/${COREOS_VERSION}
ORIGINAL_DIR=${PWD}

function finish {
  if [ "${KEEP_CONTAINER}" != "1" ]
  then
    cd ${ORIGINAL_DIR}
    rm -Rf ${DEV_CONTAINER} ${WORK_DIR}/${DRIVER_ARCHIVE} tmp
  fi
}

trap finish exit

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
rm -Rf ./${DRIVER_ARCHIVE}
./${DRIVER_ARCHIVE}.run -x -s
cd ${ORIGINAL_DIR}

sudo systemd-nspawn -i ${DEV_CONTAINER} --share-system \
  --bind=${PWD}/_container_build.sh:/build.sh \
  --bind=${PWD}/${WORK_DIR}:/nvidia_installers \
  /bin/bash -x /build.sh ${DRIVER_VERSION}

sudo chown -R ${UID}:${GROUPS[0]} ${PWD}/${WORK_DIR}

bash -x _export.sh ${WORK_DIR}/*-${DRIVER_VERSION} \
  ${DRIVER_VERSION} ${COREOS_VERSION}-${DRIVER_VERSION}
