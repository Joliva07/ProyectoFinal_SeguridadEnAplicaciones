# cms/docker — Imagen endurecida de WordPress + WooCommerce (issue #40)

Responsable: Horacio. Un solo `Dockerfile` produce **dos imágenes**, que son dos contenedores del Deployment de [`infra/k8s/base/deployment.yaml`](../../infra/k8s/base/deployment.yaml):

| Target | Contenido | Puerto | Usuario | Escribible en el pod |
|---|---|---|---|---|
| `php-runtime` | PHP-FPM 8.3 + WordPress 7.1.5 + WooCommerce 11.3.1 | `127.0.0.1:9000` | 10001 | `/tmp` (emptyDir) y `wp-content/uploads` (GCS) |
| `nginx-runtime` | Nginx 1.30.8 con reglas de hardening y archivos estáticos | `8080` | 10001 | `/var/cache/nginx` y `/var/run` (emptyDir) |

Build, igual que en [`security-ci.yml`](../../.github/workflows/security-ci.yml). El contexto es `cms/`:

```bash
docker build --target php-runtime   -t aurorashop-php:ci   -f cms/docker/Dockerfile cms
docker build --target nginx-runtime -t aurorashop-nginx:ci -f cms/docker/Dockerfile cms
```

## Archivos

| Archivo | Qué hace |
|---|---|
| `Dockerfile` | Multi-stage: descarga y verifica WooCommerce (SHA-256), compila extensiones PHP sin imagick y arma las dos imágenes finales sin compiladores, `curl` ni `apk` |
| `Dockerfile.dockerignore` | Excluye `.env`, `compose.yaml` y documentación del contexto `cms/` |
| `php/zz-aurora.ini` | `php.ini` endurecido: sin `expose_php`, funciones peligrosas deshabilitadas, `open_basedir`, límites de subida, cookies seguras |
| `php/zzz-aurora-pool.conf` | Pool FPM: solo escucha en localhost, solo ejecuta `.php`, workers sin variables de entorno |
| `bin/aurora-entrypoint.sh` | Al arrancar: genera la configuración, borra los secretos del entorno y lanza PHP-FPM. Se niega a correr como root |
| `bin/generate-config.php` | Escribe `config.php` (en `/run/aurora` si existe ese emptyDir; si no, en `/tmp/aurora`, con permisos `0400`) con los secretos del **CSI driver** (GKE), de la **API de Secret Manager** o de **variables de entorno** (solo local) |
| `wordpress/wp-config.aurora.php` | `wp-config.php` sin secretos: editor deshabilitado, sin instalar plugins desde el admin, debug apagado, bloqueo de HTTP saliente. Queda fuera del webroot (`/var/www/wp-config.php`) |
| `nginx/*.conf` | `xmlrpc.php` → 403, sin PHP en `uploads` ni en `wp-content`, archivos ocultos/sensibles/`readme.txt` bloqueados, cabeceras de seguridad, rate limit en login, IP real desde `CF-Connecting-IP`, log JSON con `request_id` |
| `compose.yaml` + `env.example` | Entorno **local** que imita el pod: mismas rutas, mismos directorios escribibles, contenedores read-only y sin capabilities |

## Contrato con el Deployment de GKE

La imagen lee exactamente lo que el Deployment ya define, así que no hace falta cambiar los manifiestos:

| Variable o volumen del Deployment | Uso en la imagen |
|---|---|
| `DB_HOST=127.0.0.1`, `DB_PORT=3306` | Se combinan en `DB_HOST=127.0.0.1:3306` (cloud-sql-proxy) |
| `DB_NAME`, `DB_USER` (ConfigMap) | `aurorashop_demo` / `sa-gke-workload-demo` |
| `DB_PASSWORD=""` | Autenticación IAM con `--auto-iam-authn`: no hay contraseña |
| `WP_ENVIRONMENT_TYPE` (ConfigMap) | `production`, `staging` o `development`. Con `local` se permiten secretos en variables de entorno; con cualquier otro valor, no |
| `WP_SECRET_DIR=/var/run/aurorashop-secrets` (CSI) | Lee los archivos `auth-keys` y `salts`; `payment-sandbox` se reserva para el plugin propio |
| emptyDir `/tmp` (php) | Configuración generada en `/tmp/aurora/config.php` (`0400`) |
| emptyDir `/var/cache/nginx`, `/var/run` (nginx) | Temporales y pid de Nginx |
| GCS `wp-content/uploads` (`uid=10001`, `0640`) | Medios; Nginx lo monta de solo lectura y nunca ejecuta PHP ahí |
| Probes `/healthz` (8080) y TCP 9000 | Implementados |

Mejoras opcionales para el Deployment, que no bloquean:
- Un `emptyDir` con `medium: Memory` en `/run/aurora` del contenedor php-fpm. Así la configuración generada vive en RAM y no en disco; la imagen lo usa automáticamente si existe.
- `WP_HOME` en el ConfigMap (`https://aurorashop.ancordss.me.uk`). Si no está, WordPress usa la URL guardada en la base de datos al instalarse.

### Formato de los secretos (valores a cargar en Secret Manager)

| Secreto | Contenido |
|---|---|
| `aurorashop-<amb>-auth-keys` | JSON `{"AUTH_KEY":"…","SECURE_AUTH_KEY":"…","LOGGED_IN_KEY":"…","NONCE_KEY":"…"}` |
| `aurorashop-<amb>-salts` | JSON `{"AUTH_SALT":"…","SECURE_AUTH_SALT":"…","LOGGED_IN_SALT":"…","NONCE_SALT":"…"}` |
| `aurorashop-<amb>-payment-sandbox` | Lo define el plugin propio (`cms/plugin-aurora/`); por ahora la imagen no lo lee |

Para cargarlos sin guardar los valores en disco, alguien con permiso en Secret Manager (James o Javier) ejecuta en bash, con `<amb>` = `demo`, `staging` o `dev`:

```bash
P=aurorashop-sec-umg; AMB=demo
php -r 'foreach(["AUTH_KEY","SECURE_AUTH_KEY","LOGGED_IN_KEY","NONCE_KEY"] as $n) $k[$n]=bin2hex(random_bytes(32)); echo json_encode($k);' \
  | gcloud secrets versions add "aurorashop-$AMB-auth-keys" --project "$P" --data-file=-
php -r 'foreach(["AUTH_SALT","SECURE_AUTH_SALT","LOGGED_IN_SALT","NONCE_SALT"] as $n) $k[$n]=bin2hex(random_bytes(32)); echo json_encode($k);' \
  | gcloud secrets versions add "aurorashop-$AMB-salts" --project "$P" --data-file=-
```

Si falta un secreto o el JSON está incompleto, el contenedor php no arranca y el log dice cuál es (`[aurora-config] ERROR: ...`).

### Instalación de WordPress (una vez por ambiente)

Nginx bloquea `/wp-admin/install.php` y `setup-config.php` (403), así que nadie puede "reclamar" el sitio desde internet. WordPress se instala **desde dentro del pod** con [`bin/install-wordpress.php`](bin/install-wordpress.php).

El rol `aurorashop_runtime_*` ([`infra/sql/grant-runtime-role.sql.template`](../../infra/sql/grant-runtime-role.sql.template)) solo tiene `SELECT, INSERT, UPDATE, DELETE`. Crear las tablas exige permisos extra **solo durante la instalación**. Procedimiento (ejecutado en `demo` el 2026-11-25):

1. Usuario administrador temporal (contraseña larga, no se guarda):
   `gcloud sql users create aurora-migrate --instance=aurorashop-demo-mysql --host=% --password=...`
2. En **Cloud SQL Studio**, con ese usuario: aplicar el template del ambiente y, temporalmente,
   ``GRANT CREATE, ALTER, INDEX, REFERENCES ON `aurorashop_demo`.* TO 'sa-gke-workload-demo'@'%';``
3. Instalar (la contraseña del admin sale solo por STDOUT, a un archivo local; guardarla en un gestor y borrar el archivo):
   ```bash
   POD=$(kubectl get pods -n aurorashop -l app.kubernetes.io/name=aurorashop -o jsonpath='{.items[0].metadata.name}')
   kubectl exec -i -n aurorashop "$POD" -c php-fpm -- php -- https://aurorashop.ancordss.me.uk < cms/docker/bin/install-wordpress.php > credenciales.txt
   ```
4. Limpiar:
   ``REVOKE CREATE, ALTER, INDEX, REFERENCES ON `aurorashop_demo`.* FROM 'sa-gke-workload-demo'@'%';``
   y `gcloud sql users delete aurora-migrate --instance=aurorashop-demo-mysql --host=%`.

Las **actualizaciones** de WordPress/WooCommerce que cambien el esquema repiten los pasos 1, 2 y 4.

### Notas del primer despliegue en `demo` (2026-11-25)

- Los nodos de Autopilot usan la cuenta `<número>-compute@developer`; necesitan `roles/artifactregistry.reader` sobre el repositorio `aurorashop` para descargar las imágenes. Se dio a mano y falta en Terraform (`google_artifact_registry_repository_iam_member`).
- Cargar secretos con `--data-file=-` desde **bash**. En PowerShell 5.1 el pipe a `gcloud` agrega un BOM (`U+FEFF`) y el JSON queda inválido.
- El tag `:local` es mutable y con `imagePullPolicy: IfNotPresent` el nodo no baja una versión nueva. El pipeline despliega por digest; a mano, usar `kubectl set image ...@sha256:...`.

## Validación local

Última ejecución completa: [`evidencias/fase2/docker-2026-11-24/`](../../evidencias/fase2/docker-2026-11-24/fase2-imagen-cms-validacion-2026-11-24.txt).

Los comandos son para **PowerShell** dentro de `cms/docker`. Usa `curl.exe`, no `curl`, porque en PowerShell `curl` es un alias de otro comando.

### 1. Preparar y levantar

```powershell
cd cms/docker
Copy-Item env.example .env     # y cambia las dos contrasenas
docker compose up -d --build   # la primera vez descarga imagenes base y WooCommerce
docker compose ps              # php y nginx deben quedar "healthy"
docker compose logs php        # "configuracion escrita en /tmp/aurora/config.php"
```

Si la base de datos es nueva, instala WordPress (el instalador web está bloqueado, igual que en GKE):

```powershell
Get-Content bin/install-wordpress.php -Raw | docker compose exec -T php php -- http://localhost:8080 > credenciales-local.txt
```

Abre http://localhost:8080/wp-admin/ con el usuario y la contraseña de `credenciales-local.txt` (no lo subas al repo; bórralo después de guardar la contraseña).

### 2. Checklist del issue

| # | Prueba | Comando | Esperado |
|---|---|---|---|
| 0 | Build como el pipeline | El bloque `docker build` de arriba, desde la raíz del repo | Termina sin error |
| 0b | Trivy como el pipeline | `docker run --rm -v //var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.76.2 image --scanners vuln --severity CRITICAL --ignore-unfixed --exit-code 1 aurorashop/cms-php:local` | Sin vulnerabilidades, código de salida 0 |
| 1 | Imagen < 400 MB | `docker images aurorashop/*` | Ambas < 400 MB |
| 2 | No root (php) | `docker compose exec php id` | `uid=10001` |
| 3 | No root (nginx) | `docker compose exec nginx id` | `uid=10001` |
| 4 | Sin herramientas de build ni gestor de paquetes | `docker compose exec php sh -c "command -v gcc make git composer curl apk; echo fin"` | Solo imprime `fin` |
| 5 | La tienda responde | `curl.exe -I http://localhost:8080/` | `200` (o `302` a la instalación) |
| 6 | XML-RPC e instalador bloqueados | `curl.exe -I http://localhost:8080/xmlrpc.php` y `/wp-admin/install.php` | `403` |
| 7 | Sin versión en cabeceras | `curl.exe -I http://localhost:8080/` | `Server: nginx` sin número; sin `X-Powered-By` |
| 8 | Cabeceras de seguridad | mismo comando | `X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy`, `X-Request-ID` |
| 9 | Archivos sensibles | `curl.exe -I http://localhost:8080/readme.html` y `/.env`, `/wp-config.php`, `/wp-content/plugins/woocommerce/readme.txt` | `403` |
| 10 | Código de solo lectura | `docker compose exec php touch /var/www/html/prueba` | `Read-only file system` |
| 11 | Secretos fuera del entorno | `docker compose exec php grep -c PASSWORD /proc/1/environ` | `0` |
| 12 | Sin PHP en uploads | ver abajo | `403` |
| 13 | Rate limit de login | ver abajo | Aparecen `429` después de ~6 peticiones |
| 14 | IP real no falsificable | `curl.exe -H "CF-Connecting-IP: 6.6.6.6" http://localhost:8080/` y revisar `docker compose logs nginx` | `remote_addr` es la IP de Docker, no `6.6.6.6` |

Prueba 12 (crea un PHP en uploads, comprueba que no se ejecuta y lo borra):

```powershell
docker compose exec php sh -c "echo '<?php echo 1;' > /var/www/html/wp-content/uploads/prueba.php"
curl.exe -I http://localhost:8080/wp-content/uploads/prueba.php      # esperado: 403
docker compose exec php rm /var/www/html/wp-content/uploads/prueba.php
```

Prueba 13 (20 peticiones seguidas al login):

```powershell
1..20 | ForEach-Object { curl.exe -s -o NUL -w "%{http_code} " http://localhost:8080/wp-login.php }
```

### 3. Guardar evidencia

Guarda las salidas en `evidencias/fase2/docker-AAAA-MM-DD/` (comando, salida y fecha), según `CONTRIBUTING.md`. Revisa que no aparezcan contraseñas.

### 4. Apagar

```powershell
docker compose down        # conserva la base de datos y los uploads
docker compose down -v     # borra todo
```

### Actualizar versiones

Las versiones están fijadas en los `ARG` del `Dockerfile`. Al subir `WOOCOMMERCE_VERSION`, deja `WOOCOMMERCE_SHA256` vacío, construye, copia el hash que imprime el aviso y fíjalo. Después de cualquier cambio, repite el checklist y Trivy.
