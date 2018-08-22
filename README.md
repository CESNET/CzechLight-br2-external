# How to use this

This repository contains CzechLight-specific bits for [Buildroot](https://buildroot.org/).
Buildroot is a tool which produces system images for flashing to embedded devices.
They have a [nice documentation](http://nightly.buildroot.org/manual.html) which explains everything that one might need.

## Quick Start

Everything is in Gerrit.
One should not need to clone anything from anywhere else.
The build will download source tarballs of various open source components, though.

TODO: Automate this via the CI system.
I want to get the `.img` files for testing of each change, eventually.

```sh
git clone ssh://$YOUR_LOGIN@cesnet.cz@gerrit.cesnet.cz:29418/CzechLight/br2-external czechlight
pushd czechlight
git submodule update --init --recursive
popd
mkdir build-clearfog
cd build-clearfog
../czechlight/dev-setup-git.sh
make czechlight_clearfog_defconfig
make
```

A full rebuild takes between 30 and 45 minutes on a T460s laptop.

WARNING: Buildroot is fragile.
It is *not* safe to perform incremental builds after changing an "important" setting.
Please check their manual for details.

### Hack: parallel build

A significant amount of time is wasted in `configure` steps which are not parallelized :( as of November 2017.
This can be hacked by patching Buildroot's top-level `Makefile`, but note that one cannot easily debug stuff afterwards.

```diff
diff --git a/Makefile b/Makefile
index 79db7fe..905099a 100644
--- a/Makefile
+++ b/Makefile
@@ -114,7 +114,7 @@ endif
 # this top-level Makefile in parallel comment the ".NOTPARALLEL" line and
 # use the -j<jobs> option when building, e.g:
 #      make -j$((`getconf _NPROCESSORS_ONLN`+1))
-.NOTPARALLEL:
 
 # absolute path
 TOPDIR := $(CURDIR)
```

## Installing

### Updates via RAUC

Apart from the traditional way of re-flashing the SD card or the eMMC from scratch, it's also possible to use RAUC to update.
This method preserves the U-Boot version and the U-Boot's environment.
Apart from that, everything starting with the kernel and the DTB file and including the root FS is updated.
Configuration stored in `/cfg` is brought along and preserved as well.

To install an update:

```sh
# build node
make
rsync -avP images/update.raucb somewhere.example.org:path/to/web/root

# target, perhaps via an USB console
wget http://somewhere.example.org/update.raucb -O /tmp/update.raucb
rauc install /tmp/update.raucb
reboot
```

### Initial installation

#### Clearfog

On development boards with a µSD card slot, simply `dd` the `images/sdcard.img` to the SD card and boot from there.

On a regular Clearfog Base with an eMMC, one has to bootstrap the device first.
If recovering a totally bricked board, one can use the `kwboot` command to upload the initial U-Boot via the console:

```sh
./tools/kwboot -b ./u-boot-spl.kwb -t -p /dev/ttyUSB0
```
Once in U-Boot (a stock factory image is OK as well), plug a USB flash disk which contains `images/usb-flash.img` and execute:

```sh
usb start; fatload usb 0:1 00800000 boot.scr; source 00800000
```
The system will boot and flash the eMMC from the USB drive.
Once the status LED starts blinking in yellow, data are being transferred to the eMMC.
The light changes to solid yellow in later phases of the flashing process.
Once everything is done, the status LED shows a solid white light and the system reboots automatically.
