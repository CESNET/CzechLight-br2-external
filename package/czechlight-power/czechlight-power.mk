define CZECHLIGHT_POWER_INSTALL_TARGET_CMDS
        mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
        $(INSTALL) -D -m 0644 \
                $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-power/czechlight-power.service \
                $(TARGET_DIR)/usr/lib/systemd/system/
        ln -sf ../czechlight-power.service $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/
	cp \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-power/czechlight-power.sh \
		$(TARGET_DIR)/usr/bin/
endef

$(eval $(generic-package))
