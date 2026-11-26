# syntax=docker/dockerfile:1
#
# AuroraShop — imagen del CMS (issue #40)
#
# Contexto de build: cms/   (asi lo construye .github/workflows/security-ci.yml)
#   docker build --target php-runtime   -f cms/docker/Dockerfile cms
#   docker build --target nginx-runtime -f cms/docker/Dockerfile cms
#
# Dos imagenes finales = dos contenedores del Deployment infra/k8s/base/deployment.yaml:
#   php-runtime    PHP-FPM 8.3 + WordPress + WooCommerce   (127.0.0.1:9000)
#   nginx-runtime  Nginx con reglas de hardening           (8080)
#
# Ambas corren como 10001 con el codigo de solo lectura (propiedad de root). En el pod solo son
# escribibles los emptyDir del Deployment (/tmp en php; /var/cache/nginx y /var/run en nginx)
# y wp-content/uploads (bucket GCS por CSI).
#
# Etapas:
#   plugins     descarga y verifica WooCommerce (curl/unzip solo aqui)
#   wordpress   imagen oficial, solo como fuente del nucleo de WordPress
#   app         arbol final de /var/www con permisos ya aplicados
#   extensions  compila extensiones PHP (compiladores solo aqui)
#   php-runtime / nginx-runtime  imagenes finales
#
# Versiones fijadas y verificadas el 2026-11-24. La issue #48 revisa sus CVE.

ARG PHP_IMAGE=php:8.3.37-fpm-alpine3.24
ARG WORDPRESS_IMAGE=wordpress:7.1.5-php8.3-fpm-alpine
ARG NGINX_IMAGE=nginx:1.30.8-alpine
ARG ALPINE_IMAGE=alpine:3.24.4

# ---------------------------------------------------------------------------
FROM ${ALPINE_IMAGE} AS plugins

ARG WOOCOMMERCE_VERSION=11.3.1
# SHA-256 del zip. Al cambiar la version, dejar vacio: el build imprime el hash para fijarlo.
ARG WOOCOMMERCE_SHA256="1502600c738840f7f9ebfa2f11e1aaff087221a5fc5a2006c51be2d874ae2a09"
# 2FA (TOTP) del equipo de WordPress; se instala como must-use para que no se pueda desactivar (#44)
ARG TWO_FACTOR_VERSION=0.17.0
ARG TWO_FACTOR_SHA256="4d1b0f8e5d82e24876c2b4e86f119122e28a8dbaf76dfde495173226c3356f37"

RUN apk add --no-cache curl unzip

WORKDIR /build
# fetch <slug> <version> <sha256> <destino>: descarga de wordpress.org, verifica y descomprime
RUN set -eu; \
    fetch() { \
      curl -fsSL --proto '=https' --tlsv1.2 -o "$1.zip" \
        "https://downloads.wordpress.org/plugin/$1.$2.zip"; \
      if [ -n "$3" ]; then \
        echo "$3  $1.zip" | sha256sum -c -; \
      else \
        echo "AVISO: SHA256 de $1 vacio; hash calculado:" >&2; sha256sum "$1.zip" >&2; \
      fi; \
      mkdir -p "$4"; unzip -q "$1.zip" -d "$4"; rm -f "$1.zip"; \
    }; \
    fetch woocommerce "${WOOCOMMERCE_VERSION}" "${WOOCOMMERCE_SHA256}" plugins; \
    fetch two-factor  "${TWO_FACTOR_VERSION}"  "${TWO_FACTOR_SHA256}"  mu-plugins

# ---------------------------------------------------------------------------
FROM ${WORDPRESS_IMAGE} AS wordpress

# ---------------------------------------------------------------------------
FROM ${ALPINE_IMAGE} AS app

COPY --from=wordpress /usr/src/wordpress   /var/www/html
COPY --from=plugins   /build/plugins/      /var/www/html/wp-content/plugins/
COPY --from=plugins   /build/mu-plugins/   /var/www/html/wp-content/mu-plugins/
COPY docker/wordpress/mu-plugins/          /var/www/html/wp-content/mu-plugins/
COPY docker/wordpress/wp-config.aurora.php /var/www/wp-config.php

RUN set -eu; \
    cd /var/www/html; \
    # Archivos que revelan version o no se usan
    rm -f readme.html license.txt wp-config-sample.php; \
    rm -rf wp-content/plugins/akismet wp-content/plugins/hello.php; \
    find wp-content/themes -mindepth 1 -maxdepth 1 -type d ! -name twentytwentyfive -exec rm -rf {} +; \
    mkdir -p wp-content/uploads; \
    # Codigo: root y solo lectura para el proceso
    chown -R root:root /var/www; \
    find /var/www -type d -exec chmod 0755 {} +; \
    find /var/www -type f -exec chmod 0644 {} +; \
    # uploads es lo unico escribible del arbol (en GKE lo tapa el volumen GCS)
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
FROM ${PHP_IMAGE} AS php-runtime

COPY --from=extensions /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=extensions /usr/local/etc/php/conf.d/     /usr/local/etc/php/conf.d/
COPY --from=extensions /usr/local/aurora-rundeps.txt  /tmp/aurora-rundeps.txt

RUN set -eu; \
    # Parches de seguridad de Alpine publicados despues de la imagen base (Trivy)
    apk upgrade --no-cache; \
    apk add --no-cache $(cat /tmp/aurora-rundeps.txt) libcurl; \
    # Sin cliente curl en runtime (PHP usa libcurl, no el binario)
    apk del --no-cache curl; \
    rm -f /tmp/aurora-rundeps.txt; \
    cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini; \
    # La base trae /var/www/html 1777 de www-data: se reemplaza por el arbol de "app"
    rm -rf /var/www; \
    # Crear antes del COPY: COPY --chmod aplicaria 0644 tambien al directorio nuevo.
    # /run/aurora es opcional (emptyDir en memoria); sin el, la config va a /tmp/aurora.
    mkdir -p /run/aurora /usr/local/lib/aurora; \
    chown 10001:10001 /run/aurora; \
    chmod 0700 /run/aurora

COPY --from=app /var/www /var/www
COPY --chmod=0644 docker/php/zz-aurora.ini          /usr/local/etc/php/conf.d/zz-aurora.ini
COPY --chmod=0644 docker/php/zzz-aurora-pool.conf   /usr/local/etc/php-fpm.d/zzz-aurora-pool.conf
COPY --chmod=0644 docker/bin/generate-config.php    /usr/local/lib/aurora/generate-config.php
COPY --chmod=0755 docker/bin/aurora-entrypoint.sh   /usr/local/bin/aurora-entrypoint

# COPY --from no conserva el dueno de uploads; se reaplica.
# Sin gestor de paquetes en runtime (la base de datos de apk se conserva para que Trivy inventarie).
RUN chown 10001:10001 /var/www/html/wp-content/uploads && \
    chmod 0750 /var/www/html/wp-content/uploads && \
    rm -f /sbin/apk

USER 10001:10001
WORKDIR /var/www/html
EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
  CMD ["php", "-r", "exit(@fsockopen('127.0.0.1', 9000) ? 0 : 1);"]

ENTRYPOINT ["/usr/local/bin/aurora-entrypoint"]
CMD ["php-fpm"]

# ---------------------------------------------------------------------------
FROM ${NGINX_IMAGE} AS nginx-runtime

# snippets/ se crea antes del COPY: COPY --chmod aplicaria 0644 tambien al directorio nuevo
# Parches de seguridad de Alpine publicados despues de la imagen base (Trivy)
RUN apk upgrade --no-cache && \
    rm -f /etc/nginx/conf.d/default.conf && \
    mkdir -p /etc/nginx/snippets

COPY --chmod=0644 docker/nginx/nginx.conf      /etc/nginx/nginx.conf
COPY --chmod=0644 docker/nginx/aurora.conf     /etc/nginx/conf.d/aurora.conf
COPY --chmod=0644 docker/nginx/aurora-php.conf /etc/nginx/snippets/aurora-php.conf

# Mismo arbol que el contenedor PHP (Nginx sirve estaticos y comprueba que el .php exista)
COPY --from=app /var/www/html /var/www/html
RUN chown 10001:10001 /var/www/html/wp-content/uploads && \
    chmod 0750 /var/www/html/wp-content/uploads

USER 10001:10001
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/healthz"]

ENTRYPOINT ["nginx", "-g", "daemon off;"]
CMD []
