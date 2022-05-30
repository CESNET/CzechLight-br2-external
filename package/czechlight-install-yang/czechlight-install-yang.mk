CZECHLIGHT_INSTALL_YANG_DEPENDENCIES = systemd

define CZECHLIGHT_INSTALL_YANG_INSTALL_INIT_SYSTEMD
	$(INSTALL) -m 0755 -t $(TARGET_DIR)/usr/bin/ \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-install-yang/czechlight-install-yang.sh
	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/lib/systemd/system/ \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-install-yang/czechlight-install-yang.service
endef

$(eval $(generic-package))
