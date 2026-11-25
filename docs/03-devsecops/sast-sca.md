# SAST y SCA

Dueño: **Josue** · Triaje del CMS: Horacio · Revisión del triaje: Arun · Componente 2.

> Estado: reglas y automatización definidas. El repositorio aún no tiene plugin/tema PHP ni instancia publicada para producir hallazgos del producto. No se registran resultados inventados.

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
| Núcleo WordPress | Imagen de Horacio / instalación | Pendiente: Dockerfile e instancia no están en el repo |
| Plugins y tema | Instalación WooCommerce | Pendiente: sin inventario instalado |
| Bibliotecas Composer | `composer.json` + `composer.lock` | Solo contrato PHP, sin paquetes PHP de aplicación |
| Dependencias npm | `package.json` + `package-lock.json` | No hay manifest JS |

## 3. Triaje para el informe

| ID | Componente | Versión | CVE/regla | CVSS | Alcanzable | Decisión | Responsable | Evidencia |
|---|---|---|---|---:|---|---|---|---|
| — | — | — | — | — | — | Sin resultados ejecutados | — | Pendiente de CI |

Los hallazgos demostrados se registran como `H-NN`; observaciones SAST/SCA sin prueba de impacto como `S-NN`. Por cada CVE se anota versión corregida y commit de actualización. Las excepciones requieren motivo, responsable y fecha de revisión.

## 4. Coordinación

Horacio entrega las dependencias y la imagen del CMS; Josue integra el escaneo y automatiza el gate. Arun revisa falsos positivos y aceptación de riesgo. Los reportes originales se archivan en `evidencias/fase3/` después de que la CI ejecute.
