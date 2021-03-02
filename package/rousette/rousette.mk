ROUSETTE_VERSION = master
ROUSETTE_SITE = https://gerrit.cesnet.cz/CzechLight/rousette
ROUSETTE_SITE_METHOD = git
ROUSETTE_INSTALL_STAGING = NO
ROUSETTE_DEPENDENCIES = boost docopt-cpp nghttp2 spdlog systemd sysrepo
ROUSETTE_LICENSE = Apache-2.0
ROUSETTE_LICENSE_FILES = LICENSE.md

ROUSETTE_CONF_OPTS = \
	-DTHREADS_PTHREAD_ARG:STRING=-pthread

$(eval $(cmake-package))
