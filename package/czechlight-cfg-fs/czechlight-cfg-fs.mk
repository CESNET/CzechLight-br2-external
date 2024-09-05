CZECHLIGHT_CFG_FS_INSTALL_IMAGES = YES
CZECHLIGHT_CFG_FS_DEPENDENCIES = \
	host-e2fsprogs \
	host-sysrepo \
	systemd \
	netopeer2 \
	rousette \
	sysrepo-ietf-alarms \
	velia \
	cla-sysrepo

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
endef

CZECHLIGHT_CFG_FS_SYSTEMD_FOR_MULTIUSER = \
	cfg-yang.service \
	cfg-migrate.service \
	sysrepo-persistent-cfg.service \
	openssh-persistent-keys.service \
	cfg-restore-systemd-networkd.service

define CZECHLIGHT_CFG_FS_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/cfg
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/

	$(INSTALL) -D -m 0755 -t $(TARGET_DIR)/sbin \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/init-czechlight.sh \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/cfg-save-sysrepo \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/impl-cfg-save-sysrepo \
		$(@D)/czechlight-random-seed

	$(INSTALL) -D -m 0755 -t $(TARGET_DIR)/usr/libexec/czechlight-cfg-fs \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/cfg-yang.sh \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/cfg-migrate.sh \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/meld.jq

	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/share/yang/static-data/czechlight-cfg-fs \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/static-data/*.json \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/static-data/*.json.in

	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/share/yang/modules/czechlight-cfg-fs \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/yang/*.yang


	for UNIT in $(CZECHLIGHT_CFG_FS_SYSTEMD_FOR_MULTIUSER); do \
		$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/lib/systemd/system/ \
			$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/$${UNIT}; \
		ln -sf ../$${UNIT} $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/ ;\
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

# Do not use buildroot's stock installation scripts
define CZECHLIGHT_CFG_FS_OVERRIDE_NETOPEER_UNITS
	$(RM) \
		$(TARGET_DIR)/usr/lib/systemd/system/netopeer2-install-yang.service \
		$(TARGET_DIR)/usr/lib/systemd/system/netopeer2-setup.service
	$(SED) 's|netopeer2-setup.service|cfg-yang.service|g' $(TARGET_DIR)/usr/lib/systemd/system/netopeer2.service
endef
NETOPEER2_POST_INSTALL_TARGET_HOOKS += CZECHLIGHT_CFG_FS_OVERRIDE_NETOPEER_UNITS

.PHONY: czechlight-cfg-fs-test-migrations
czechlight-cfg-fs-test-migrations: PKG=czechlight-cfg-fs
czechlight-cfg-fs-test-migrations: $(PKG)_NAME=czechlight-cfg-fs
czechlight-cfg-fs-test-migrations: $(BUILD_DIR)/czechlight-cfg-fs/.stamp_configured
	PATH=$(BR_PATH) \
		CLA_SYSREPO_SRCDIR=$(CLA_SYSREPO_SRCDIR) \
		VELIA_SRCDIR=$(VELIA_SRCDIR) \
		SYSREPO_IETF_ALARMS_SRCDIR=$(SYSREPO_IETF_ALARMS_SRCDIR) \
		ROUSETTE_SRCDIR=$(ROUSETTE_SRCDIR) \
		LIBNETCONF2_SRCDIR=$(LIBNETCONF2_SRCDIR) \
		NETOPEER2_SRCDIR=$(NETOPEER2_SRCDIR) \
		pytest -vv $(BR2_EXTERNAL_CZECHLIGHT_PATH)/tests/czechlight-cfg-fs/migrations.py

$(eval $(generic-package))
