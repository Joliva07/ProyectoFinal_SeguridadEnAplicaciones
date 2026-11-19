# OWASP Web Top 10 (2021)

Dueños: **Horacio** (pruebas) · **Arun** (verificación y mapeo a WAF) · Sección 3.3 del informe

## 1. Matriz

| Código | Categoría | Prueba realizada | Estado | Hallazgo | Control |
|---|---|---|---|---|---|
| A01 | Broken Access Control | IDOR de pedidos, capacidades, endpoints REST sin `permission_callback` | | | autorización por objeto + nonces + capabilities |
| A02 | Cryptographic Failures | TLS, HSTS, cookies, hashes de contraseña, secretos | | | TLS 1.3, CMEK, Argon2id/bcrypt nativo, Secret Manager |
| A03 | Injection | SQLi en búsqueda y plugin propio, XSS, command injection en plugins | | | `$wpdb->prepare`, escape, sin `exec` |
| A04 | Insecure Design | reglas de cupón, límites de carrito, flujo de pago, exportaciones | | | diseño con límites y revalidación en servidor |
| A05 | Security Misconfiguration | `readme.html`, `xmlrpc`, listado, `DISALLOW_FILE_EDIT`, headers, errores | | | baseline de hardening + WAF |
| A06 | Vulnerable and Outdated Components | WPScan de núcleo/plugins/tema, Trivy de imagen | | | versiones fijadas + CI de escaneo |
| A07 | Identification and Authentication Failures | fuerza bruta, MFA, fijación de sesión, enumeración | | | 2FA, rate limit, cookies seguras |
| A08 | Software and Data Integrity Failures | despliegue, plugins, webhooks, actualizaciones | | | firma/imagen por digest, WIF, firma de webhook |
| A09 | Security Logging and Monitoring Failures | auditoría de pedidos y admin, alertas ante ataques | | | sinks + alertas probadas |
| A10 | SSRF | funcionalidad que consume URLs (importadores, webhooks) | | | allowlist de destinos y sin respuesta del destino |

## 2. Cómo se evidencia cada fila

- **A01:** PoC de dos cuentas sobre pedidos + captura del 403 tras el fix.
- **A02:** `testssl.sh` y `curl -I`; revisión de `wp-config` sin secretos.
- **A03:** payloads en búsqueda y en el shortcode del plugin; salida escapada.
- **A04:** intento de total manipulado y doble cupón; respuesta del servidor.
- **A05:** `curl` a `readme.html`, `xmlrpc.php`, `debug.log`, `.git/config`.
- **A06:** tabla WPScan con CVE y decisión.
- **A07:** 30 intentos de login → 429; MFA obligatorio en admin; cookies con flags.
- **A08:** digest de imagen desplegada ≠ latest; webhook sin firma rechazado.
- **A09:** alerta disparada en prueba controlada; logs de auditoría con autor y pedido.
- **A10:** endpoint de importación con URL externa; respuesta bloqueada.

## 3. Cobertura WAF

Cada categoría con vector HTTP se mapea a una regla en `docs/05-operaciones/waf-cloudflare.md` (CRS o regla custom). Las que no son filtrables por WAF (A04, A07 parcial, A08, A09) se cubren con diseño, pipeline y monitoreo; se declara explícitamente para no vender el WAF como solución universal.

## 4. Salida

Tabla completa con estado (mitigado / aceptado / abierto), hallazgo asociado y control; conclusión sobre qué categorías requieren cambios de diseño y no solo configuración.
