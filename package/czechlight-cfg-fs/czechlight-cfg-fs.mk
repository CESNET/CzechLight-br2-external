CZECHLIGHT_CFG_FS_INSTALL_IMAGES = YES
CZECHLIGHT_CFG_FS_DEPENDENCIES = host-e2fsprogs host-libyang netopeer2

CZECHLIGHT_CFG_FS_LOCATION = $(BINARIES_DIR)/cfg.ext4

define CZECHLIGHT_CFG_FS_INSTALL_IMAGES_CMDS
	rm -f $(CZECHLIGHT_CFG_FS_LOCATION)
	$(HOST_DIR)/sbin/mkfs.ext4 -L cfg $(CZECHLIGHT_CFG_FS_LOCATION) $(call qstrip,$(CZECHLIGHT_CFG_FS_SIZE))
endef

ifeq ($(BR2_PACKAGE_CZECHLIGHT_CFG_FS)-$(call qstrip,$(CZECHLIGHT_CFG_FS_SIZE)),y-)
$(error CZECHLIGHT_CFG_FS_SIZE cannot be empty)
endif

define CZECHLIGHT_CFG_FS_BUILD_CMDS
	$(TARGET_CC) $(CZECHLIGHT_CFG_FS_PKGDIR)/czechlight-random-seed.c -o $(@D)/czechlight-random-seed

	$(HOST_DIR)/usr/bin/yanglint -t config \
		$(TARGET_DIR)/usr/share/yang/modules/netopeer2/ietf-netconf-acm@2018-02-14.yang \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/nacm.json
endef

define CZECHLIGHT_CFG_FS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/init-czechlight.sh \
		$(TARGET_DIR)/sbin/init-czechlight.sh
	$(INSTALL) -D -m 0755 $(@D)/czechlight-random-seed $(TARGET_DIR)/sbin/czechlight-random-seed
	mkdir -p $(TARGET_DIR)/cfg
	$(INSTALL) -D -m 0644 \
	    --target-directory $(TARGET_DIR)/usr/lib/systemd/system/ \
	    $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/nacm-restore.service
	$(INSTALL) -D -m 0644 \
	    --target-directory $(TARGET_DIR)/usr/share/yang-data/ \
	    $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/nacm.json
	$(ifeq ($(CZECHLIGHT_CFG_FS_PERSIST_SYSREPO),y))
		mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
		$(INSTALL) -D -m 0644 \
			$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/sysrepo-persistent-cfg.service \
			$(TARGET_DIR)/usr/lib/systemd/system/
		ln -sf ../sysrepo-persistent-cfg.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
		$(INSTALL) -D -m 0644 \
			$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/cfg-restore-sysrepo.service \
			$(TARGET_DIR)/usr/lib/systemd/system/
		ln -sf ../cfg-restore-sysrepo.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
	$(endif)
	$(ifeq ($(CZECHLIGHT_CFG_FS_PERSIST_KEYS),y))
		mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
		$(INSTALL) -D -m 0644 \
			$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/openssh-persistent-keys.service \
			$(TARGET_DIR)/usr/lib/systemd/system/
		ln -sf ../openssh-persistent-keys.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
	$(endif)
	$(ifeq ($(CZECHLIGHT_CFG_FS_PERSIST_NETWORK),y))
		mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/network-pre.target.wants/
		$(INSTALL) -D -m 0644 \
			$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/cfg-restore-systemd-networkd.service \
			$(TARGET_DIR)/usr/lib/systemd/system/
		ln -sf ../cfg-restore-systemd-network.service $(TARGET_DIR)/usr/lib/systemd/system/network-pre.target.wants/
	$(endif)
endef

# Configure OpenSSH to look for *user* keys in the /cfg
define CZECHLIGHT_CFG_FS_OPENSSH_AUTH_PATH_PATCH
	$(SED) 's|^AuthorizedKeysFile.*|AuthorizedKeysFile /cfg/ssh-user-auth/%u|' $(TARGET_DIR)/etc/ssh/sshd_config
endef
OPENSSH_POST_INSTALL_TARGET_HOOKS += CZECHLIGHT_CFG_FS_OPENSSH_AUTH_PATH_PATCH

NETOPEER2_CONF_OPTS += \
		      -DNP2SRV_SSH_AUTHORIZED_KEYS_PATTERN="/cfg/ssh-user-auth/%s" \
		      -DNP2SRV_SSH_AUTHORIZED_KEYS_ARG_IS_USERNAME=ON

$(eval $(generic-package))
