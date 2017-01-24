#!/bin/sh

# Default: use binary packages instead of building everything from source
EMERGE_SOURCE_FLAGS=gK
while :; do
  case $1 in
    --emerge-sources)
      EMERGE_SOURCE_FLAGS=
      ;;
    *)
      break
  esac
  shift
done


VERSION=$1
echo Building ${VERSION}

function finish {
  cat /nvidia_installers/NVIDIA-Linux-x86_64-${VERSION}/nvidia-installer.log
}

set -e
trap finish exit

emerge-gitclone
. /usr/share/coreos/release
git -C /var/lib/portage/coreos-overlay checkout build-${COREOS_RELEASE_VERSION%%.*}
emerge -${EMERGE_SOURCE_FLAGS}q --jobs 4 --load-average 4 coreos-sources

cd /usr/src/linux
cp /lib/modules/*-coreos*/build/.config .config

make olddefconfig
make modules_prepare

cd /nvidia_installers/NVIDIA-Linux-x86_64-${VERSION}
./nvidia-installer -s -n --kernel-source-path=/usr/src/linux \
  --no-check-for-alternate-installs --no-opengl-files \
  --kernel-install-path=${PWD} --log-file-name=${PWD}/nvidia-installer.log
