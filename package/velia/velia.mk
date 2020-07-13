VELIA_VERSION = master
VELIA_SITE = https://gerrit.cesnet.cz/CzechLight/velia
VELIA_SITE_METHOD = git
VELIA_INSTALL_STAGING = NO
VELIA_DEPENDENCIES = docopt-cpp spdlog boost sdbus-cpp
VELIA_CONF_OPTS = -DTHREADS_PTHREAD_ARG:STRING=-pthread
VELIA_LICENSE = Apache-2.0
VELIA_LICENSE_FILES = LICENSE.md

define VELIA_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
        $(INSTALL) -D -m 0644 \
                $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/velia/velia.service \
                $(TARGET_DIR)/usr/lib/systemd/system/
        ln -sf ../velia.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
endef
$(eval $(cmake-package))
