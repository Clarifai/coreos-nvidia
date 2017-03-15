#!/bin/bash

if [[ $(uname -r) != *"-coreos-"* ]]; then
    echo "OS is not CoreOS"
    exit 1
fi

COREOS_TRACK_DEFAULT=beta
COREOS_VERSION_DEFAULT=1185.5.0
# If we are on CoreOS by default use the current CoreOS version
if [[ -f /etc/lsb-release && -f /etc/coreos/update.conf ]]; then
    source /etc/lsb-release
    source /etc/coreos/update.conf
    
    COREOS_TRACK_DEFAULT=$GROUP
    COREOS_VERSION_DEFAULT=$DISTRIB_RELEASE
    if [[ $DISTRIB_ID != *"CoreOS"* ]]; then
        echo "Distribution is not CoreOS"
        exit 1
    fi
fi

DRIVER_VERSION=${1:-375.20}
COREOS_TRACK=${2:-$COREOS_TRACK_DEFAULT}
COREOS_VERSION=${3:-$COREOS_VERSION_DEFAULT}

# this is where the modules go
release=$(uname -r)

mkdir -p /opt/lib64/tls 2>/dev/null
mkdir -p /opt/bin 2>/dev/null
ln -sfT lib64 /opt/lib 2>/dev/null
mkdir -p /opt/lib64/modules/$release/video/

tar xvf libraries-$DRIVER_VERSION.tar.bz2 -C /opt/lib64/
tar xvf libraries-tls-$DRIVER_VERSION.tar.bz2 -C /opt/lib64/tls/
tar xvf modules-$COREOS_VERSION-$DRIVER_VERSION.tar.bz2 -C /opt/lib64/modules/$release/video/
tar xvf tools-$DRIVER_VERSION.tar.bz2 -C /opt/bin/

install -m 755 create-uvm-dev-node.sh /opt/bin/
install -m 755 nvidia-start.sh /opt/bin/
install -m 755 nvidia-insmod.sh /opt/bin/
cp -f 71-nvidia.rules /etc/udev/rules.d/
udevadm control --reload-rules

mkdir -p /etc/ld.so.conf.d/ 2>/dev/null
echo "/opt/lib64" > /etc/ld.so.conf.d/nvidia.conf
ldconfig

echo "Configuring nvidia persistence user"
id -u nvidia-persistenced >/dev/null 2>&1 || \
useradd --system --home '/' --shell '/sbin/nologin' -c 'NVIDIA Persistence Daemon' nvidia-persistenced

cp *.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable nvidia-start.service
systemctl start nvidia-start.service
