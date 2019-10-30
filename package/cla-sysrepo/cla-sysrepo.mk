CLA_SYSREPO_VERSION = master
CLA_SYSREPO_SITE = ssh://kundrat@cesnet.cz@gerrit.cesnet.cz:29418/CzechLight/cla-sysrepo
CLA_SYSREPO_SITE_METHOD = git
CLA_SYSREPO_INSTALL_STAGING = NO
CLA_SYSREPO_DEPENDENCIES = sysrepo docopt-cpp spdlog systemd libgpiod boost cppcodec
CLA_SYSREPO_CONF_OPTS = -DTHREADS_PTHREAD_ARG:STRING=-pthread
CLA_SYSREPO_LICENSE_FILES = LICENSE.md

define CLA_SYSREPO_ONE_MODEL_INSTALL_1
	sed \
		-e "s/__MODEL__/$1/g" \
		-e "s/__YANG__/$2/g" \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/cla-sysrepo/cla-install-yang.service.in \
		> $(TARGET_DIR)/usr/lib/systemd/system/cla-install-yang-$1.service
endef

define CLA_SYSREPO_ONE_MODEL_INSTALL_2
	sed -i '/__FEATURE__/d' $(TARGET_DIR)/usr/lib/systemd/system/cla-install-yang-$1.service
	sed \
		-e "s/__MODEL__/$1/g" \
		-e "s/__YANG__/$2/g" \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/cla-sysrepo/cla-appliance.service.in \
		> $(TARGET_DIR)/usr/lib/systemd/system/cla-$1.service
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants
	ln -sf ../cla-install-yang-$1.service \
		$(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
	ln -sf ../cla-$1.service \
		$(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
endef

define CLA_SYSREPO_ONE_MODEL_W_FEATURE
	$(call CLA_SYSREPO_ONE_MODEL_INSTALL_1,$1,$2)
	# FIXME: multiple features...
	sed -i 's|__FEATURE__|ExecStart=/usr/bin/sysrepoctl --module $2 --feature-enable $3\n__FEATURE__|' \
		$(TARGET_DIR)/usr/lib/systemd/system/cla-install-yang-$1.service
	$(call CLA_SYSREPO_ONE_MODEL_INSTALL_2,$1,$2)
endef

define CLA_SYSREPO_ONE_MODEL
	$(call CLA_SYSREPO_ONE_MODEL_INSTALL_1,$1,$2)
	$(call CLA_SYSREPO_ONE_MODEL_INSTALL_2,$1,$2)
endef

define CLA_SYSREPO_INSTALL_INIT_SYSTEMD
	$(call CLA_SYSREPO_ONE_MODEL_W_FEATURE,sdn-roadm-add-drop,czechlight-roadm-device,hw-add-drop-20)
	$(call CLA_SYSREPO_ONE_MODEL_W_FEATURE,sdn-roadm-line,czechlight-roadm-device,hw-line-9)
	$(call CLA_SYSREPO_ONE_MODEL,sdn-roadm-coherent-a-d,czechlight-coherent-add-drop)
	$(call CLA_SYSREPO_ONE_MODEL,sdn-inline,czechlight-inline-amp)
endef

$(eval $(cmake-package))
