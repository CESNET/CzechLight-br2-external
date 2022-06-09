CZECHLIGHT_INSTALL_YANG_DEPENDENCIES = systemd

define CZECHLIGHT_INSTALL_YANG_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0755 -t $(TARGET_DIR)/usr/libexec/czechlight \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-install-yang/czechlight-install-yang.sh \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-install-yang/czechlight-migrate.sh

	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/libexec/czechlight/migrations \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-install-yang/migrations/*

	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/lib/systemd/system/ \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-install-yang/czechlight-install-yang.service \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-install-yang/czechlight-migrate.service
endef

$(eval $(generic-package))
