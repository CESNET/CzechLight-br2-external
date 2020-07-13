VELIA_VERSION = master
VELIA_SITE = https://gerrit.cesnet.cz/CzechLight/velia
VELIA_SITE_METHOD = git
VELIA_INSTALL_STAGING = NO
VELIA_DEPENDENCIES = docopt-cpp spdlog boost sdbus-cpp
VELIA_CONF_OPTS = -DTHREADS_PTHREAD_ARG:STRING=-pthread
VELIA_LICENSE = Apache-2.0
VELIA_LICENSE_FILES = LICENSE.md

$(eval $(cmake-package))
