LLDP_SYSTEMD_NETWORKD_SYSREPO_VERSION = master
LLDP_SYSTEMD_NETWORKD_SYSREPO_SITE = https://gerrit.cesnet.cz/CzechLight/lldp-systemd-networkd-sysrepo
LLDP_SYSTEMD_NETWORKD_SYSREPO_SITE_METHOD = git
LLDP_SYSTEMD_NETWORKD_SYSREPO_INSTALL_STAGING = NO
LLDP_SYSTEMD_NETWORKD_SYSREPO_DEPENDENCIES = spdlog sdbus-cpp systemd docopt-cpp sysrepo
LLDP_SYSTEMD_NETWORKD_SYSREPO_CONF_OPTS = -DTHREADS_PTHREAD_ARG:STRING=-pthread
LLDP_SYSTEMD_NETWORKD_SYSREPO_LICENSE = Apache-2.0
LLDP_SYSTEMD_NETWORKD_SYSREPO_LICENSE_FILES = LICENSE.md

define LLDP_SYSTEMD_NETWORKD_SYSREPO_INSTALL_INIT_SYSTEMD
        mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
        $(INSTALL) -D -m 0644 \
                $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/lldp-systemd-networkd-sysrepo/lldp-systemd-networkd-sysrepo.service \
                $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/lldp-systemd-networkd-sysrepo/lldp-systemd-networkd-sysrepo-install-yang.service \
                $(TARGET_DIR)/usr/lib/systemd/system/
        ln -sf ../lldp-systemd-networkd-sysrepo.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
        ln -sf ../lldp-systemd-networkd-sysrepo-install-yang.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
endef

$(eval $(cmake-package))
