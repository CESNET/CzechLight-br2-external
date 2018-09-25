SFP_I2C_VERSION = b433e4010aac3c672d8b49865cd90f3a65fb3e00
SFP_I2C_SITE = $(call github,feuerrot,sfp-i2c,$(SFP_I2C_VERSION))
SFP_I2C_LICENSE = SPL
SFP_I2C_LICENSE_FILES = LICENSE

define SFP_I2C_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(TARGET_CC) $(SFP_I2C_MAKE_OPTS) $(@D)/main.c -o $(@D)/sfp-i2c
endef

define SFP_I2C_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 $(@D)/sfp-i2c $(TARGET_DIR)/usr/bin/
endef

$(eval $(generic-package))
