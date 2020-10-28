LLDP_SYSTEMD_NETWORKD_SYSREPO_VERSION = master
LLDP_SYSTEMD_NETWORKD_SYSREPO_SITE = https://gerrit.cesnet.cz/CzechLight/lldp-systemd-networkd-sysrepo
LLDP_SYSTEMD_NETWORKD_SYSREPO_SITE_METHOD = git
LLDP_SYSTEMD_NETWORKD_SYSREPO_INSTALL_STAGING = NO
LLDP_SYSTEMD_NETWORKD_SYSREPO_DEPENDENCIES = spdlog sdbus-cpp systemd docopt-cpp sysrepo
LLDP_SYSTEMD_NETWORKD_SYSREPO_CONF_OPTS = -DTHREADS_PTHREAD_ARG:STRING=-pthread
LLDP_SYSTEMD_NETWORKD_SYSREPO_LICENSE = Apache-2.0
LLDP_SYSTEMD_NETWORKD_SYSREPO_LICENSE_FILES = LICENSE.md

define LLDP_SYSTEMD_NETWORKD_SYSREPO_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/lib/systemd/system/ \
                $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/lldp-systemd-networkd-sysrepo/lldp-systemd-networkd-sysrepo.service
        ln -sf ../lldp-systemd-networkd-sysrepo.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
endef

$(eval $(cmake-package))
