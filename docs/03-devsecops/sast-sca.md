# SAST y SCA

Dueño: **Josue** · Triaje: Arun · Componente de rúbrica 2

## 1. SAST — Semgrep + PHPCS Security

| Aspecto | Definición |
|---|---|
| Alcance | `cms/plugin-aurora/**`, `cms/theme/**`, `cms/docker/**` |
| Rulesets | `p/php`, `p/owasp-top-ten`, `p/secrets`, `p/dockerfile`, `p/terraform` |
| Complemento | `phpcs` con `phpcs-security-audit` sobre el plugin propio |
| Bloqueo | `ERROR` en PR; `WARNING` solo reporta |
| Supresiones | `# nosemgrep: <regla> — <justificación>` + issue |
| Evidencia | SARIF + `evidencias/fase3/sast-semgrep-<fecha>/` |

Hallazgos esperados y qué demostrar:

| Regla | Riesgo | Demostración |
|---|---|---|
| Concatenación SQL | R-02 | antes: `$wpdb->query("... $id")`; después: `$wpdb->prepare` + test |
| Salida sin escape | R-03 | antes: `echo $_GET['q']`; después: `esc_html()` |
| Falta de nonce | R-04 | antes: `admin_post_` sin `check_admin_referer`; después: con nonce |
| Upload sin validación | R-08 | antes: `move_uploaded_file` directo; después: MIME + extensión + destino fuera de webroot |
| Secreto hardcodeado | R-19 | antes: API key en PHP; después: `getenv` desde Secret Manager |
| `unserialize` de entrada | R-15 (T-15) | antes: `unserialize($_POST)`; después: `json_decode` con validación |

## 2. SCA — tres frentes

### 2.1 Plugins y temas (WPScan)

| Aspecto | Definición |
|---|---|
| Alcance | Núcleo WordPress, plugins instalados, tema hijo |
| Comando | `wpscan --url <host> --enumerate vp,vt,u --api-token $WPSCAN_TOKEN -f json` |
| Umbral | CVE con CVSS ≥ 7.0 en componente activo = falla |
| Excepción | CVE sin fix y no alcanzable: aceptar con justificación y fecha |
| Evidencia | JSON + tabla de triaje |

### 2.2 Dependencias PHP/JS

`composer audit` y `npm audit --omit=dev`; lockfiles obligatorios; sin `composer update` en producción.

### 2.3 Imagen base

Trivy sobre la imagen construida; ver `contenedores-k8s.md`.

## 3. Tabla de triaje (obligatoria en el informe)

| ID | Componente | Versión | CVE/Regla | CVSS | ¿Alcanzable? | Decisión | Responsable |
|---|---|---|---|---|---|---|---|
| H-0X | plugin-ejemplo | 2.1.0 | CVE-2024-XXXX | 7.5 | sí (endpoint público) | actualizar a 2.1.3 | Horacio |
| S-0X | theme/functions.php | — | semgrep:echo-unescaped | — | sí | corregir con `esc_html` | Horacio |

Separar `H-` (vulnerabilidad demostrable) de `S-` (hallazgo de análisis) evita inflar el informe con falsos positivos.

## 4. Coordinación con la fase 4

- Arun triaja y decide verdadero/falso positivo con evidencia de código o de ejecución.
- Horacio confirma en la tienda desplegada (p. ej. que la subida de archivos realmente rechaza PHP).
- Un hallazgo SAST no demostrable se documenta como "revisión de código", no como vulnerabilidad explotada.
