VELIA_VERSION = master
VELIA_SITE = https://gerrit.cesnet.cz/CzechLight/velia
VELIA_SITE_METHOD = git
VELIA_INSTALL_STAGING = NO
VELIA_DEPENDENCIES = docopt-cpp spdlog boost sdbus-cpp systemd sysrepo-cpp libnl json-for-modern-cpp
VELIA_LICENSE = Apache-2.0
VELIA_LICENSE_FILES = LICENSE.md

VELIA_CONF_OPTS = \
	-DTHREADS_PTHREAD_ARG:STRING=-pthread \
	-DVELIA_BACKUP_ETC_SHADOW=/cfg/etc/shadow \
	-DVELIA_BACKUP_ETC_HOSTNAME=/cfg/etc/hostname \
	-DVELIA_AUTHORIZED_KEYS_FORMAT="/cfg/ssh-user-auth/{USER}" \
	-DNFT_EXECUTABLE=/usr/sbin/nft \
	-DSSH_KEYGEN_EXECUTABLE=/usr/bin/ssh-keygen \
	-DCHPASSWD_EXECUTABLE=/usr/sbin/chpasswd \
	-DSYSTEMCTL_EXECUTABLE=/usr/bin/systemctl \
	-DNETWORKCTL_EXECUTABLE=/usr/bin/networkctl \
	-DHOSTNAMECTL_EXECUTABLE=/usr/bin/hostnamectl

define VELIA_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/velia/max_match_rules.conf \
		$(TARGET_DIR)/usr/share/dbus-1/system.d/

	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/lib/systemd/system/ \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/velia/velia-health.service \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/velia/velia-hardware-g1.service \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/velia/velia-hardware-g2.service \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/velia/velia-system.service \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/velia/velia-firewall.service
endef

$(eval $(cmake-package))
