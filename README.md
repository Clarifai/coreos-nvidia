# coreos-nvidia
Simplified building of NVIDIA drivers for CoreOS Linux

This set of scripts will cross-build a given version of NVIDIA drivers for a
given version of CoreOS. It does so by running the build inside the developer
container image associated with the OS version, i.e. using the same compiler
toolchain and kernel configuration used by the system. The scripts can be
started from a machine running _any_ kind of Linux distribution: it
**doesn't** have to be CoreOS.

## Requirements:

 - any Linux distribution
 - `systemd-nspawn` (tested on version 229, there might be issues with <= 225)
 - `sudo`, to run `systemd-nspawn`
 - `curl`
 - `bzip2` and `bunzip2`
 - about 4GB of scratch disk space, most of it taken by the uncompressed
   developer image

## Usage:

<tt><a href="build.sh">build.sh</a> [--keep] DRIVER_VERSION [CHANNEL] [COREOS_VERSION]</tt>

e.g.

`./build.sh 367.27 alpha 1097.0.0`

The scripts will download both the official NVIDIA archive and the CoreOS
developer images, caching them afterwards. If you pass the `--keep` flag, the
temporary container used for building will be preserved after the run; this is
helpful for debugging purposes. The scripts will then create three archives:

```
libraries-[DRIVER_VERSION].tar.bz2
libraries-tls-[DRIVER_VERSION].tar.bz2
tools-[DRIVER_VERSION].tar.bz2
modules-[COREOS_VERSION]-[DRIVER_VERSION].tar.bz2
```

Getting the libraries, tools and modules onto final systems, as well as creating
device nodes under `/dev/`, depends a lot on their particular provisioning
(cloud-config, Ansible, etc.), so it is left as an exercise to the reader. A few
tips:

- on CoreOS, `/lib64/`, `/usr/lib64/` and co. all reside on a read-only
filesystem. You might need to create a new directory elsewhere and its location
listed in a file under `/etc/ld.so.conf.d/`
- depending on your intepretation of [FHS
specifications](http://refspecs.linuxfoundation.org/fhs.shtml), directories
under `/opt/` or `/srv/` might be an option. `/opt/bin/` is already in users'
search path, the `PATH` variable.

## Automating driver builds for new OS releases

Another script, <tt><a href="check.sh">check.sh</a></tt>, can be run as a cron
job to automatically build drivers for new versions of CoreOS as they get
released.

### Usage

`./check.sh DRIVER_VERSION COREOS_CHANNELS`

where `COREOS_CHANNELS` defaults to `"alpha beta stable"`. Example:

`./check.sh 367.27 "beta stable"`

The first time, it will build drivers for the most recent release of each given
channel. Upon subsequent invocations, it will build only newer releases it
hasn't built before — and still only the most recent one per channel. The script
expects to live in a writable directory which is persisted across runs and
includes the other scripts.
