CZECHLIGHT_WEBUI_VERSION = main
CZECHLIGHT_WEBUI_SITE = git@gitlab.cesnet.cz:705/czl-sdn/czl-sdn-web-ui.git
CZECHLIGHT_WEBUI_SITE_METHOD = git
CZECHLIGHT_WEBUI_INSTALL_STAGING = NO
CZECHLIGHT_WEBUI_INSTALL_TARGET = YES
CZECHLIGHT_WEBUI_LICENSE = Apache-2.0
CZECHLIGHT_WEBUI_LICENSE_FILES = LICENSE.md
CZECHLIGHT_WEBUI_DEPENDENCIES = nghttp2

define CZECHLIGHT_WEBUI_BUILD_CMDS
	npm install --prefix $(@D)
	npm run build --prefix $(@D)
endef

define CZECHLIGHT_WEBUI_INSTALL_INIT_SYSTEMD
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-webui/nghttp-webclient.service \
		$(TARGET_DIR)/usr/lib/systemd/system/
	ln -sf ../nghttp-webclient.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
endef

define CZECHLIGHT_WEBUI_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -d $(TARGET_DIR)/usr/share/czechlight/webclient/webui
	cp -R $(@D)/build/. $(TARGET_DIR)/usr/share/czechlight/webclient/webui
endef

$(eval $(generic-package))
