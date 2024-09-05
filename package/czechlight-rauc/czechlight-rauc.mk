CZECHLIGHT_RAUC_TMP_TARGET_DIR = $(FS_DIR)/rootfs.czechlight-rauc.tmp

$(BINARIES_DIR)/update.raucb: host-rauc rootfs-tar
	@$(call MESSAGE,"Generating RAUC update bundle")
	$(RM) -rf $(CZECHLIGHT_RAUC_TMP_TARGET_DIR)
	mkdir -p $(CZECHLIGHT_RAUC_TMP_TARGET_DIR)
	sed \
		-e 's|CZECHLIGHT_RAUC_IMAGE_VERSION|$(call qstrip,$(shell git --git-dir=$(BR2_EXTERNAL_CZECHLIGHT_PATH)/.git --work-tree=$(BR2_EXTERNAL_CZECHLIGHT_PATH) describe --dirty))|' \
		-e 's|CZECHLIGHT_RAUC_COMPATIBLE|$(call qstrip,$(CZECHLIGHT_RAUC_COMPATIBLE))|' \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-rauc/rauc-manifest.raucm.in \
		> $(CZECHLIGHT_RAUC_TMP_TARGET_DIR)/manifest.raucm

	$(RM) -f $(BINARIES_DIR)/update.raucb
	ln $(BINARIES_DIR)/rootfs.tar.xz $(CZECHLIGHT_RAUC_TMP_TARGET_DIR)
	tar -cJf $(CZECHLIGHT_RAUC_TMP_TARGET_DIR)/cfg.tar.xz -T /dev/null
	cp $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-rauc/rauc-hook.sh $(CZECHLIGHT_RAUC_TMP_TARGET_DIR)/hook.sh

	PATH=$(HOST_DIR)/bin:$(PATH) $(HOST_DIR)/bin/rauc \
		--cert $(BR2_EXTERNAL_CZECHLIGHT_PATH)/crypto/rauc-cert.pem \
		--key $(BR2_EXTERNAL_CZECHLIGHT_PATH)/crypto/rauc-key.pem \
		bundle $(CZECHLIGHT_RAUC_TMP_TARGET_DIR) $(BINARIES_DIR)/update.raucb

rootfs-czechlight-rauc: $(BINARIES_DIR)/update.raucb

rootfs-czechlight-rauc-show-depends:
	@echo host-rauc rootfs-tar

.PHONY: rootfs-czechlight-rauc rootfs-czechlight-rauc-show-depends

ifeq ($(CZECHLIGHT_RAUC_ROOTFS),y)
TARGETS_ROOTFS += rootfs-czechlight-rauc
ifeq ($(call qstrip,$(CZECHLIGHT_RAUC_COMPATIBLE)),)
$(error CZECHLIGHT_RAUC_COMPATIBLE cannot be empty)
endif
endif

CZECHLIGHT_RAUC_INSTALL_TARGET = YES
CZECHLIGHT_RAUC_DEPENDENCIES = rauc

ifeq ($(BR2_PACKAGE_CZECHLIGHT_RAUC),y)

ifeq ($(call qstrip,$(CZECHLIGHT_RAUC_BOOTLOADER)),)
$(error Unsupported bootloader for RAUC)
endif

ifeq ($(call qstrip,$(CZECHLIGHT_RAUC_SLOT_A_ROOTFS_DEV)),)
$(error CZECHLIGHT_RAUC_SLOT_A_ROOTFS_DEV cannot be empty)
endif
ifeq ($(call qstrip,$(CZECHLIGHT_RAUC_SLOT_A_CFG_DEV)),)
$(error CZECHLIGHT_RAUC_SLOT_A_CFG_DEV cannot be empty)
endif
ifeq ($(call qstrip,$(CZECHLIGHT_RAUC_SLOT_B_ROOTFS_DEV)),)
$(error CZECHLIGHT_RAUC_SLOT_B_ROOTFS_DEV cannot be empty)
endif
ifeq ($(call qstrip,$(CZECHLIGHT_RAUC_SLOT_B_CFG_DEV)),)
$(error CZECHLIGHT_RAUC_SLOT_B_CFG_DEV cannot be empty)
endif

endif # BR2_PACKAGE_CZECHLIGHT_RAUC

define CZECHLIGHT_RAUC_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_CZECHLIGHT_PATH)/crypto/rauc-cert.pem $(TARGET_DIR)/etc/rauc/keyring.pem
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-rauc/system.conf.in $(TARGET_DIR)/etc/rauc/system.conf
	sed -i -E -e "s|CZECHLIGHT_RAUC_BOOTLOADER|$(call qstrip, $(CZECHLIGHT_RAUC_BOOTLOADER))|" \
		-e 's|CZECHLIGHT_RAUC_COMPATIBLE|$(call qstrip,$(CZECHLIGHT_RAUC_COMPATIBLE))|' \
		-e "s|CZECHLIGHT_RAUC_SLOT_A_ROOTFS_DEV|$(call qstrip,$(CZECHLIGHT_RAUC_SLOT_A_ROOTFS_DEV))|" \
		-e "s|CZECHLIGHT_RAUC_SLOT_A_CFG_DEV|$(call qstrip,$(CZECHLIGHT_RAUC_SLOT_A_CFG_DEV))|" \
		-e "s|CZECHLIGHT_RAUC_SLOT_B_ROOTFS_DEV|$(call qstrip,$(CZECHLIGHT_RAUC_SLOT_B_ROOTFS_DEV))|" \
		-e "s|CZECHLIGHT_RAUC_SLOT_B_CFG_DEV|$(call qstrip,$(CZECHLIGHT_RAUC_SLOT_B_CFG_DEV))|" \
		$(TARGET_DIR)/etc/rauc/system.conf
	$(INSTALL) -D -m 0644 -t $(TARGET_DIR)/usr/lib/systemd/system/ \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-rauc/rauc-mark-good.service \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-rauc/enable-hw-watchdog.service

	# Just for USB flashing
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system-generators/
	$(INSTALL) -D -m 0755 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-rauc/czechlight-usb-flash-mount-generator \
		$(TARGET_DIR)/usr/lib/systemd/system-generators/
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/czechlight-rauc/usb-flash.service \
		$(TARGET_DIR)/usr/lib/systemd/system/
endef

$(eval $(generic-package))
