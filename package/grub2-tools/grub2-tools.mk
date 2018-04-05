################################################################################
#
# grub2-tools
#
################################################################################

GRUB2_TOOLS_VERSION = 2.02
GRUB2_TOOLS_SITE = http://ftp.gnu.org/gnu/grub
GRUB2_TOOLS_SOURCE = grub-$(GRUB2_VERSION).tar.xz
GRUB2_TOOLS_LICENSE = GPLv3+
GRUB2_TOOLS_LICENSE_FILES = COPYING
GRUB2_TOOLS_DEPENDENCIES = host-bison host-flex

GRUB2_TOOLS_CONF_ENV = \
	CPP="$(TARGET_CC) -E" \
	TARGET_CC="$(TARGET_CC)" \
	TARGET_CFLAGS="$(TARGET_CFLAGS) -Wp,-U_FORTIFY_SOURCE -fno-stack-protector" \
	TARGET_CPPFLAGS="$(TARGET_CPPFLAGS) -Wp,-U_FORTIFY_SOURCE -fno-stack-protector" \
	TARGET_LDFLAGS="$(TARGET_LDFLAGS) -fno-stack-protector" \
	TARGET_NM="$(TARGET_NM)" \
	TARGET_OBJCOPY="$(TARGET_OBJCOPY)" \
	TARGET_STRIP="$(TARGET_CROSS)strip" \
	CXXFLAGS="$(CXXFLAGS) -fno-stack-protector" \
	CFLAGS="$(CFLAGS) -fno-stack-protector" \
	LDFLAGS="$(LDFLAGS) -fno-stack-protector"

GRUB2_TOOLS_CONF_OPTS = \
	--disable-grub-mkfont \
	--enable-efiemu=no \
	ac_cv_lib_lzma_lzma_code=no \
	--enable-device-mapper=no \
	--enable-libzfs=no \
	--disable-werror

$(eval $(autotools-package))
