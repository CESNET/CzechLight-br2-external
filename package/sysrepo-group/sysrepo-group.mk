SYSREPO_GROUP_INSTALL_TARGET = YES

SYSREPO_CONF_OPTS += -DSYSREPO_GROUP=sysrepo -DSYSREPO_UMASK=0007

define SYSREPO_GROUP_INSTALL_TARGET_CMDS
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/lib/systemd/system/run-sysrepo.mount.d/
	for UNIT in \
		netopeer2.service \
		netopeer2-setup.service \
		netopeer2-install-yang.service \
	; do \
		echo "Adding systemd unit group $${UNIT}"; \
		$(INSTALL) -d -m 0755 $(TARGET_DIR)/usr/lib/systemd/system/$${UNIT}.d/ ; \
		echo -e "[Unit]\nGroup=sysrepo\n" > $(TARGET_DIR)/usr/lib/systemd/system/$${UNIT}.d/sysrepo-group.conf ; \
	done
endef

$(eval $(generic-package))
