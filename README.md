# How to use this

This repository contains CzechLight-specific bits for [Buildroot](https://buildroot.org/).
Buildroot is a tool which produces system images for flashing to embedded devices.
They have a [nice documentation](http://nightly.buildroot.org/manual.html) which explains everything that one might need.

The [system architecture is described in another document](doc/architecture.md).
This is a quick build HOWTO.

## Quick Start

Everything is in Gerrit.
One should not need to clone anything from anywhere else.
The build will download source tarballs of various open source components, though.

By default, each change of this repo uploaded to Gerrit causes the CI system to produce a firmware update.
On Gerrit, the change will get a comment from Zuul with a link to the CI log server.
Next to the logs, a file named `artifacts/update.raucb` [can be used for updating devices](#updates-via-rauc).

Behind the scenes, the system uses [Zuul](https://zuul-ci.org/docs/zuul/) with a [configuration tracked in git](https://gerrit.cesnet.cz/plugins/gitiles/ci/).

### Developer Workflow

Here's how to reproduce the build on a developer's workstation:

```sh
git clone ssh://$YOUR_LOGIN@cesnet.cz@gerrit.cesnet.cz:29418/CzechLight/br2-external czechlight
pushd czechlight
git submodule update --init --recursive
popd
mkdir build-clearfog
cd build-clearfog
../czechlight/dev-setup-git.sh
make czechlight_clearfog_defconfig
make -j8
```

A full rebuild takes about half an hour on a modern laptop.

WARNING: Buildroot is fragile.
It is *not* safe to perform incremental builds after changing an "important" setting.
Please [check their manual](https://buildroot.org/downloads/manual/manual.html#full-rebuild) for details.

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

# target, perhaps via an USB console or over SSH
rauc install http://somewhere.example.org/update.raucb
reboot
```

Once the updated FW slot boots, the configuration in `/cfg` will be automatically upgraded (["migrated"](doc/architecture.md#yang)) to the newest layout.
A downgrade to an incompatible OS version might therefore fail during the next reboot.
Completely removing all data in the newly updated slot's `cfg` partition will restore functionality, but it is effectively a factory reset.

### Initial installation

#### Clearfog

On a regular Clearfog Base with an eMMC, one has to bootstrap the device first.
If recovering a totally bricked board (or one that is fresh from factory), use the `kwboot` command to upload the initial, new enough U-Boot via the console.
Ensure that the jumpers are set to `0 1 0 0 1` (default for eMMC boot is `0 0 1 1 1`), and then use U-Boot's `kwboot` tool:

```sh
./host/bin/kwboot -b ./u-boot-spl.kwb -t -p /dev/ttyUSB0
```
Prepare a USB flash disk with a raw bootable image, `images/usb-flash.img`.
Use a tool such as `dd` to overwrite the raw block device, do not copy the image file.
Once in U-Boot, plug the USB flash disk and execute:

```sh
usb start; fatload usb 0:1 00800000 boot.scr; source 00800000
```
The system will boot and flash the eMMC from the USB drive.
Once the status LED starts blinking in yellow, data are being transferred to the eMMC.
The light changes to solid yellow in later phases of the flashing process.
Once everything is done, the status LED shows a solid white light and the system reboots automatically.

Turn off power, remove the USB flash, re-jumper the board (`0 0 1 1 1`), power-cycle, and configure MAC addresses at the U-Boot prompt.
The MAC addresses are found on the label at the front panel.

```
=> setenv eth1addr 00:11:17:01:XX:XX
=> setenv eth2addr 00:11:17:01:XX:YY
=> setenv eth3addr 00:11:17:01:XX:ZZ
```

Also set up the system type:

| Model | `czechlight` variable value |
|-------|-----------------------------|
| ROADM Line Degree | `sdn-roadm-line-g2` |
| ROADM Flex Add/Drop | `sdn-roadm-add-drop-g2` |
| ROADM Hi-Res Add/Drop | `sdn-roadm-hires-add-drop-g2` |
| ROADM Coherent Add/Drop | `sdn-roadm-coherent-a-d-g2` |
| Inline Amplifier | `sdn-inline-g2` |
| BiDi Amplifier C-Band + 1572nm | `sdn-bidi-cplus1572-g2` |
| BiDi Amplifier C-Band + 1572nm with OCM | `sdn-bidi-cplus1572-ocm-g2` |

```
=> setenv czechlight sdn-roadm-line-g2
=> saveenv
Saving Environment to MMC... Writing to redundant MMC(0)... OK
=> boot
```

Once the system boots (which currently requires a reboot for some unknown reason -- fsck, perhaps?), configure hostname, plug in the network cable, and update SW:

```console
# hostnamectl set-hostname line-XYZSERIALNO
# cp /etc/hostname /cfg/etc/
# rauc install http://somewhere.example.org/update.raucb
# reboot
```

#### Beaglebone Black

Obtain a reasonable Linux distro image for BBB and flash it to a µSD card.
Unlock eMMC boot partitions (`echo 0 > /sys/class/block/mmcblk1boot0/force_ro; echo 0 > /sys/class/block/mmcblk1boot1/force_ro`).
Clean the eMMC data (`blkdiscard /dev/mmcblk1`).
Flash the content of `images/emmc.img` to device's `/dev/mmcblk1`.
Flash what fits into `/dev/mmcblk1boot0` and `/dev/mmcblk1boot1`.
Fetching the image over web (`python3 -m http.server` and `wget http://...:8000/emmc.img -O - | dd of=/dev/mmcblk1 conv=sparse`) works well.
