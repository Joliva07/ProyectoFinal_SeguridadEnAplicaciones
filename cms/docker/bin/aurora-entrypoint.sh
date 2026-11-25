#!/bin/sh
# AuroraShop — entrypoint del contenedor PHP (issue #40)
# 1. Genera config.php (secretos del CSI driver en GKE; de variables de entorno en local).
# 2. Borra los secretos del entorno del proceso.
# 3. Arranca PHP-FPM.
set -eu

if [ "$(id -u)" = "0" ]; then
  echo "[aurora-entrypoint] ERROR: el contenedor no debe correr como root" >&2
  exit 1
fi

umask 077
# open_basedir propio del generador: su codigo, las salidas posibles y el volumen de secretos
SECRETS_DIR="${AURORA_SECRETS_DIR:-${WP_SECRET_DIR:-/var/run/aurorashop-secrets}}"
php -d open_basedir="/usr/local/lib/aurora/:/run/aurora/:/tmp/:${SECRETS_DIR%/}/" \
    /usr/local/lib/aurora/generate-config.php

# Los secretos ya estan en el archivo; no deben quedar en /proc/1/environ
unset DB_PASSWORD \
      AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY \
      AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT

# Archivos subidos legibles por Nginx (mismo UID/GID), no por otros
umask 027
exec "$@"
