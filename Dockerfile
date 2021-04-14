########################################################################
# Copyright (C) 2020		Sebastian Francisco Colomar Bauza
# Copyright (C) 2020, 2021	Alejandro Colomar <alx.manpages@gmail.com>
# Copyright (C) 2021		Ganimedes Colomar <gacoan.linux@gmail.com>
# SPDX-License-Identifier:	GPL-2.0-only OR LGPL-2.0-only
########################################################################


########################################################################
ARG	NGINX_REG="docker.io"
ARG	NGINX_USER="library"
ARG	NGINX_REPO="nginx"
ARG	NGINX_REPOSITORY="${NGINX_REG}/${NGINX_USER}/${NGINX_REPO}"
ARG	NGINX_LBL="1.19.9-alpine"
ARG	NGINX_DIGEST="sha256:4fe11ac2b8ee14157911dd2029b6e30b7aed3888f4549e733aa51930a4af52af"
########################################################################


########################################################################
FROM	"${NGINX_REPOSITORY}:${NGINX_LBL}@${NGINX_DIGEST}" AS nginx
########################################################################
RUN									\
	apk list							\
	|grep 'nginx'							\
	|cut -d' ' -f1							\
	|sed 's/-[0-9].*//'						\
	|sort								\
	|uniq								\
	|grep -v '^nginx$'						\
	|xargs apk del;

########################################################################
RUN	rm -frv	/etc/nginx/conf.d/*;
RUN	rm -fv /etc/nginx/nginx.conf;
########################################################################


########################################################################
FROM	scratch
########################################################################
COPY	--from=nginx / /
########################################################################
EXPOSE	8080
########################################################################
STOPSIGNAL SIGQUIT
########################################################################
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD	["nginx", "-g", "daemon off;"]
########################################################################
VOLUME	/var/cache/nginx/
VOLUME	/var/run/
########################################################################
