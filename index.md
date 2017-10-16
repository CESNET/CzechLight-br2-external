# How to use this

This repository contains CzechLight-specific bits for [Buildroot](https://buildroot.org/).
Buildroot is a tool which produces system images for flashing to embedded devices.
They have a [nice documentation](http://nightly.buildroot.org/manual.html) which explains everything that one might need.

## Quick Start

Everything is in Gerrit.
One should not need to clone anything from anywhere else.
The build will download source tarballs of various open source components, though.
The following branches are required:

| Project | branch |
|---------|:------:|
| [github/buildroot/buildroot](https://gerrit.cesnet.cz/plugins/gitiles/github/buildroot/buildroot/) | `cesnet/cla-6` |
| [CzechLight/br2-external](https://gerrit.cesnet.cz/plugins/gitiles/CzechLight/br2-external/) | `master` |

Our SW uses several open-source projects which are special snowflakes and which are integrated by the CI due to their tight coupling:

* [`libredblack`](https://gerrit.cesnet.cz/plugins/gitiles/github/sysrepo/libredblack/)
* [`libyang`](https://gerrit.cesnet.cz/plugins/gitiles/github/CESNET/libyang/)
* [`sysrepo`](https://gerrit.cesnet.cz/plugins/gitiles/github/sysrepo/sysrepo/)
* [`cla-sysrepo`](https://gerrit.cesnet.cz/plugins/gitiles/CzechLight/cla-sysrepo/)
* [`libnetconf2`](https://gerrit.cesnet.cz/plugins/gitiles/github/CESNET/libnetconf2/)
* Netopeer2's [`keystored`](https://gerrit.cesnet.cz/plugins/gitiles/github/CESNET/Netopeer2/+/master/keystored/)
* [`Netopeer2-server`](https://gerrit.cesnet.cz/plugins/gitiles/github/CESNET/Netopeer2/+/master/server/)

TODO: Can we use git submodules instead of this madness?
Will that work reasonably well for changes that need to be made in a lockstep?

The commit hashes (SHA1s) of the required versions are [stored in git](https://gerrit.cesnet.cz/plugins/gitiles/CzechLight/cla-sysrepo/+/master/ci/versions.sh).
All of these projects have to be checked out and made available to Buildroot via a `local.mk` file in the build dir:

```sh
#DOCOPT_CPP_OVERRIDE_SRCDIR = /home/cesnet/gerrit/github/docopt/docopt.cpp
#SPDLOG_OVERRIDE_SRCDIR = /home/cesnet/gerrit/github/gabime/spdlog
LIBYANG_OVERRIDE_SRCDIR = /home/cesnet/gerrit/github/CESNET/libyang
SYSREPO_OVERRIDE_SRCDIR = /home/cesnet/gerrit/github/sysrepo/sysrepo
LIBNETCONF2_OVERRIDE_SRCDIR = /home/cesnet/gerrit/github/CESNET/libnetconf2
NETOPEER2_KEYSTORED_OVERRIDE_SRCDIR = /home/cesnet/gerrit/github/CESNET/Netopeer2
NETOPEER2_SERVER_OVERRIDE_SRCDIR = /home/cesnet/gerrit/github/CESNET/Netopeer2
NETOPEER2_CLI_OVERRIDE_SRCDIR = /home/cesnet/gerrit/github/CESNET/Netopeer2
CLA_SYSREPO_OVERRIDE_SRCDIR = /home/cesnet/gerrit/CzechLight/cla-sysrepo
```

This `local.mk` instructs Buildroot to skip download of these critical packages from the Internet.
Their sources will be used as-is from these source directories.
No patches will be applied!


```
$ mkdir build-for-clearfog
$ cd build-for-clearfog
$ vim local.mk
# ...edit as shown above...
$ make O=$PWD -C /home/cesnet/gerrit/github/buildroot/buildroot \
  BR2_EXTERNAL=/home/cesnet/gerrit/CzechLight/br2-external \
  czechlight_clearfog_defconfig
$ make
```

A full rebuild takes between 30 and 45 minutes on a T460s laptop for targets which use a pre-generated Linaro toolchain (`clearfog`, `beaglebone`).
Other targets take longer because one has to build a toolchain first.
When the build finishes, the generated image to be `dd`-ed to an SD card is at `images/sdcard.img`.

WARNING: Buildroot is fragile.
It is *not* safe to perform incremental builds after changing an "important" setting.
Please check their manual for details.
Using `ccache` might help, but a significant time is wasted in `configure` steps which are not parallelized :( as of October 2017.
