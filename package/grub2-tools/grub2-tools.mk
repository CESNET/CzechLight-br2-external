################################################################################
#
# GRUB2_TOOLS
#
################################################################################

GRUB2_TOOLS_VERSION = 2.02
GRUB2_TOOLS_SOURCE = grub-$(GRUB2_TOOLS_VERSION).tar.xz
GRUB2_TOOLS_SITE = ftp://ftp.gnu.org/gnu/grub
GRUB2_TOOLS_DEPENDENCIES = host-bison host-flex
GRUB2_TOOLS_LICENSE = GPLv3+
GRUB2_TOOLS_LICENSE_FILES = COPYING

GRUB2_TOOLS_CONF_ENV = \
		CPP="$(TARGET_CC) -E" \
		TARGET_CC="$(TARGET_CC)" \
		TARGET_CFLAGS="$(TARGET_CFLAGS)" \
		TARGET_CPPFLAGS="$(TARGET_CPPFLAGS)" \
		TARGET_LDFLAGS="$(TARGET_LDFLAGS)" \
		TARGET_NM="$(TARGET_NM)" \
		TARGET_OBJCOPY="$(TARGET_OBJCOPY)" \
		TARGET_STRIP="$(TARGET_CROSS)strip"

GRUB2_TOOLS_CONF_OPTS = \
		--disable-werror \
		--enable-device-mapper=no \
		--enable-libzfs=no \
		--enable-efiemu=no \
		--disable-grub-mkfont \
		ac_cv_lib_lzma_lzma_code=no

define GRUB2_TOOLS_RUN_AUTOGEN
		cd $(@D) && PATH=$(BR_PATH) ./autogen.sh
endef
GRUB2_TOOLS_PRE_CONFIGURE_HOOKS += GRUB2_TOOLS_RUN_AUTOGEN

$(eval $(autotools-package))
