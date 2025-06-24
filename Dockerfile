FROM alpine:3.22

# Best security practice (user nobody, group www-data)
ARG UID=65534
ARG GID=82

ENV CONFIG_PATH=/srv/cfg
ENV PATH=$PATH:/srv/bin

RUN \
# Install dependencies
    apk upgrade --no-cache \
    && apk add --no-cache gnupg git nginx php84 php84-ctype php84-fpm php84-gd openssl \
        php84-opcache s6 tzdata php84-iconv php84-pdo_mysql php84-pdo_pgsql php84-openssl php84-simplexml php84-zip \
# Stabilize php config location
    && mv /etc/php84 /etc/php \
    && ln -s /etc/php /etc/php84 \
    && ln -s $(which php84) /usr/local/bin/php \
# Remove (some of the) default nginx & php config
    && rm -f /etc/nginx.conf /etc/nginx/http.d/default.conf /etc/php/php-fpm.d/www.conf \
    && rm -rf /etc/nginx/sites-* \
# Ensure nginx logs, even if the config has errors, are written to stderr
    && ln -s /dev/stderr /var/log/nginx/error.log \
# Create required directories
    && mkdir -p /srv/data \
# Support running s6 under a non-root user
    && mkdir -p /etc/s6/services/nginx/supervise /etc/s6/services/php-fpm84/supervise \
    && mkfifo \
        /etc/s6/services/nginx/supervise/control \
        /etc/s6/services/php-fpm84/supervise/control \
    && chown -R ${UID}:${GID} /etc/s6 /run /srv/* /var/lib/nginx /var/www \
    && chmod o+rwx /run /var/lib/nginx /var/lib/nginx/tmp

# Copy Project's source code
COPY --chown=${UID}:${GID} . /var/www/

# Move required directories to /srv and update index.php
# ===================================================================
# PROD code (copies also tpl and lib directory)
# RUN cd /var/www \
    # && mv bin cfg lib tpl vendor /srv \
    # && sed -i "s#define('PATH', '');#define('PATH', '/srv/');#" index.php
# -------------------------------------------------------------------
# DEV code (copies only bin, cfg and vendor directories - lib and tpl are mounted as volumes)
RUN cd /var/www \
    && mv bin cfg vendor /srv \
    && mkdir /srv/tpl \
    && mkdir /srv/lib \
    && sed -i "s#define('PATH', '');#define('PATH', '/srv/');#" index.php
# ===================================================================

COPY etc/ /etc/

WORKDIR /var/www

USER ${UID}:${GID}

# mark dirs as volumes that need to be writable, allows running the container --read-only
VOLUME /run /srv/data /tmp /var/lib/nginx/tmp

EXPOSE 8080

ENTRYPOINT ["/etc/init.d/rc.local"]
