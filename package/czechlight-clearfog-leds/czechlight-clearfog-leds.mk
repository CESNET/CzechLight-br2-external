CZECHLIGHT_CLEARFOG_LEDS_DEPENDENCIES = systemd

define CZECHLIGHT_CLEARFOG_LEDS_INSTALL_TARGET_CMDS
        $(INSTALL) -D -m 0644 \
                $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-clearfog-leds/czechlight-clearfog-leds.service \
                $(TARGET_DIR)/usr/lib/systemd/system/
	cp \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-clearfog-leds/clearfog-test-leds.sh \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-clearfog-leds/init-leds-edfa.sh \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-clearfog-leds/init-leds-sfp.sh \
		$(TARGET_DIR)/usr/bin/
endef

$(eval $(generic-package))
