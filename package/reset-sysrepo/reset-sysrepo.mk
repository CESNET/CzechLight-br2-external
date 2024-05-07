RESET_SYSREPO_INSTALL_TARGET = YES

define RESET_SYSREPO_PATCH_DEV_SHM
        sed -i \
                's|^#define SR_SHM_DIR .*|#define SR_SHM_DIR "/run/sysrepo"|' \
                $(@D)/src/config.h.in
endef

SYSREPO_PRE_PATCH_HOOKS += RESET_SYSREPO_PATCH_DEV_SHM
SYSREPO_POST_RSYNC_HOOKS += RESET_SYSREPO_PATCH_DEV_SHM

define RESET_SYSREPO_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 \
		--target-directory $(TARGET_DIR)/usr/lib/systemd/system/ \
		$(BR2_EXTERNAL_CZECHLIGHT_PATH)/package/reset-sysrepo/run-sysrepo.mount
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/lib/systemd/system/run-sysrepo.mount.d/
	for UNIT in \
		cla-sdn-inline.service \
		cla-sdn-roadm-add-drop.service \
		cla-sdn-roadm-coherent-a-d.service \
		cla-sdn-roadm-hires-drop.service \
		cla-sdn-roadm-line.service \
		cla-sdn-bidi-cplus1572.service \
		cla-sdn-bidi-cplus1572-ocm.service \
		netopeer2.service \
		sysrepo-ietf-alarms.service \
		sysrepo-persistent-cfg.service \
		sysrepo-plugind.service \
		velia-firewall.service \
		velia-health.service \
		velia-system.service \
		velia-hardware-g1.service \
		velia-hardware-g2.service \
		rousette.service \
	; do \
		echo "Adding systemd drop-ins $${UNIT} <-> /run/sysrepo"; \
		$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/lib/systemd/system/$${UNIT}.d/ ; \
		echo -e "[Unit]\nBindsTo=run-sysrepo.mount\nAfter=run-sysrepo.mount\nPartOf=run-sysrepo.mount" \
			> $(TARGET_DIR)/usr/lib/systemd/system/$${UNIT}.d/reset-sysrepo.conf ; \
		echo -e "[Unit]\nPartOf=$${UNIT}" \
			> $(TARGET_DIR)/usr/lib/systemd/system/run-sysrepo.mount.d/$${UNIT}.conf ; \
	done
endef

$(eval $(generic-package))
