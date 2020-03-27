ifdef CZECHLIGHT_CLEARFOG_LEDS_BOOT
define CZECHLIGHT_CLEARFOG_LEDS_BOOT_INSTALL_TARGET_CMDS
        $(INSTALL) -D -m 0644 \
                $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-clearfog-leds/czechlight-clearfog-leds-boot.service \
                $(TARGET_DIR)/usr/lib/systemd/system/
        ln -sf ../czechlight-clearfog-leds-boot.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
endef
endif

define CZECHLIGHT_CLEARFOG_LEDS_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
        $(INSTALL) -D -m 0644 \
                $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-clearfog-leds/czechlight-clearfog-leds.service \
                $(TARGET_DIR)/usr/lib/systemd/system/
        ln -sf ../czechlight-clearfog-leds.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
	$(CZECHLIGHT_CLEARFOG_LEDS_BOOT_INSTALL_TARGET_CMDS)
	cp \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-clearfog-leds/clearfog-test-leds.sh \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-clearfog-leds/init-leds-edfa.sh \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-clearfog-leds/init-leds-sfp.sh \
		$(TARGET_DIR)/usr/bin/
endef

$(eval $(generic-package))
