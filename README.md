# coreos-nvidia
Automated building of NVIDIA drivers for CoreOS Linux

This set of scripts will build a given version of NVIDIA drivers for a
given version of CoreOS. It does so by running the build inside the
developer container image associated with the OS version, i.e. using the
same compiler toolchain and kernel configuration used by the system.

# Requirements:

 - `systemd-nspawn`
 - `sudo`, to run `systemd-nspawn`
 - `bzip2` and `bunzip2`

# Usage:

`./build.sh DRIVER_VERSION COREOS_TRACK COREOS_VERSION`

e.g.

`./build.sh 367.27 alpha 1097.0.0`

The scripts will download both the official NVIDIA archive and the
CoreOS developer images, caching them afterwards. It will then create
three archives:

```
libraries-[DRIVER_VERSION].tar.bz2
tools-[DRIVER_VERSION].tar.bz2
modules-[COREOS_VERSION]-[DRIVER_VERSION].tar.bz2
```

