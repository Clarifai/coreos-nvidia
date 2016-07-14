#!/bin/bash

DRIVER_VERSION=${1:-367.27}
COREOS_TRACK=${2:-alpha}
COREOS_VERSION=${3:-1097.0.0}

DRIVER_ARCHIVE=NVIDIA-Linux-x86_64-${DRIVER_VERSION}
DRIVER_ARCHIVE_PATH=${PWD}/nvidia_installers/${DRIVER_ARCHIVE}.run
DEV_CONTAINER=coreos_developer_container.bin.${COREOS_VERSION}
WORK_DIR=pkg/run_files/${COREOS_VERSION}

if [ ! -f ${DEV_CONTAINER} ]
then
  echo Downloading CoreOS developer container image
  curl -s -L https://alpha.release.core-os.net/amd64-usr/${COREOS_VERSION}/coreos_developer_container.bin.bz2 \
    -z ${DEV_CONTAINER}.bz2 \
    -o ${DEV_CONTAINER}.bz2
  echo Decompressing
  bunzip2 -k ${DEV_CONTAINER}.bz2
fi

if [ ! -f ${DRIVER_ARCHIVE_PATH} ]
then
  echo Downloading Linux drivers
  mkdir -p nvidia_installers
  curl -s -L http://us.download.nvidia.com/XFree86/Linux-x86_64/${DRIVER_VERSION}/${DRIVER_ARCHIVE}.run \
    -z ${DRIVER_ARCHIVE_PATH} \
    -o ${DRIVER_ARCHIVE_PATH}
fi

rm -Rf ${PWD}/tmp
mkdir -p ${PWD}/tmp ${WORK_DIR}
cp -ul ${DRIVER_ARCHIVE_PATH} ${WORK_DIR}

pushd ${WORK_DIR}
chmod +x ${DRIVER_ARCHIVE}.run
rm -Rf ./${DRIVER_ARCHIVE}
./${DRIVER_ARCHIVE}.run -x -s
popd

function finish {
 echo
}
trap finish exit

sudo systemd-nspawn -i ${DEV_CONTAINER} --share-system \
     --bind=${PWD}/_container_build.sh:/build.sh --bind=${PWD}/${WORK_DIR}:/nvidia_installers \
     /bin/bash -x /build.sh ${DRIVER_VERSION}

sudo chown -R ${UID}:${GROUPS[0]} ${PWD}/${WORK_DIR}

bash -x _export.sh ${WORK_DIR}/*-${DRIVER_VERSION} ${DRIVER_VERSION} ${COREOS_VERSION}-${DRIVER_VERSION}
