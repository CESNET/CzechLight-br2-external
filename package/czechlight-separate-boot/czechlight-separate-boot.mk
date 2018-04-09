define CZECHLIGHT_SEPARATE_BOOT_SYMLINK_BOOT
	cd $(TARGET_DIR)/boot
	ln -s . boot
endef

ROOTFS_CZECHLIGHT_SEPARATE_BOOT_PRE_GEN_HOOKS += CZECHLIGHT_SEPARATE_BOOT_SYMLINK_BOOT

ROOTFS_CZECHLIGHT_SEPARATE_BOOT_DEPENDENCIES = host-e2fsprogs

define ROOTFS_CZECHLIGHT_SEPARATE_BOOT_CMD
	rm -f $@
	$(HOST_DIR)/sbin/mkfs.ext2 -d $(TARGET_DIR)/boot -L /boot $@ \
		$(call qstrip,$(CZECHLIGHT_SEPARATE_BOOT_SIZE))
endef

ifeq ($(BR2_TARGET_ROOTFS_CZECHLIGHT_SEPARATE_BOOT)-$(call qstrip,$(CZECHLIGHT_SEPARATE_BOOT_SIZE)),y-)
$(error CZECHLIGHT_SEPARATE_BOOT_SIZE cannot be empty)
endif

define CZECHLIGHT_SEPARATE_BOOT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-separate-boot/boot.mount \
		$(TARGET_DIR)/usr/lib/systemd/system/boot.mount
	ln -sf ../boot.mount $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
endef

$(eval $(rootfs))
$(eval $(generic-package))
