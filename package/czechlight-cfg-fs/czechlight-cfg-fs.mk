CZECHLIGHT_CFG_FS_DEPENDENCIES = host-e2fsprogs

CZECHLIGHT_CFG_FS_LOCATION = $(BINARIES_DIR)/cfg.ext4

CZECHLIGHT_CFG_FS_SIZE_REAL = $(call qstrip,$(CZECHLIGHT_CFG_FS_SIZE))

define CZECHLIGHT_CFG_FS_BUILD_CMDS
	rm -f $(CZECHLIGHT_CFG_FS_LOCATION)
	$(HOST_DIR)/sbin/mkfs.ext4 -L cfg $(CZECHLIGHT_CFG_FS_LOCATION) $(CZECHLIGHT_CFG_FS_SIZE_REAL)
endef

$(eval $(generic-package))
