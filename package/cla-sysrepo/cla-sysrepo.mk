CLA_SYSREPO_VERSION = master
CLA_SYSREPO_SITE = ssh://kundrat@cesnet.cz@gerrit.cesnet.cz:29418/CzechLight/cla-sysrepo
CLA_SYSREPO_SITE_METHOD = git
CLA_SYSREPO_INSTALL_STAGING = NO
CLA_SYSREPO_DEPENDENCIES = sysrepo docopt-cpp spdlog netsnmp systemd libgpiod
CLA_SYSREPO_CONF_OPTS = -DTHREADS_PTHREAD_ARG:STRING=-pthread
CLA_SYSREPO_LICENSE_FILES = LICENSE.md

CLA_SYSREPO_ONE_MODEL = \
	sed \
		-e "s/__MODEL__/$1/g" \
		-e "s/__YANG__/$2/g" \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/cla-sysrepo/cla-install-yang.service.in \
		> $(TARGET_DIR)/usr/lib/systemd/system/cla-install-yang-$1.service ; \
	sed \
		-e "s/__MODEL__/$1/g" \
		-e "s/__YANG__/$2/g" \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/cla-sysrepo/cla-appliance.service.in \
		> $(TARGET_DIR)/usr/lib/systemd/system/cla-$1.service ; \
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants ; \
	ln -sf ../cla-install-yang-$1.service \
		$(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/ ; \
	ln -sf ../cla-$1.service \
		$(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/ ;

define CLA_SYSREPO_INSTALL_INIT_SYSTEMD
	$(call CLA_SYSREPO_ONE_MODEL,sdn-roadm-add-drop,czechlight-roadm-device)
	$(call CLA_SYSREPO_ONE_MODEL,sdn-roadm-line,czechlight-roadm-device)
endef

$(eval $(cmake-package))
