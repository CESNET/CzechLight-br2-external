CZECHLIGHT_CFG_FS_INSTALL_IMAGES = YES
CZECHLIGHT_CFG_FS_DEPENDENCIES = host-e2fsprogs host-libyang netopeer2 systemd

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

CZECHLIGHT_CFG_FS_SYSTEMD_FOR_MULTIUSER = \
	czechlight-install-yang.service \
	czechlight-migrate.service \
	nacm-restore.service \
	yang-startup.target

$(ifeq ($(CZECHLIGHT_CFG_FS_PERSIST_SYSREPO),y))
	CZECHLIGHT_CFG_FS_SYSTEMD_FOR_MULTIUSER += \
		sysrepo-persistent-cfg.service \
		cfg-restore-sysrepo.service
$(endif)
$(ifeq ($(CZECHLIGHT_CFG_FS_PERSIST_KEYS),y))
	CZECHLIGHT_CFG_FS_SYSTEMD_FOR_MULTIUSER += openssh-persistent-keys.service
$(endif)
$(ifeq ($(CZECHLIGHT_CFG_FS_PERSIST_NETWORK),y))
	CZECHLIGHT_CFG_FS_SYSTEMD_FOR_MULTIUSER += cfg-restore-systemd-networkd.service
$(endif)

define CZECHLIGHT_CFG_FS_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/cfg
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/

	$(INSTALL) -D -m 0755 -t $(TARGET_DIR)/sbin \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/init-czechlight.sh \
		$(@D)/czechlight-random-seed

	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/share/yang-data/ \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/nacm.json

	$(INSTALL) -D -m 0755 -t $(TARGET_DIR)/usr/libexec/czechlight-cfg-fs \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/czechlight-install-yang.sh \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/czechlight-migrate.sh \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/czechlight-migration-list.sh

	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/libexec/czechlight-cfg-fs/migrations \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/migrations/*

	for UNIT in $(CZECHLIGHT_CFG_FS_SYSTEMD_FOR_MULTIUSER); do \
		$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/lib/systemd/system/ \
			$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/$${UNIT}; \
		ln -sf ../${{UNIT}} $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/ ;\
	done
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
