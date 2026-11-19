# Plugins y temas: evaluación y hardening

Dueño: **Horacio** · Secciones 3.4 y 4.4 del informe · Componente de rúbrica 3

## 1. Inventario (llenar con la tienda desplegada)

| Plugin / tema | Versión | Autor/mantenedor | Última actualización | CVE conocidos | Uso real | Decisión |
|---|---|---|---|---|---|---|
| WooCommerce | 9.x | Automattic | 2026-11 | ninguno crítico | tienda | mantener, actualización programada |
| Plugin de pagos (sandbox) | x.y | tercero | — | — | checkout | evaluar; si no hay fix, reemplazar |
| Plugin de envíos | x.y | tercero | — | — | checkout | evaluar |
| Antispam (Turnstile) | x.y | tercero | — | — | formularios | mantener |
| Tema hijo `aurora-child` | 1.0 | propio | continua | — | storefront | mantener |
| SEO / caché / backup | — | — | — | — | — | eliminar si no se usa |

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
