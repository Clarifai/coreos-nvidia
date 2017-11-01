#!/bin/sh

/opt/bin/nvidia-insmod.sh nvidia.ko

# Start the first devices
/usr/bin/mknod -m 666 /dev/nvidiactl c 195 255 2>/dev/null
/usr/bin/mknod -m 666 /dev/nvidia0 c 195 0 2>/dev/null
