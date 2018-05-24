CZECHLIGHT_CFG_FS_INSTALL_IMAGES = YES
CZECHLIGHT_CFG_FS_DEPENDENCIES = host-e2fsprogs

CZECHLIGHT_CFG_FS_LOCATION = $(BINARIES_DIR)/cfg.ext4

define CZECHLIGHT_CFG_FS_INSTALL_IMAGES_CMDS
	rm -f $(CZECHLIGHT_CFG_FS_LOCATION)
	$(HOST_DIR)/sbin/mkfs.ext4 -L cfg $(CZECHLIGHT_CFG_FS_LOCATION) $(call qstrip,$(CZECHLIGHT_CFG_FS_SIZE))
endef

ifeq ($(BR2_PACKAGE_CZECHLIGHT_CFG_FS)-$(call qstrip,$(CZECHLIGHT_CFG_FS_SIZE)),y-)
$(error CZECHLIGHT_CFG_FS_SIZE cannot be empty)
endif

define CZECHLIGHT_CFG_FS_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/local-fs.target.wants/
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/etc-overlay.service \
		$(TARGET_DIR)/usr/lib/systemd/system/etc-overlay.service
	ln -sf ../etc-overlay.service $(TARGET_DIR)/usr/lib/systemd/system/local-fs.target.wants/
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system-generators/
	$(INSTALL) -D -m 0755 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/czechlight-cfg-mount-generator \
		$(TARGET_DIR)/usr/lib/systemd/system-generators/czechlight-cfg-mount-generator
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/cfg-restore-etc.service \
		$(TARGET_DIR)/usr/lib/systemd/system/cfg-restore-etc.service
	ln -sf ../cfg-restore-etc.service $(TARGET_DIR)/usr/lib/systemd/system/local-fs.target.wants/
	$(ifeq ($(CZECHLIGHT_CFG_FS_PERSIST_SYSREPO),y))
		mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
		$(INSTALL) -D -m 0644 \
			$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/sysrepo-persistent-cfg.service \
			$(TARGET_DIR)/usr/lib/systemd/system/
		ln -sf ../sysrepo-persistent-cfg.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
	$(endif)
endef

$(eval $(generic-package))
