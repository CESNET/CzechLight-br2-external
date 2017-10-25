CLA_SYSREPO_VERSION = master
CLA_SYSREPO_SITE = ssh://kundrat@cesnet.cz@gerrit.cesnet.cz:29418/CzechLight/cla-sysrepo
CLA_SYSREPO_SITE_METHOD = git
CLA_SYSREPO_INSTALL_STAGING = NO
CLA_SYSREPO_DEPENDENCIES = sysrepo docopt-cpp spdlog netsnmp systemd
CLA_SYSREPO_CONF_OPTS = -DTHREADS_PTHREAD_ARG:STRING=-pthread
CLA_SYSREPO_LICENSE_FILES = LICENSE.md

$(eval $(cmake-package))
