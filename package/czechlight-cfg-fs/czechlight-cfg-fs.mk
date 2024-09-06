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

	$(INSTALL) -D -m 0755 -t $(TARGET_DIR)/sbin \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/init-czechlight.sh \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/cfg-save-sysrepo \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/impl-cfg-save-sysrepo \
		$(@D)/czechlight-random-seed

	$(INSTALL) -D -m 0755 -t $(TARGET_DIR)/usr/libexec/czechlight-cfg-fs \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/cfg-yang.sh \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/cfg-migrate.sh

	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/libexec/czechlight-cfg-fs \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/meld.jq \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/CURRENT_CONFIG_VERSION

	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/share/yang/static-data/czechlight-cfg-fs \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/static-data/*.json \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/static-data/*.json.in

	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/share/yang/modules/czechlight-cfg-fs \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/yang/*.yang


	for UNIT in $(CZECHLIGHT_CFG_FS_SYSTEMD_FOR_MULTIUSER); do \
		$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/lib/systemd/system/ \
			$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/$${UNIT}; \
	done

	$(INSTALL) -D -m 644 -t $(TARGET_DIR)/usr/lib/systemd/system-preset \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/50-czechlight.preset

	$(INSTALL) -D -m 0644 --target-directory $(TARGET_DIR)/usr/lib/systemd/system/ \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-cfg-fs/run-sysrepo.mount
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/lib/systemd/system/run-sysrepo.mount.d/
	for UNIT in \
		cla-sdn-inline.service \
		cla-sdn-roadm-add-drop.service \
		cla-sdn-roadm-coherent-a-d.service \
		cla-sdn-roadm-hires-drop.service \
		cla-sdn-roadm-line.service \
		cla-sdn-bidi-cplus1572.service \
		cla-sdn-bidi-cplus1572-ocm.service \
		netopeer2.service \
		sysrepo-ietf-alarms.service \
		sysrepo-persistent-cfg.service \
		sysrepo-plugind.service \
		velia-firewall.service \
		velia-health.service \
		velia-system.service \
		velia-hardware-g1.service \
		velia-hardware-g2.service \
		rousette.service \
	; do \
		$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/lib/systemd/system/$${UNIT}.d/ ; \
		echo -e "[Unit]\nBindsTo=run-sysrepo.mount\nAfter=run-sysrepo.mount" \
			> $(TARGET_DIR)/usr/lib/systemd/system/$${UNIT}.d/reset-sysrepo.conf ; \
	done
endef

# Configure OpenSSH to look for *user* keys in the /cfg
define CZECHLIGHT_CFG_FS_OPENSSH_AUTH_PATH_PATCH
	$(SED) 's|^AuthorizedKeysFile.*|AuthorizedKeysFile /cfg/ssh-user-auth/%u|' $(TARGET_DIR)/etc/ssh/sshd_config
endef
OPENSSH_POST_INSTALL_TARGET_HOOKS += CZECHLIGHT_CFG_FS_OPENSSH_AUTH_PATH_PATCH

NETOPEER2_CONF_OPTS += -DSSH_AUTHORIZED_KEYS_FORMAT="/cfg/ssh-user-auth/%u"

VELIA_CONF_OPTS += \
	-DVELIA_BACKUP_ETC_SHADOW=/cfg/etc/shadow \
	-DVELIA_BACKUP_ETC_HOSTNAME=/cfg/etc/hostname \
	-DVELIA_AUTHORIZED_KEYS_FORMAT="/cfg/ssh-user-auth/{USER}"

# Do not use buildroot's stock installation scripts
define CZECHLIGHT_CFG_FS_OVERRIDE_NETOPEER_UNITS
	$(SED) 's|netopeer2-setup.service|cfg-yang.service|g' $(TARGET_DIR)/usr/lib/systemd/system/netopeer2.service
endef
NETOPEER2_POST_INSTALL_TARGET_HOOKS += CZECHLIGHT_CFG_FS_OVERRIDE_NETOPEER_UNITS

# Do not clutter /dev/shm, use a proper prefix for sysrepo
define RESET_SYSREPO_PATCH_DEV_SHM
        sed -i \
                's|^#define SR_SHM_DIR .*|#define SR_SHM_DIR "/run/sysrepo"|' \
                $(@D)/src/config.h.in
endef
SYSREPO_PRE_PATCH_HOOKS += RESET_SYSREPO_PATCH_DEV_SHM
SYSREPO_POST_RSYNC_HOOKS += RESET_SYSREPO_PATCH_DEV_SHM

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
		PYTHONDONTWRITEBYTECODE=1 \
		pytest \
			-vv \
			--basetemp $(BUILD_DIR)/czechlight-cfg-fs/pytest \
			-o tmp_path_retention_count=1 \
			$(BR2_EXTERNAL_CZECHLIGHT_PATH)/tests/czechlight-cfg-fs/migrations.py

$(eval $(generic-package))
