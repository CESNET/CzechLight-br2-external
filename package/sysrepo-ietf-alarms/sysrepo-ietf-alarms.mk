SYSREPO_IETF_ALARMS_VERSION = master
SYSREPO_IETF_ALARMS_SITE = https://gerrit.cesnet.cz/CzechLight/sysrepo-ietf-alarms
SYSREPO_IETF_ALARMS_SITE_METHOD = git
SYSREPO_IETF_ALARMS_INSTALL_STAGING = NO
SYSREPO_IETF_ALARMS_DEPENDENCIES = docopt-cpp spdlog date sysrepo sysrepo-cpp boost
SYSREPO_IETF_ALARMS_LICENSE = Apache-2.0
SYSREPO_IETF_ALARMS_LICENSE_FILES = LICENSE.md

define SYSREPO_IETF_ALARMS_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/sysrepo-ietf-alarms/sysrepo-ietf-alarms.service \
		$(TARGET_DIR)/usr/lib/systemd/system/
endef

$(eval $(cmake-package))
