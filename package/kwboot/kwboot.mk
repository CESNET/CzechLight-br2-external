KWBOOT_VERSION = 2024.10
KWBOOT_SOURCE = u-boot-${KWBOOT_VERSION}.tar.bz2
KWBOOT_SITE = ftp://ftp.denx.de/pub/u-boot
KWBOOT_LICENSE = GPL-2.0+
KWBOOT_LICENSE_FILES = Licenses/gpl-2.0.txt
KWBOOT_CPE_ID_VENDOR = denx
KWBOOT_CPE_ID_PRODUCT = u-boot

# Building for host: override everything

HOST_KWBOOT_MAKE_OPTS = \
	NO_PYTHON=1 \
	O=$(@D)/bld \
	CONFIG_TOOLS_MKEFICAPSULE=n \
	CONFIG_TOOLS_MKFWUMDATA=n \
	CONFIG_ARCH_MVEBU=y \
	CROSS_COMPILE="" \
	HOSTCC="$(HOSTCC)" \
	HOSTCFLAGS="$(HOST_CFLAGS)" \
	HOSTLDFLAGS="$(HOST_LDFLAGS)" \
	AR=$(HOSTAR)

HOST_KWBOOT_DEPENDENCIES = $(BR2_MAKE_HOST_DEPENDENCY) \
	host-pkgconf \
	host-openssl \
	host-util-linux

define HOST_KWBOOT_CONFIGURE_CMDS
	$(HOST_MAKE_ENV) $(MAKE) -C $(@D) $(HOST_KWBOOT_MAKE_OPTS) tools-only_defconfig
endef

define HOST_KWBOOT_BUILD_CMDS
	$(HOST_MAKE_ENV) $(MAKE) -C $(@D) $(HOST_KWBOOT_MAKE_OPTS) tools-all
endef

define HOST_KWBOOT_INSTALL_CMDS
	$(INSTALL) -D -m 0755 -t $(HOST_DIR)/bin $(@D)/bld/tools/kwboot
endef


# "Building" for target: just rely on the fact that `kwboot` gets built via the `uboot` package already

KWBOOT_DEPENDENCIES = uboot

KWBOOT_EXTRACT_CMDS = echo nothing
KWBOOT_CONFIGURE_CMDS = echo nothing
define KWBOOT_BUILD_CMDS
	cp $(UBOOT_BUILDDIR)/tools/kwboot $(@D)
endef

define KWBOOT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m -0755 -t $(TARGET_DIR)/bin $(@D)/kwboot
endef

$(eval $(generic-package))
$(eval $(host-generic-package))
