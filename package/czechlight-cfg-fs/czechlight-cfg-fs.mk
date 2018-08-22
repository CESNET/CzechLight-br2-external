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
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/etc-fstab \
		$(TARGET_DIR)/etc/fstab
	mkdir -p $(TARGET_DIR)/cfg
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/local-fs.target.wants/
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/etc-overlay.service \
		$(TARGET_DIR)/usr/lib/systemd/system/etc-overlay.service
	ln -sf ../etc-overlay.service $(TARGET_DIR)/usr/lib/systemd/system/local-fs.target.wants/
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system-generators/
	$(INSTALL) -D -m 0755 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/czechlight-cfg-mount-generator \
		$(TARGET_DIR)/usr/lib/systemd/system-generators/
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
	$(ifeq ($(CZECHLIGHT_CFG_FS_PERSIST_KEYS),y))
		mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
		$(INSTALL) -D -m 0644 \
			$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/netopeer2-keystored-persistent-keys.service \
			$(TARGET_DIR)/usr/lib/systemd/system/
		ln -sf ../netopeer2-keystored-persistent-keys.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
	$(endif)
endef

# Configure OpenSSH to look for *user* keys in the /cfg
define CZECHLIGHT_CFG_FS_OPENSSH_AUTH_PATH_PATCH
	$(SED) 's|^AuthorizedKeysFile.*|AuthorizedKeysFile /cfg/ssh-user-auth/%u|' $(TARGET_DIR)/etc/ssh/sshd_config
endef
OPENSSH_POST_INSTALL_TARGET_HOOKS += CZECHLIGHT_CFG_FS_OPENSSH_AUTH_PATH_PATCH

$(eval $(generic-package))
