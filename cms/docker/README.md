# cms/docker — Imagen endurecida de WordPress + WooCommerce (issue #40)

Responsable: Horacio. Un solo `Dockerfile` produce **dos imágenes** que en GKE corren como dos contenedores del mismo pod:

| Imagen (target) | Contenido | Puerto | Usuario |
|---|---|---|---|
| `php` | PHP-FPM 8.3 + WordPress + WooCommerce | `127.0.0.1:9000` | 10001 |
| `nginx` | Nginx con reglas de hardening y archivos estáticos | `8080` | 10001 |

## Archivos

| Archivo | Qué hace |
|---|---|
| `Dockerfile` | Multi-stage: (1) descarga y verifica WooCommerce con herramientas que no llegan a la imagen final; (2) imagen PHP; (3) imagen Nginx |
| `php/zz-aurora.ini` | `php.ini` endurecido: sin `expose_php`, funciones peligrosas deshabilitadas, `open_basedir`, límites de subida, cookies seguras |
| `php/zzz-aurora-pool.conf` | Pool FPM: solo escucha en localhost, solo ejecuta `.php`, workers sin variables de entorno |
| `bin/aurora-entrypoint.sh` | Al arrancar: genera la configuración, borra los secretos del entorno y lanza PHP-FPM. Se niega a correr como root |
| `bin/generate-config.php` | Escribe `/run/aurora/config.php` con los secretos desde **variables de entorno** (solo local) o **Secret Manager** (GKE, con la identidad del pod y sin claves JSON) |
| `wordpress/wp-config.aurora.php` | `wp-config.php` sin secretos: editor deshabilitado, sin instalar plugins desde el admin, debug apagado, bloqueo de HTTP saliente. Queda fuera del webroot |
| `nginx/*.conf` | `xmlrpc.php` → 403, sin PHP en `uploads`, archivos ocultos y sensibles bloqueados, cabeceras de seguridad, rate limit en login, log JSON con `request_id` |
| `compose.yaml` + `env.example` | Entorno **local** de pruebas con MySQL 8, contenedores read-only y sin capabilities |

## Validación local (criterio de cierre del #40)

Última ejecución completa: [`evidencias/fase2/docker-2026-11-24/`](../../evidencias/fase2/docker-2026-11-24/fase2-imagen-cms-validacion-2026-11-24.txt).

Los comandos son para **PowerShell**. Usa `curl.exe`, no `curl`, porque en PowerShell `curl` es un alias de otro comando.

### 0. Preparar

```powershell
cd cms/docker
Copy-Item env.example .env
notepad .env        # cambia las dos contrasenas
```

### 1. Construir (este paso descarga de internet)

Descarga las imágenes base (`wordpress`, `nginx`, `alpine`, `mysql`) desde Docker Hub y WooCommerce desde wordpress.org.

```powershell
docker compose build
```

El build verifica el SHA-256 del zip de WooCommerce (`woocommerce.zip: OK`). Si actualizas `WOOCOMMERCE_VERSION`, deja `WOOCOMMERCE_SHA256` vacío, copia el hash que imprime el build en el aviso y fíjalo.

### 2. Levantar

```powershell
docker compose up -d
docker compose ps          # php y nginx deben quedar "healthy"
docker compose logs php    # debe decir "configuracion escrita en /run/aurora/config.php"
```

Abre http://localhost:8080, instala WordPress con un usuario de prueba y activa WooCommerce en *Plugins*.

### 3. Checklist del issue

| # | Prueba | Comando | Esperado |
|---|---|---|---|
| 1 | Imagen < 400 MB | `docker images aurorashop/*` | Ambas < 400 MB |
| 2 | No root (php) | `docker compose exec php id` | `uid=10001` |
| 3 | No root (nginx) | `docker compose exec nginx id` | `uid=10001` |
| 4 | Sin herramientas de build ni gestor de paquetes | `docker compose exec php sh -c "command -v gcc make git composer curl apk; echo fin"` | Solo imprime `fin` |
| 5 | La tienda responde | `curl.exe -I http://localhost:8080/` | `200` (o `302` a la instalación) |
| 6 | XML-RPC bloqueado | `curl.exe -I http://localhost:8080/xmlrpc.php` | `403` |
| 7 | Sin versión en cabeceras | `curl.exe -I http://localhost:8080/` | `Server: nginx` sin número; sin `X-Powered-By` |
| 8 | Cabeceras de seguridad | mismo comando | `X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy`, `X-Request-ID` |
| 9 | Archivos sensibles | `curl.exe -I http://localhost:8080/readme.html` y `/.env`, `/wp-config.php`, `/wp-content/plugins/woocommerce/readme.txt` | `403` o `404` |
| 10 | Código de solo lectura | `docker compose exec php touch /srv/aurora/html/prueba` | `Read-only file system` |
| 11 | Secretos fuera del entorno | `docker compose exec php grep -c PASSWORD /proc/1/environ` | `0` |
| 12 | Sin PHP en uploads | ver abajo | `403` |
| 13 | Rate limit de login | ver abajo | Aparecen `429` después de ~6 peticiones |

Prueba 12 (crea un archivo PHP en uploads, comprueba que no se ejecuta y lo borra):

```powershell
docker compose exec php sh -c "echo '<?php echo 1;' > /srv/aurora/html/wp-content/uploads/prueba.php"
curl.exe -I http://localhost:8080/wp-content/uploads/prueba.php      # esperado: 403
docker compose exec php rm /srv/aurora/html/wp-content/uploads/prueba.php
```

Prueba 13 (20 peticiones seguidas al login):

```powershell
1..20 | ForEach-Object { curl.exe -s -o NUL -w "%{http_code} " http://localhost:8080/wp-login.php }
```

### 4. Guardar evidencia

Guarda las salidas en `evidencias/fase2/docker-AAAA-MM-DD/` (comando, salida y fecha), según `CONTRIBUTING.md`. Revisa que no aparezcan contraseñas.

### 5. Apagar

```powershell
docker compose down        # conserva la base de datos
docker compose down -v     # borra todo (base de datos y uploads)
```

## Paso a GKE (para Josue, #38, #39 y #43)

### Secretos: la imagen soporta tres modos (`AURORA_SECRETS_SOURCE`)

| Modo | Cuándo | Qué necesita |
|---|---|---|
| `env` | Solo local (`AURORA_ENV=local`); en otro ambiente el contenedor se niega a arrancar | Variables en `.env` |
| `files` | GKE con **Secret Manager CSI driver** (lo que indica `arquitectura-seguridad.md`) | `SecretProviderClass` que monte cada secreto como archivo en `AURORA_SECRETS_DIR` (por defecto `/var/secrets/aurora`), con el nombre del secreto como nombre de archivo |
| `gsm` | GKE sin CSI driver | `GCP_PROJECT_ID`; el contenedor llama a la API con la identidad del pod |

En los dos modos de GKE:

| Secreto (nombre por defecto) | Contenido | Variable para cambiar el nombre |
|---|---|---|
| `aurorashop-db-password` | Contraseña del usuario de la app en Cloud SQL (texto plano) | `GSM_SECRET_DB_PASSWORD` |
| `aurorashop-auth-keys` | JSON `{"AUTH_KEY":"…","SECURE_AUTH_KEY":"…","LOGGED_IN_KEY":"…","NONCE_KEY":"…"}` | `GSM_SECRET_AUTH_KEYS` |
| `aurorashop-salts` | JSON `{"AUTH_SALT":"…","SECURE_AUTH_SALT":"…","LOGGED_IN_SALT":"…","NONCE_SALT":"…"}` | `GSM_SECRET_SALTS` |

El prefijo `aurorashop-` coincide con la condición IAM de `sa-gke-workload` (`secretAccessor` sobre `aurorashop-*`). Si falta un secreto o el JSON está incompleto, el contenedor no arranca y el log dice cuál es.

### Pod

- Dos contenedores (`php` y `nginx`) con `runAsUser: 10001`, `runAsGroup: 10001`, `fsGroup: 10001`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false` y `capabilities.drop: [ALL]`.
- `emptyDir` en `/tmp` (ambos contenedores) y en `/run/aurora` (php, idealmente `medium: Memory`).
- Volumen compartido en `/srv/aurora/html/wp-content/uploads` (de solo lectura en nginx).
- ConfigMap: `AURORA_ENV=production`, `AURORA_SECRETS_SOURCE=files` (o `gsm` + `GCP_PROJECT_ID`), `DB_HOST`, `DB_NAME`, `DB_USER`, `WP_HOME=https://aurorashop.ancordss.me.uk`, `DISABLE_WP_CRON=true` (con un CronJob).
- `DB_HOST`: IP privada de Cloud SQL, o `127.0.0.1` si se usa Cloud SQL Auth Proxy como sidecar.
- KSA vinculada a `sa-gke-workload` por Workload Identity.
- Probes: `GET /healthz` en el 8080 (nginx) y TCP en el 9000 (php).
- Pendiente: `set_real_ip_from` en Nginx con los rangos del balanceador, para que el rate limit use la IP real del cliente.

## Dependencias externas (estado al 2026-11-24)

Revisión de Javier en el proyecto GCP: **Secret Manager vacío, sin instancias de Cloud SQL y sin `sa-gke-workload` ni `sa-gh-deployer`** (solo la cuenta por defecto de Compute).

| Falta | Responsable | Issue |
|---|---|---|
| Cuentas `sa-gke-workload` y `sa-gh-deployer`, pool WIF | Javier | #30 |
| Cloud SQL (instancia, base de datos y usuario de la app) | Josue | #38 |
| Secretos `aurorashop-*` en Secret Manager | Josue (Terraform crea el secreto; el valor se carga fuera del repo) | #38 |
| CSI driver o API, Workload Identity y ConfigMap | Josue | #39 |
| Build, push y deploy de esta imagen | Josue | #43 |
