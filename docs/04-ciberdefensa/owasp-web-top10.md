# OWASP Web Top 10 (2021)

Dueños: **Horacio** (pruebas) · **Arun** (verificación y mapeo a WAF) · Sección 3.3 del informe · Issue #47 · Corte: 2026-11-26

## 1. Matriz

Estado: **mitigado** (control probado y funcionando), **parcial** (control presente con brecha documentada), **abierto** (sin control). Las pruebas `Ax-n` están en `evidencias/fase2/owasp-abuso-superficie-2026-11-26.md`.

| Código | Categoría | Prueba realizada | Estado | Hallazgo | Control |
|---|---|---|---|---|---|
| A01 | Broken Access Control | Dos clientes: B intenta leer el pedido de A por la cuenta, por la URL de confirmación (con la clave correcta), por la Store API y por REST `wc/v3`; anónimo lista clientes (A01-0..6) | Mitigado | Ninguno: WooCommerce comprueba la propiedad del pedido; REST `wc/v3` responde 401 sin credenciales | Autorización por objeto de WooCommerce; `/wp/v2/users` 401 por cualquier ruta (#44) |
| A02 | Cryptographic Failures | Versiones TLS aceptadas en el borde (`openssl s_client`), cabeceras, flags de cookies, hash de contraseñas, secretos | Parcial | **P-07:** Cloudflare acepta TLS 1.0. **P-08:** sin HSTS | TLS 1.2/1.3 disponibles; cookies `secure; HttpOnly`; contraseñas con bcrypt (`$wp$`); secretos en Secret Manager por CSI; Cloud SQL con CMEK, sin IP pública y con `ENCRYPTED_ONLY` |
| A03 | Injection | XSS reflejado en búsqueda general y de productos; SQLi (booleana, `UNION`, `SLEEP`) en la Store API y en `orderby` (A03-1..6) | Mitigado | Ninguno: el payload sale escapado y no hay errores SQL ni retrasos | Escape del núcleo/WooCommerce; consultas preparadas; Cloud Armor `sqli-v33` y `xss-v33`; `DISALLOW_UNFILTERED_HTML` (#44) |
| A04 | Insecure Design | Store API: precio manipulado, cantidad negativa, cupón aplicado dos veces, cupón inventado, petición sin nonce (A04-1..5) | Mitigado | Ninguno: el servidor recalcula el total e ignora el precio enviado | Recálculo en servidor; nonce obligatorio en la Store API; cupón con límite de uso |
| A05 | Security Misconfiguration | `curl` a 28 rutas sensibles en producción (`readme.html`, `.git/config`, `.env`, `wp-config.php.bak`, `debug.log`, instalador, `uploads/`), métodos `OPTIONS`/`TRACE`, cabeceras | Parcial | **P-11:** red `default` de GCP con SSH/RDP abiertos a `0.0.0.0/0` (sin VMs). **P-12:** `wp-cron.php` público | Todas las rutas sensibles 403/404; `OPTIONS`/`TRACE` 405; cabeceras de seguridad presentes; `DISALLOW_FILE_EDIT`/`MODS`; sin `WP_DEBUG` |
| A06 | Vulnerable and Outdated Components | Inventario + CVE (#48), WPScan en CI, Trivy de imagen | Mitigado | Ninguno: 0 CVE en las versiones instaladas, todas en su última versión | Versiones y SHA-256 fijados en el `Dockerfile`; WPScan y Trivy como gate del pipeline |
| A07 | Identification and Authentication Failures | Ráfaga a `wp-login.php`; enumeración por `?author=`, sitemap y REST; flujo 2FA y bloqueo (#44) | Mitigado | Ninguno en la app. Relacionado: **P-09** (`admin-` sin Access) | Rate limit de Cloudflare (429 al tercer intento) y de Nginx; 2FA obligatorio para el personal; bloqueo 15 min tras 5 fallos; mensajes genéricos |
| A08 | Software and Data Integrity Failures | Imagen desplegada frente a la publicada; condición de WIF; acciones del workflow; integridad de plugins | Parcial | **P-13:** `main` sin *branch protection* (un push directo dispara el deploy) | Deploy por digest verificado (PR #67); WIF limitado a este repo y a `main`; acciones fijadas por SHA; zips con SHA-256; `DISALLOW_FILE_MODS`; FS de solo lectura |
| A09 | Security Logging and Monitoring Failures | Formato de logs de Nginx; trazabilidad del 429 | Parcial | Alertas AL-01..AL-05 aún no probadas (dueño: Arun, `siem.md`) | Logs JSON con `request_id`, IP real, método, ruta, estado y duración en Cloud Logging |
| A10 | SSRF | `wp_safe_remote_get` desde el pod hacia metadata de GCP, `metadata.google.internal`, `127.0.0.1:9000` y un host externo | Mitigado | Ninguno: las 4 peticiones se bloquean | `WP_HTTP_BLOCK_EXTERNAL=true` sin hosts permitidos; NetworkPolicy *default-deny* de salida |

## 2. Cómo se evidencia cada fila

- **A01:** `abuse_tests.py` con `cliente-a` y `cliente-b` en local (misma imagen que producción): la dirección del pedido de A solo aparece en la sesión de A.
- **A02:** `openssl s_client -tls1 / -tls1_2 / -tls1_3` contra el borde y `curl -D -` de cabeceras y cookies.
- **A03:** payloads en `?s=`, `?s=&post_type=product`, `wc/store/v1/products?search=` y `?orderby=`.
- **A04:** `POST /wp-json/wc/store/v1/cart/add-item` con `price` y `prices` manipulados: el total del servidor queda en 329.00.
- **A05:** tabla de 28 rutas con su código HTTP en producción.
- **A06:** `evaluacion-plugins.md` (#48).
- **A07:** 15 GET seguidos a `wp-login.php`: `200 200 429 429 …`, sin `x-request-id` (lo corta Cloudflare antes del pod).
- **A08:** `kubectl get deployment` muestra `wordpress-php@sha256:…` y `wordpress-nginx@sha256:…`.
- **A09:** línea de log JSON de Nginx con `request_id` (IP redactada).
- **A10:** salida de `wp_safe_remote_get` en el contenedor PHP.

## 3. Cobertura WAF

| Categoría | ¿Filtrable por WAF? | Regla |
|---|---|---|
| A01 | Parcial | Regla custom para `rest_route=/wp/v2/users` (recomendada; la app ya responde 401) |
| A03 | Sí | Cloud Armor `sqli-v33-stable` y `xss-v33-stable` (prioridades 100 y 110) |
| A05 | Sí | Nginx bloquea las rutas sensibles en el pod; reglas de Cloudflare según `waf-cloudflare.md` (James) |
| A06 | Parcial | Cloud Armor `cve-canary` (prioridad 120) para CVE masivos |
| A07 | Parcial | Rate limit de Cloudflare en `wp-login.php` |
| A02, A04, A08, A09, A10 | No | Diseño, pipeline y monitoreo |

Se declara explícitamente que A02, A04, A08, A09 y A10 **no se resuelven con el WAF**, para no venderlo como solución universal.

## 4. Salida

- **Mitigado:** A01, A03, A04, A06, A07, A10.
- **Parcial:** A02 (TLS 1.0 y HSTS en Cloudflare), A05 (red `default` y `wp-cron`), A08 (*branch protection*), A09 (alertas por probar).
- **Abierto:** ninguno.

Ningún hallazgo requiere cambios de diseño de la aplicación: los cuatro parciales son **configuración** de Cloudflare, GCP y GitHub. Las categorías de lógica (A01 y A04) se resuelven con el diseño de WooCommerce y se comprobaron con pruebas de abuso reales.

## 5. Verificación (Arun, #50)

Verificado el 2026-11-26 contra las evidencias de #45–#48, el triaje SAST/SCA (`docs/03-devsecops/sast-sca.md` §3) y una revisión pasiva del borde (`evidencias/fase3/triaje-sast-sca-2026-11-26.md` §4).

| Código | Estado de la matriz | Verificación | Ajuste |
|---|---|---|---|
| A01 | Mitigado | Coincide. H-09 (descargas sin sesión) corregido con regresión en #46 | — |
| A02 | Parcial | **P-07 sigue abierto**: el borde acepta TLS 1.0 y 1.1 el 2026-11-26. `pentest-caja-negra.md` lo da por corregido y hay que rectificarlo. P-08 (sin HSTS) también sigue abierto | Se mantiene Parcial |
| A03 | Mitigado | Coincide: Semgrep 0 hallazgos en el código PHP propio | — |
| A04 | Mitigado | Coincide | — |
| A05 | Parcial | Coincide (P-11, P-12). Se suman H-11 (CORS que refleja el origen con credenciales), aún reproducible, y S-06 (supresión `CKV2_GCP_18` que oculta P-11) | Se mantiene Parcial |
| A06 | Mitigado | Coincide para las versiones instaladas, pero el gate de WPScan **no bloquea** (S-04): la API free no da CVSS. Un CVE nuevo no rompería el pipeline | **Pasa a Parcial** hasta corregir S-04 |
| A07 | Mitigado | Coincide. H-10 (`SameSite`) aceptado; P-09 sigue sin Access | — |
| A08 | Parcial | Coincide (P-13). Binary Authorization aceptado (S-07) | — |
| A09 | Parcial | Coincide: AL-01..AL-08 sin probar (#54) | — |
| A10 | Mitigado | Coincide | — |

Resultado verificado: **5 mitigados** (A01, A03, A04, A07, A10), **5 parciales** (A02, A05, A06, A08, A09), **0 abiertos**.
