VELIA_VERSION = master
VELIA_SITE = ssh://kundrat@cesnet.cz@gerrit.cesnet.cz:29418/CzechLight/velia
VELIA_SITE_METHOD = git
VELIA_INSTALL_STAGING = NO
VELIA_DEPENDENCIES = docopt-cpp spdlog boost sdbus-cpp
VELIA_CONF_OPTS = -DTHREADS_PTHREAD_ARG:STRING=-pthread
VELIA_LICENSE_FILES = LICENSE.md

$(eval $(cmake-package))
