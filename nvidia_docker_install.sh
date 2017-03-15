#!/bin/bash

NVIDIA_DOCKER_VERSION=${1:-1.0.1}

if [[ $(uname -r) != *"-coreos-"* ]]; then
    echo "OS is not CoreOS"
    exit 1
fi

wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v${NVIDIA_DOCKER_VERSION}/nvidia-docker_${NVIDIA_DOCKER_VERSION}_amd64.tar.xz
tar --strip-components=1 -C /opt/bin -xvf /tmp/nvidia-docker*.tar.xz && rm /tmp/nvidia-docker*.tar.xz
echo "Setting up permissions"
chown root:root /opt/bin/nvidia-docker*
setcap cap_fowner+pe /opt/bin/nvidia-docker-plugin

echo "Configuring nvidia user"
id -u nvidia-docker >/dev/null 2>&1 || \
useradd -r -M -d /var/lib/nvidia-docker -s /usr/sbin/nologin -c "NVIDIA Docker plugin" nvidia-docker
mkdir -p /var/lib/nvidia-docker 2>/dev/null
chown nvidia-docker: /var/lib/nvidia-docker

systemctl enable nvidia-docker.service
systemctl start nvidia-docker.service
