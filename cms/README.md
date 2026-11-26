# cms/ — CMS y e-commerce

| Ruta | Contenido | Responsable |
|---|---|---|
| `cms/docker/` | Dockerfile multi-stage (PHP-FPM 8.3 + Nginx), `php.ini`, configuración de Nginx, entrypoint que genera `wp-config.php` desde Secret Manager | Horacio |
| `cms/plugin-aurora/` | Plugin propio (integración con la pasarela sandbox, endpoints REST, auditoría) | Horacio |
| `cms/theme-aurora/` | Tema hijo del storefront | Horacio |
| `cms/composer.json` | Dependencias PHP fijadas (lockfile obligatorio) | Josue |

`cms/docker/` y `cms/theme-aurora/` ya tienen código (fase 2). `cms/plugin-aurora/` aún no existe: el hardening del CMS vive como must-use en `cms/docker/wordpress/mu-plugins/`.

Reglas para cualquier PR de código:

- Sin secretos ni credenciales; `wp-config.php` no se versiona.
- `$wpdb->prepare` en toda consulta con variables; escape en toda salida.
- `permission_callback` y `current_user_can` en REST y acciones admin; nonces en formularios.
- Subidas validadas (MIME real, extensión, tamaño) y almacenadas fuera del webroot ejecutable.
- Logs estructurados sin PII; `request_id` por petición.
- Errores genéricos al cliente, detalle solo en el log; `WP_DEBUG` desactivado en demo.
- Núcleo de WordPress y plugins de terceros sin modificar: los cambios van en plugin/tema propios.
