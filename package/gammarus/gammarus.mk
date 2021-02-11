GAMMARUS_VERSION = master
GAMMARUS_SITE = ssh://gerrit.cesnet.cz:29418/CzechLight/gammarus
GAMMARUS_SITE_METHOD = git
GAMMARUS_INSTALL_STAGING = NO
GAMMARUS_INSTALL_TARGET = YES
GAMMARUS_LICENSE = Apache-2.0

define GAMMARUS_INSTALL_TARGET_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) DESTDIR=$(TARGET_DIR) install
endef

define GAMMARUS_USERS
	yangnobody 333666 dwdm -1 * - - - Unauthenticated operations via RESTCONF
endef

$(eval $(generic-package))
