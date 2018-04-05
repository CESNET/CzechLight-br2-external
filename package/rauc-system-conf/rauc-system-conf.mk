RAUC_SYSTEM_CONF_INSTALL_TARGET = YES
RAUC_SYSTEM_CONF_INSTALL_IMAGES = NO

# Find out which bootloader should we write into system.conf:
ifeq ($(BR2_TARGET_GRUB2), y)
	export BOOTLOADER_NAME = grub
else ifeq ($(BR2_TARGET_UBOOT), y)
	export BOOTLOADER_NAME = uboot
else
	$(error Unsupported bootloader for RAUC)
endif

# Generate the system.conf RAUC file
define RAUC_SYSTEM_CONF_BUILD_CMDS
	$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/rauc-system-conf/generate-system-conf.sh > $(@D)/system.conf
	sed -i -E "s|BOOTLOADER_NAME|$(BOOTLOADER_NAME)|" $(@D)/system.conf
	sed -i -E "s|CZECHLIGHT_RAUC_SLOT_A_ROOTFS_DEV|$(call qstrip, $(CZECHLIGHT_RAUC_SLOT_A_ROOTFS_DEV))|" $(@D)/system.conf
	sed -i -E "s|CZECHLIGHT_RAUC_SLOT_A_CFG_DEV|$(call qstrip, $(CZECHLIGHT_RAUC_SLOT_A_CFG_DEV))|" $(@D)/system.conf
	sed -i -E "s|CZECHLIGHT_RAUC_SLOT_B_ROOTFS_DEV|$(call qstrip, $(CZECHLIGHT_RAUC_SLOT_B_ROOTFS_DEV))|" $(@D)/system.conf
	sed -i -E "s|CZECHLIGHT_RAUC_SLOT_B_CFG_DEV|$(call qstrip, $(CZECHLIGHT_RAUC_SLOT_B_CFG_DEV))|" $(@D)/system.conf
endef

# Install the /etc/rauc/system.conf file
define RAUC_SYSTEM_CONF_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/system.conf $(TARGET_DIR)/etc/rauc/system.conf
endef

$(eval $(generic-package))
