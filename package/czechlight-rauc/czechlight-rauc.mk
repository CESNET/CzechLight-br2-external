CZECHLIGHT_RAUC_TMP_TARGET_DIR = $(FS_DIR)/rootfs.czechlight-rauc.tmp

CZECHLIGHT_RAUC_IMAGE_VERSION = dev

$(BINARIES_DIR)/update.raucb: host-rauc rootfs-tar
	@$(call MESSAGE,"Generating RAUC update bundle")
	$(RM) -rf $(CZECHLIGHT_RAUC_TMP_TARGET_DIR)
	mkdir -p $(CZECHLIGHT_RAUC_TMP_TARGET_DIR)
	sed \
		-e 's|CZECHLIGHT_RAUC_IMAGE_VERSION|$(call qstrip,$(CZECHLIGHT_RAUC_IMAGE_VERSION))|' \
		-e 's|CZECHLIGHT_RAUC_COMPATIBLE|$(call qstrip,$(CZECHLIGHT_RAUC_COMPATIBLE))|' \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/board/czechlight/common/rauc-manifest.raucm.in \
		> $(CZECHLIGHT_RAUC_TMP_TARGET_DIR)/manifest.raucm

	$(RM) -f $(BINARIES_DIR)/update.raucb
	ln $(BINARIES_DIR)/rootfs.tar.xz $(CZECHLIGHT_RAUC_TMP_TARGET_DIR)
	tar -cJf $(CZECHLIGHT_RAUC_TMP_TARGET_DIR)/cfg.tar.xz -T /dev/null
	cp $(BR2_EXTERNAL_CZECHLIGHT_PATH)/board/czechlight/common/rauc-hook.sh $(CZECHLIGHT_RAUC_TMP_TARGET_DIR)/hook.sh

	$(HOST_DIR)/usr/bin/rauc \
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
