define CZECHLIGHT_CLEARFOG_LEDS_BOOT_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-clearfog-leds-boot/czechlight-clearfog-leds.service \
		$(TARGET_DIR)/usr/lib/systemd/system/
	ln -sf ../czechlight-clearfog-leds.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
endef

$(eval $(generic-package))
