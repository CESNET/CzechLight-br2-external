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

A full rebuild takes between 30 and 45 minutes on a T460s laptop for targets which use a pre-generated Linaro toolchain (`clearfog`, `beaglebone`).
Other targets take longer because one has to build a toolchain first.
When the build finishes, the generated image to be `dd`-ed to an SD card is at `images/sdcard.img`.

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

## Testing build images with `QEMU`

After you build your OS images with Buildroot, you might want to try them
inside a virtual machine before deploying them onto a production hardware.

For example, let's pretend I have used the commands above to successfully
build the `czechlight_epia_geode_defconfig` configuration. Now, I have
a folder called `images`, which contains files like `hdimage.img`, `bzImage`,
`rootfs.ext4` and several others.

### Running `hdimage.img` inside a virtual machine

`hdimage.img` contains complete image of a system, together with the bootloader
and kernel. Therefore, it can be used to launch a virtual machine like this:

```sh
qemu-system-i386 -curses images/hdimage.img
```

New virtual machine will be launched immediately, connected to the terminal
where you entered this command (the `-curses` flag ensures _curses_ will be used
to display "video" output right in the terminal - I prefer this to the default
behaviour, which is to create a new window for the virtual machine).

### Accelerate virtualization with _KVM_, more _RAM_ and _CPUs_

By default, virtual machine gets about 128 MB RAM and 1 CPU. Let's
start another virtual machine, which gets 1024 MB RAM and 4 CPUs!

Moreover, we will make use of KVM (Kernel Virtual Machine) by adding
the `-enable-kvm` switch. Remember, that KVM may not work for all architectures.

```sh
qemu-system-i386 -curses -enable-kvm \
                 -m 1024M -smp 4 \
                 images/hdimage.img
```

### More control over boot process, custom kernel cmdline parameters...

Now, we will use a little different way to boot. This way requires us
to separately specify the kernel image file and the root filesystem file.
The advantage is that we can i. e. append custom parameters to the kernel
command line.

```sh
qemu-system-i386 -nographic \
                 -kernel images/bzImage \
                 -hda images/rootfs.ext4 \
                 -append "root=/dev/sda console=ttyS0" \
                 -m 512M -smp 2 \
                 -enable-kvm
```

This runs virtual machine with it's serial port `ttyS0` attached
to the terminal where we executed the command.

There are hundreds of options for the `qemu-system-i386` command - run
`man qemu-system-i386` to display a very detailed manpage.

## Installing updates to a device

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
