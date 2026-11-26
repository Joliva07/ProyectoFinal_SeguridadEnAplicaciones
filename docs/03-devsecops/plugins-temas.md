# Plugins y temas: evaluación y hardening

Dueño: **Horacio** · Secciones 3.4 y 4.4 del informe · Componente de rúbrica 3

## 1. Inventario (tienda desplegada, corte 2026-11-25)

| Plugin / tema | Versión | Autor/mantenedor | Última actualización | CVE conocidos | Uso real | Decisión |
|---|---|---|---|---|---|---|
| WooCommerce | 11.3.1 (última) | Automattic | 2026-11-19 | 0 que afecten a 11.3.1 (101 históricas, corregidas) | tienda, carrito, checkout | mantener; actualización por PR |
| Two Factor (must-use) | 0.17.0 (última) | equipo de WordPress | 2026-09-28 | 0 que afecten (CVE-2026-100508 corregida en 0.17.0) | 2FA del personal (#44) | mantener |
| `aurora-hardening` (must-use) | repo | propio | continua | — (Semgrep sin hallazgos) | hardening del CMS (#44) | mantener |
| Tema Twenty Twenty-Five | 1.5 (última) | equipo de WordPress | 2026-05-20 | ninguno | storefront | mantener |
| Plugin de pagos / envíos | — | — | — | — | se usan los métodos del propio WooCommerce | no admitido |
| Antispam (Turnstile) | — | — | — | — | se aplica en Cloudflare, no como plugin | no admitido |
| Tema hijo `aurora-child` | — | propio | — | — | todavía no existe | pendiente; debe pasar §2 antes de entrar |
| SEO / caché / backup | — | — | — | — | sin uso; los respaldos son de la infraestructura, no del CMS | no admitido |
| Akismet, Hello Dolly, Twenty Twenty-Three/Four | — | — | — | — | sin uso | eliminados en el `Dockerfile` |

Detalle de CVE, alcanzabilidad y evidencias: `docs/04-ciberdefensa/evaluacion-plugins.md`.

Regla: **todo plugin que no tenga uso demostrable se elimina**. Cada plugin activo debe tener: versión fija, justificación, CVE revisados y plan de actualización.

## 2. Criterios de admisión de un plugin

| Criterio | Umbral |
|---|---|
| Mantenimiento | actualización en los últimos 12 meses |
| CVE abiertos | ninguno con CVSS ≥ 7 sin fix |
| Código | sin `eval`, `base64_decode` de entrada, `unserialize` de usuario, `exec` |
| Permisos | no requiere `administrator` para operar |
| Salida | usa escape (`esc_html`, `esc_attr`, `wp_kses`) |
| SQL | `$wpdb->prepare` en toda consulta con variables |
| Superficie | sin endpoints públicos innecesarios ni webhooks sin firma |

## 3. Hardening aplicado

| Control | Implementación | Verificación |
|---|---|---|
| Actualizaciones | auto-update solo en `staging`; producción por PR con WPScan | PR + reporte |
| Editor deshabilitado | `DISALLOW_FILE_EDIT` y `DISALLOW_FILE_MODS` en producción | `wp-config` |
| Instalación de plugins | deshabilitada en producción (`DISALLOW_FILE_MODS`) | intento fallido documentado |
| Versiones ocultas | quitar `meta generator`, `readme.html`, `?ver=` innecesario | `curl` |
| XML-RPC | deshabilitado en Nginx/Cloudflare; solo si un plugin lo exige | `curl /xmlrpc.php` → 403/405 |
| Uploads | sin ejecución PHP; validación MIME y tamaño | subir `.php` → rechazo |
| Roles | `administrator` solo 2 personas; `editor` sin `install_plugins` | `wp user list --fields=roles` |
| Integridad | checksums de núcleo + hash de plugins contra baseline | script + alerta |
| Aislamiento | plugins de terceros en su propio directorio de solo lectura | manifiesto |

## 4. Evidencia

- `wpscan --enumerate vp,vt,u` con tabla de CVEs y decisión.
- `curl -i` de `xmlrpc.php`, `readme.html` y `?author=1`.
- Intento de subida de `shell.php` y respuesta del servidor.
- `wp plugin list --fields=name,version,status,update` (redactado).
- Diff del `wp-config` endurecido.
