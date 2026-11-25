# syntax=docker/dockerfile:1
#
# AuroraShop — imagen del CMS (issue #40)
#
# Dos imagenes finales desde un mismo Dockerfile (un pod = 2 contenedores):
#   --target php    -> PHP-FPM 8.3 + WordPress + WooCommerce   (puerto 9000, solo localhost)
#   --target nginx  -> Nginx con reglas de hardening           (puerto 8080)
#
# Ambas corren como el usuario sin privilegios 10001 y el codigo es de solo lectura
# (propiedad de root). Lo unico escribible es wp-content/uploads (volumen), /tmp y /run/aurora.
#
# Etapas:
#   plugins     descarga y verifica WooCommerce (curl/unzip solo aqui)
#   wordpress   imagen oficial, solo como fuente del nucleo de WordPress
#   app         arbol final de /srv/aurora con permisos ya aplicados
#   extensions  compila extensiones PHP (compiladores solo aqui)
#   php         imagen final PHP-FPM
#   nginx       imagen final Nginx
#
# Versiones fijadas y verificadas el 2026-11-24. La issue #48 revisa sus CVE.

ARG PHP_IMAGE=php:8.3.37-fpm-alpine3.24
ARG WORDPRESS_IMAGE=wordpress:7.1.5-php8.3-fpm-alpine
ARG NGINX_IMAGE=nginx:1.30.8-alpine
ARG ALPINE_IMAGE=alpine:3.24.4

# ---------------------------------------------------------------------------
FROM ${ALPINE_IMAGE} AS plugins

ARG WOOCOMMERCE_VERSION=11.3.1
# SHA-256 del zip. Vacio = se imprime el hash calculado para fijarlo despues.
ARG WOOCOMMERCE_SHA256="1502600c738840f7f9ebfa2f11e1aaff087221a5fc5a2006c51be2d874ae2a09"

RUN apk add --no-cache curl unzip

WORKDIR /build
RUN set -eu; \
    curl -fsSL --proto '=https' --tlsv1.2 -o woocommerce.zip \
      "https://downloads.wordpress.org/plugin/woocommerce.${WOOCOMMERCE_VERSION}.zip"; \
    if [ -n "${WOOCOMMERCE_SHA256}" ]; then \
      echo "${WOOCOMMERCE_SHA256}  woocommerce.zip" | sha256sum -c -; \
    else \
      echo "AVISO: WOOCOMMERCE_SHA256 vacio; hash calculado:" >&2; sha256sum woocommerce.zip >&2; \
    fi; \
    mkdir -p plugins; \
    unzip -q woocommerce.zip -d plugins; \
    rm -f woocommerce.zip

# ---------------------------------------------------------------------------
FROM ${WORDPRESS_IMAGE} AS wordpress

# ---------------------------------------------------------------------------
FROM ${ALPINE_IMAGE} AS app

COPY --from=wordpress /usr/src/wordpress /srv/aurora/html
COPY --from=plugins   /build/plugins/    /srv/aurora/html/wp-content/plugins/
COPY wordpress/wp-config.aurora.php      /srv/aurora/wp-config.php

RUN set -eu; \
    cd /srv/aurora/html; \
    # Archivos que revelan version o no se usan
    rm -f readme.html license.txt wp-config-sample.php; \
    rm -rf wp-content/plugins/akismet wp-content/plugins/hello.php; \
    find wp-content/themes -mindepth 1 -maxdepth 1 -type d ! -name twentytwentyfive -exec rm -rf {} +; \
    mkdir -p wp-content/uploads; \
    # Codigo: root y solo lectura para el proceso
    chown -R root:root /srv/aurora; \
    find /srv/aurora -type d -exec chmod 0755 {} +; \
    find /srv/aurora -type f -exec chmod 0644 {} +; \
    # uploads es lo unico escribible; mismo dueno en ambas imagenes para que el
    # volumen compartido quede con 10001 sin importar que contenedor lo cree primero
    chown 10001:10001 wp-content/uploads; \
    chmod 0750 wp-content/uploads

# ---------------------------------------------------------------------------
FROM ${PHP_IMAGE} AS extensions

# Mismas extensiones que la imagen oficial de WordPress, sin imagick
# (GD basta para WordPress/WooCommerce y ImageMagick agrega superficie de ataque).
RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
      $PHPIZE_DEPS pax-utils freetype-dev icu-dev libjpeg-turbo-dev libpng-dev libwebp-dev libzip-dev; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j"$(nproc)" bcmath exif gd intl mysqli zip; \
    docker-php-ext-enable opcache; \
    # Librerias que las extensiones necesitan en runtime
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
      | tr ',' '\n' | sort -u \
      | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
      > /usr/local/aurora-rundeps.txt; \
    cat /usr/local/aurora-rundeps.txt

# ---------------------------------------------------------------------------
FROM ${PHP_IMAGE} AS php

COPY --from=extensions /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=extensions /usr/local/etc/php/conf.d/     /usr/local/etc/php/conf.d/
COPY --from=extensions /usr/local/aurora-rundeps.txt  /tmp/aurora-rundeps.txt

RUN set -eu; \
    apk add --no-cache $(cat /tmp/aurora-rundeps.txt) libcurl; \
    # Sin cliente curl en runtime (PHP usa libcurl, no el binario)
    apk del --no-cache curl; \
    rm -f /tmp/aurora-rundeps.txt; \
    cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini; \
    # Crear antes del COPY: COPY --chmod aplicaria 0644 tambien al directorio nuevo
    mkdir -p /run/aurora /usr/local/lib/aurora; \
    chown 10001:10001 /run/aurora; \
    chmod 0700 /run/aurora

COPY --from=app /srv/aurora /srv/aurora
COPY --chmod=0644 php/zz-aurora.ini          /usr/local/etc/php/conf.d/zz-aurora.ini
COPY --chmod=0644 php/zzz-aurora-pool.conf   /usr/local/etc/php-fpm.d/zzz-aurora-pool.conf
COPY --chmod=0644 bin/generate-config.php    /usr/local/lib/aurora/generate-config.php
COPY --chmod=0755 bin/aurora-entrypoint.sh   /usr/local/bin/aurora-entrypoint

# uploads: COPY --from no conserva el dueno, se reaplica (en GKE/compose se monta un volumen encima).
# Sin gestor de paquetes en runtime (la base de datos de apk se conserva para que Trivy inventarie).
RUN chown 10001:10001 /srv/aurora/html/wp-content/uploads && \
    chmod 0750 /srv/aurora/html/wp-content/uploads && \
    rm -f /sbin/apk

USER 10001:10001
WORKDIR /srv/aurora/html
EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
  CMD ["php", "-r", "exit(@fsockopen('127.0.0.1', 9000) ? 0 : 1);"]

ENTRYPOINT ["/usr/local/bin/aurora-entrypoint"]
CMD ["php-fpm"]

# ---------------------------------------------------------------------------
FROM ${NGINX_IMAGE} AS nginx

# snippets/ se crea antes del COPY: COPY --chmod aplicaria 0644 tambien al directorio nuevo
RUN rm -f /etc/nginx/conf.d/default.conf && mkdir -p /etc/nginx/snippets

COPY --chmod=0644 nginx/nginx.conf      /etc/nginx/nginx.conf
COPY --chmod=0644 nginx/aurora.conf     /etc/nginx/conf.d/aurora.conf
COPY --chmod=0644 nginx/aurora-php.conf /etc/nginx/snippets/aurora-php.conf

# Mismo arbol que el contenedor PHP (Nginx sirve estaticos y comprueba que el .php exista)
COPY --from=app /srv/aurora/html /srv/aurora/html
RUN chown 10001:10001 /srv/aurora/html/wp-content/uploads && \
    chmod 0750 /srv/aurora/html/wp-content/uploads

USER 10001:10001
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/healthz"]

ENTRYPOINT ["nginx", "-g", "daemon off;"]
CMD []
