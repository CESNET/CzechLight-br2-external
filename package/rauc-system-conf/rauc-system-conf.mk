RAUC_SYSTEM_CONF_INSTALL_TARGET = YES
RAUC_SYSTEM_CONF_INSTALL_IMAGES = NO

# Find out which bootloader should we write into system.conf:
ifeq ($(BR2_TARGET_GRUB2),y)
	CZECHLIGHT_RAUC_BOOTLOADER_NAME = grub
else ifeq ($(BR2_TARGET_UBOOT),y)
	CZECHLIGHT_RAUC_BOOTLOADER_NAME = uboot
else
	$(error Unsupported bootloader for RAUC)
endif

# Generate the /etc/rauc/system.conf file
define RAUC_SYSTEM_CONF_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/rauc-system-conf/system.conf $(TARGET_DIR)/etc/rauc/system.conf
	sed -i -E -e "s|CZECHLIGHT_RAUC_BOOTLOADER_NAME|$(CZECHLIGHT_RAUC_BOOTLOADER_NAME)|" \
		-e "s|CZECHLIGHT_RAUC_SLOT_A_ROOTFS_DEV|$(call qstrip,$(CZECHLIGHT_RAUC_SLOT_A_ROOTFS_DEV))|" \
		-e "s|CZECHLIGHT_RAUC_SLOT_A_CFG_DEV|$(call qstrip,$(CZECHLIGHT_RAUC_SLOT_A_CFG_DEV))|" \
		-e "s|CZECHLIGHT_RAUC_SLOT_B_ROOTFS_DEV|$(call qstrip,$(CZECHLIGHT_RAUC_SLOT_B_ROOTFS_DEV))|" \
		-e "s|CZECHLIGHT_RAUC_SLOT_B_CFG_DEV|$(call qstrip,$(CZECHLIGHT_RAUC_SLOT_B_CFG_DEV))|" \
		$(TARGET_DIR)/etc/rauc/system.conf
endef

$(eval $(generic-package))
