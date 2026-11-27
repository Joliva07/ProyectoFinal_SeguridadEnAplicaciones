# SAST y SCA

Dueño: **Josue** · Triaje del CMS: Horacio · Revisión del triaje: Arun · Componente 2.

> Estado (2026-11-26): pipeline ejecutado sobre la imagen y la tienda reales (run `45940623596`). Triaje de Arun en el §3 (issue #50); evidencia en `evidencias/fase3/triaje-sast-sca-2026-11-26.md`.

## 1. SAST — Semgrep

`.github/workflows/security-ci.yml` ejecuta Semgrep contra `p/php`, `p/owasp-top-ten` y `p/secrets`; los hallazgos ERROR bloquean el gate. El reporte SARIF se guarda como artifact de la ejecución.

Al integrarse el código de Horacio, el alcance esperado es `cms/plugin-aurora/**`, `cms/theme-aurora/**` y `cms/docker/**`. La revisión manual debe verificar como mínimo:

| Riesgo | Revisión requerida | Control a buscar |
|---|---|---|
| SQL injection | Consultas propias con variables | `$wpdb->prepare()` |
| XSS | Salida de datos de usuario | `esc_html()`, `esc_attr()` o escape contextual |
| CSRF | Acciones de administración y formularios | nonce + validación de capacidades |
| Upload abusivo | Subida de contenido | MIME, extensión, tamaño y almacenamiento no ejecutable |
| Secretos | Claves y credenciales | Secret Manager/runtime; nunca en código o capas |
| Deserialización | Entrada externa | evitar `unserialize()` o usar estructura validada |

No añadir supresiones Semgrep sin regla, motivo, enlace de issue y revisión. Un hallazgo de SAST no confirmado se describe como observación de código, no como explotación comprobada.

## 2. SCA — dependencias PHP/JavaScript

`cms/composer.json` fija el contrato PHP del runtime (`^8.3`) y `composer.lock` permite reproducir la resolución. El gate descarga Composer 2.11.3 desde el origen oficial y verifica SHA-256 antes de ejecutar `composer audit --locked`. La lista real de bibliotecas debe completarse al recibir el Dockerfile/plugin de Horacio.

Si se añade `cms/package.json`, también debe entrar `cms/package-lock.json`; CI usa `npm ci --ignore-scripts` y `npm audit --omit=dev --audit-level=high`. No existe hoy manifiesto JS, por lo que ese subanálisis queda condicionado a que aparezcan dependencias.

WPScan enumera plugins y temas instalados en el storefront activo en ejecuciones sobre `main`, manuales y semanales. `.github/scripts/wpscan-threshold.py` bloquea CVSS ≥ 7.0. El resultado no equivale a un análisis de una imagen o una rama de PR.

| Elemento | Fuente de versión | Estado observado |
|---|---|---|
| Núcleo WordPress | `cms/docker/Dockerfile` | 7.1.5, última publicada, 0 CVE (#48) |
| Plugins y tema | `cms/docker/Dockerfile` (versión + SHA-256) | WooCommerce 11.3.1, Two Factor 0.17.0, Twenty Twenty-Five 1.5; 0 CVE en la versión instalada (#48) |
| Bibliotecas Composer | `composer.json` + `composer.lock` | Solo contrato PHP (`packages: 0`); las 20 dependencias empaquetadas de WooCommerce las cubre Trivy (`composer-vendor`, 0 vulnerabilidades) |
| Dependencias npm | `package.json` + `package-lock.json` | No hay manifest JS |
| Imágenes | Trivy sobre `aurorashop-php` y `aurorashop-nginx` | Alpine 3.24.4: 0 vulnerabilidades, 0 secretos |

## 3. Triaje para el informe

Triaje: **Arun**, 2026-11-26, sobre el run `45940623596`. Semgrep: 3 resultados, todos suprimidos en el código. gitleaks, Checkov, Trivy y `composer audit`: 0. WPScan: 57 entradas históricas de WooCommerce. Detalle en `evidencias/fase3/triaje-sast-sca-2026-11-26.md`.

| ID | Componente | Versión | CVE/regla | CVSS | Alcanzable | Decisión | Responsable | Evidencia |
|---|---|---|---|---:|---|---|---|---|
| S-01 | `cms/docker/nginx/nginx.conf:42` | imagen `2f98a53` | Semgrep `request-host-used` (CWE-290) | — | No: `$host` solo va al log JSON con `escape=json`; no se usa para enrutar ni redirigir | **Falso positivo**; la supresión queda, con su motivo en línea | Arun | §2 de la evidencia |
| S-02 | `infra/modules/data/main.tf:135` (bucket `access_logs`) | `2f98a53` | Semgrep `gcp-cloud-storage-logging` (CWE-778) | — | No: es el bucket que recibe los logs; registrarse a sí mismo sería recursivo (igual que `CKV_GCP_62`) | **Falso positivo por diseño**; se acepta | Arun | §2 de la evidencia |
| S-03 | `infra/modules/data/main.tf:289` (Cloud SQL) | `2f98a53` | Semgrep `gcp-sql-database-ssl-insecure-value` (CWE-326) | — | No en la práctica: IP privada, sin `ipv4_enabled`, autenticación IAM, y el pod entra por `cloud-sql-proxy` 2.28.0 (mTLS hacia el puerto 3307) | **Aceptado** con `ENCRYPTED_ONLY`. Acción: el `nosemgrep` no tiene motivo en línea, lo que incumple la regla del §1; añadir el motivo y el enlace a #50 | Josue | `infra/k8s/base/deployment.yaml:175`, `networkpolicy.yaml:62` |
| S-04 | `.github/scripts/wpscan-threshold.py` | `2f98a53` | Gate CVSS ≥ 7 de WPScan | — | Sí: la API free devuelve 0 de 57 entradas con `cvss`, el script no compara nada y pasa en verde. Un CVE crítico sin corregir no rompería el pipeline | **Mitigar**: comparar `fixed_in` contra `WOOCOMMERCE_VERSION`/`TWO_FACTOR_VERSION` del `Dockerfile` y fallar si `fixed_in` > instalada, o fallar si una vulnerabilidad no trae CVSS. Riesgo R-23/R-01 | Josue | §3 de la evidencia |
| S-05 | WooCommerce (WPScan) | 11.3.1 (WPScan no la detecta: versión oculta, P-04) | 57 entradas, la más reciente CVE-2026-125801 (`fixed_in` 11.3.0) | 6.5–7.5 (según #48) | No: todas corregidas en ≤ 11.3.0 | **Falso positivo de versión**; se mantiene WooCommerce 11.3.1 | Horacio | §3 de la evidencia; `evaluacion-plugins.md` EV-48-02 |
| S-06 | `.checkov.yaml` → `CKV2_GCP_18` | `2f98a53` | Checkov "red `default` con reglas abiertas" suprimido | — | Sí: la justificación dice *"sin red default"*, pero la red `default` del proyecto sí existe con SSH/RDP abiertos a `0.0.0.0/0` (P-11). Checkov no la ve porque no está en Terraform | **Mitigar**: borrar la red `default` (o importarla y cerrarla) y corregir el comentario de la supresión. Riesgo R-12 | Josue | `superficie-ataque.md` P-11 |
| S-07 | `.checkov.yaml` → `CKV_GCP_66` | `2f98a53` | Binary Authorization desactivado | — | Parcial: un actor con permisos de deploy podría desplegar una imagen no verificada | **Aceptado** (ya en `iac-hardening.md`); compensado con el deploy por digest (PR #67) y WIF limitado a `main`. Revisión el 9-dic | Josue | `.checkov.yaml`, PR #67 |
| S-08 | kubesec `Deployment/aurorashop` | `dev`/`staging`/`demo` | consejo `HostUsers` (user namespaces) | — | No: es una recomendación, sin puntos críticos (score 18) | **Aceptado**; se revisa en el hardening final (#57) | Josue | artefacto `iac-reports` |

Las otras 11 supresiones de `.checkov.yaml` se revisaron una por una: cada una tiene motivo y corresponde a un control de Autopilot no configurable, a uno que el análisis estático no puede leer o a uno ya cubierto de otra forma. La única cuyo motivo no coincide con la realidad es `CKV2_GCP_18` (S-06).

**Resultado:** 0 CVE explotables en la versión desplegada. Hay 2 debilidades reales de proceso (S-04, S-06) y 1 supresión sin motivo (S-03). Ningún `S-NN` se promueve a `H-NN`, porque ninguno tiene una prueba de explotación contra la tienda.

Los hallazgos demostrados se registran como `H-NN`; observaciones SAST/SCA sin prueba de impacto como `S-NN`. Por cada CVE se anota versión corregida y commit de actualización. Las excepciones requieren motivo, responsable y fecha de revisión.

## 4. Coordinación

Horacio entrega las dependencias y la imagen del CMS; Josue integra el escaneo y automatiza el gate. Arun revisa falsos positivos y aceptación de riesgo. Los reportes originales se archivan en `evidencias/fase3/` después de que la CI ejecute.
