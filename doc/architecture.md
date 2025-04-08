# System Software Architecture of Czech Light Embedded Linux

These are important "features" or "design decisions" which drove the overall architecture:

- Users are supposed to only interact with these devices via YANG data.
If some functionality is not available through one of enabled models, that's a bug which should be (eventually) fixed.

- Devices are updated in one step.
There are no separate user-visible or individually updateable packages.
There's one software image which drives "the whole device".

- "Nobody" is expected to log in into the system.
SSH connections are supported, but users should not have a local shell.
Remote SSH connection should go to a CLI which manipulates the YANG datastores.

## Configuration

All configuration "should be" stored in sysrepo as YANG-formatted data.
Of course there are still (Q2 2020) exceptions:

- hostname
- timezone
- SSH keys for system accounts
- passwords for direct login, which should not be supported anyway
- ...

### YANG

The system always boots with an empty state -- the sysrepo database is completely empty, with no YANG modules, and no data.
Transforming that into a working system involves installation of several YANG modules.
Some of those modules are device-specific, and some modules might require non-empty default configuration as the *initial data*.
Also, the on-disk configuration that is preserved from the last reboot might need updates in order to apply to the current revisions of YANG modules.
That's why the data preparation/upgrading works purely at the JSON level, with no associated YANG-based tools.

If there is no previous snapshot, or if it comes from an unsupported version (pre-v9), it is discarded and considered to be an empty JSON object.
Then, a series of transformations ("migrations") is applied to the JSON, bumping the "data version" for each of these migrations.
Once done, the resulting JSON is loaded into sysrepo as the initial data.

- the JSON data are migrated by [`cfg-migrate.service`](../package/czechlight-cfg-fs/cfg-migrate.service),
- YANG modules are installed and the data are loaded via [`cfg-yang.service`](../package/czechlight-cfg-fs/cfg-yang.service),
- finally, any daemons that use sysrepo are started.

### Factory data

MAC addresses and some identification data and in future also calibration data.
As of 2020-04, MAC addresses and device type information (`czechlight=...`) are in U-Boot env.
Manufacturer-defined data, such as serial numbers, are in an [EEPROM](eeprom.md).

## Boot Flow

### 1) Early boot:

- Hardware watchdog timer gets activated, and U-Boot starts pinging it.

- U-Boot: there's a [script that determines](../board/czechlight/clearfog/patches/u-boot/boot.patch) what [RAUC slot](https://rauc.readthedocs.io/en/latest/basic.html#target-slot-selection) to use.
This part is supposed to be immutable.
Nothing updates this script as it's hard-embedded into the bootloader, and nothing updates the bootloader in the field because *that* is hard to do in a failsafe manner.

- U-Boot [environment](https://elinux.org/U-boot_environment_variables_in_linux) is marked as "I'm trying to boot an A/B slot now" while keeping track of how many attaempts are remaining.

- Once an A/B boot slot is chosen, another [U-Boot script](../board/czechlight/clearfog/boot.scr.txt) (which is a part of every system release and therefore updateable) changes LED blinking patterns, resets the fan controller, loads the [device tree](https://elinux.org/Device_Tree_Reference) (such as [this one](../board/czechlight/clearfog/sdn-roadm-line-clearfog.dts)) which provides Linux-level device description, and launches the kernel.

### 2) Linux Kernel:

- HW watchdog keeps running, but U-Boot has now ceased its periodic ping.
We have about 90 seconds to start pinging it, otherwise the system reboots once the watchdog fires.

- An [init shell script](../package/czechlight-cfg-fs/init-czechlight.sh) sets up `overlayfs` so that rootfs' `/etc` is writable, but all changes are discarded on reboot.

- Some parts of `/etc` are persistent ([sysrepo configuration in the `startup` datastore](../package/czechlight-cfg-fs/sysrepo-persistent-cfg.service), [SSH keys for local shell](../package/czechlight-cfg-fs/openssh-persistent-keys.service)).
These are copied from `/cfg`, our R/W configuration partition, into their "final" destination.

- Bootup is controlled via systemd and its targets; it's a pretty stock configuration.

### 3) Useful services:

- Some LEDs are [set up from userspace](../package/czechlight-clearfog-leds/)

- The most important service is `netopeer2` which provides a NETCONF server with a YANG data store (on top of `sysrepo`).
There's also `rousette` which pretends that it's a RESTCONF frontend on top of `sysrepo`.

- System management is handled by `velia-*` which bridges the YANG configuration in sysrepo with configuration for, say, `systemd-networkd`, manages user accounts, etc.

- Anything optical is handled by `cla-sysrepod` which contains code that talks to the optical modules.

- There's also a super-basic [web UI](../package/gammarus/) which doesn't do much.
It talks over an anonymous, unathenticated almost-RESTCONF with the system, so this is a frontend only thing.

- Once everything has started up properly (`Requires=multi-user.target` and `After=multi-user.target`), we [mark the current RAUC slot as functional](../package/czechlight-rauc/rauc-mark-good.service), and [instruct systemd to start pinging the HW watchdog](../package/czechlight-rauc/enable-hw-watchdog.service) as the last services to start.

The boot is driven by device information passed from U-Boot via the `czechlight=...` kernel command line parameter.

# Hacks and Development Access

## Root Access

Login as `root` over the serial console (µUSB port at the front panel, serial emulation via an FTDI chip, 115'200 Baud).
On Linux, the command typically looks like `picocom -b 115200 /dev/ttyUSB0`.
There's no password.

### SSH into the System

Unlike the NETCONF access which has its own SSH key store (but uses regular system-wide accounts for UIDs, etc), there's a separate "store" of SSH keys for direct shell access.
Put public keys into `/cfg/ssh-user-auth/$USERNAME` ([configured here](../package/czechlight-cfg-fs/czechlight-cfg-fs.mk)).
This pubkey store supports modifications and querying over the `/czechlight-system:authentication/users` YANG model.

## Debugging, Installing Custom Software, Packages, Utilities, etc

There's no package manager, so it's impossible to install anything.
Buildroot always generates a full filesystem image that can be loaded to a device, for example [via RAUC](../README.md#Updates_via_RAUC).

### Development of on-device software

Buildroot supports [`local.mk` along with `*_OVERRIDE_SRCDIR`](https://buildroot.org/downloads/manual/manual.html#_using_buildroot_during_development).
This is the mechanism that is used to select the specific version of our internal packages (e.g., `cla-sysrepo`) during the [build process via `dev-setup-git.sh`](../README.md#developer-workflow).
Either edit the `local.mk` to point, e.g., `CLA_SYSREPO_OVERRIDE_SRCDIR` to your `cla-sysrepo` checkout, or work in the checkout directly.

### Debugging

Sometimes `/tmp` could be useful for fast prototyping.
Here's how one could be debugging code on device:

```shell-session
user@laptop ~/build/br-cfb $ make cla-sysrepo-reconfigure
user@laptop ~/build/br-cfb $ scp per-package/cla-sysrepo/target/usr/bin/cla-sysrepod root@10.10.10.228:/tmp/
user@laptop ~/build/br-cfb $ ssh root@10.10.10.228 gdbserver :33666 /tmp/cla-sysrepod ...some args here...
user@laptop ~/build/br-cfb $ ./host/usr/bin/arm-linux-gdb \
  per-package/cla-sysrepo/target/usr/bin/cla-sysrepod --ex 'set sysroot target/' \
  --ex 'target remote 10.10.10.228:33666' --ex c
```

The core "NETCONF-related" packages are not stripped, so that some debugging should be possible.
