CLA_SYSREPO_VERSION = master
CLA_SYSREPO_SITE = ssh://kundrat@cesnet.cz@gerrit.cesnet.cz:29418/CzechLight/cla-sysrepo
CLA_SYSREPO_SITE_METHOD = git
CLA_SYSREPO_INSTALL_STAGING = NO
CLA_SYSREPO_DEPENDENCIES = sysrepo-cpp docopt-cpp spdlog systemd libgpiod boost cppcodec libev
CLA_SYSREPO_CONF_OPTS = -DTHREADS_PTHREAD_ARG:STRING=-pthread
CLA_SYSREPO_LICENSE_FILES = LICENSE.md

define CLA_SYSREPO_PREPARE_SERVICE
	sed \
		-e "s/__MODEL__/$1/g" \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/cla-sysrepo/cla-appliance.service.in \
		> $(TARGET_DIR)/usr/lib/systemd/system/cla-$1.service
	ln -sf ../cla-$1.service \
		$(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
endef

define CLA_SYSREPO_INSTALL_INIT_SYSTEMD
	$(INSTALL) -m 0755 -t $(TARGET_DIR)/usr/bin/ \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/cla-sysrepo/czechlight-install-yang.sh
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants
	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/lib/systemd/system/ \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/cla-sysrepo/czechlight-install-yang.service

	$(call CLA_SYSREPO_PREPARE_SERVICE,sdn-roadm-add-drop)
	$(call CLA_SYSREPO_PREPARE_SERVICE,sdn-roadm-hires-add-drop)
	$(call CLA_SYSREPO_PREPARE_SERVICE,sdn-roadm-line)
	$(call CLA_SYSREPO_PREPARE_SERVICE,sdn-roadm-coherent-a-d)
	$(call CLA_SYSREPO_PREPARE_SERVICE,sdn-inline)
	$(call CLA_SYSREPO_PREPARE_SERVICE,calibration-box)
endef

# FIXME: calibration-box really needs a drop-in file with increased timeout...

$(eval $(cmake-package))
