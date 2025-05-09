ROUSETTE_VERSION = master
ROUSETTE_SITE = https://gerrit.cesnet.cz/CzechLight/rousette
ROUSETTE_SITE_METHOD = git
ROUSETTE_INSTALL_STAGING = NO
ROUSETTE_DEPENDENCIES = boost docopt-cpp nghttp2-asio spdlog systemd sysrepo-cpp date linux-pam
ROUSETTE_LICENSE = Apache-2.0
ROUSETTE_LICENSE_FILES = LICENSE.md

ROUSETTE_CONF_OPTS = \
	-DTHREADS_PTHREAD_ARG:STRING=-pthread

define ROUSETTE_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/rousette/rousette.service \
		$(TARGET_DIR)/usr/lib/systemd/system/
endef

define ROUSETTE_INSTALL_PAM_CONF
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/rousette/pam.conf $(TARGET_DIR)/etc/pam.d/rousette
endef
ROUSETTE_POST_INSTALL_TARGET_HOOKS += ROUSETTE_INSTALL_PAM_CONF

define ROUSETTE_USERS
	yangnobody 333666 yangnobody 333666 * - - - Unauthenticated operations via RESTCONF
endef

$(eval $(cmake-package))
