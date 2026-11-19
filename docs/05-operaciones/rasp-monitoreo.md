# RASP, integridad y monitoreo de APIs

Dueño: **Arun** · Componente de rúbrica 4

## 1. Alcance

Detección en ejecución dentro del pod y del CMS, no solo en el borde: procesos anómalos, cambios de archivos, abuso de REST y señales de integridad de la aplicación.

## 2. Señales y reglas

| ID | Señal | Fuente | Umbral | Acción |
|---|---|---|---|---|
| RT-01 | Shell o proceso inesperado en el pod | Falco | 1 evento | alerta crítica + kill |
| RT-02 | Escritura en `/var/www/html` (root FS de solo lectura) | Falco | 1 evento | alerta |
| RT-03 | Cambio en archivos del núcleo del CMS | checksums + job | 1 archivo | alerta + comparación |
| RT-04 | Archivo PHP nuevo en uploads | auditoría de FS | 1 evento | alerta + cuarentena |
| RT-05 | Login fallido sostenido | Logging | > 20/min por IP | alerta + bloqueo WAF |
| RT-06 | 403 por pedido ajeno | logs app | > 5/10 min por usuario | alerta |
| RT-07 | Checkout anómalo (montos mínimos repetidos) | logs WooCommerce | > 10/hora por IP | alerta + challenge |
| RT-08 | Scraping de catálogo | Cloudflare + app | > 120 req/min | challenge |
| RT-09 | Exportación masiva de clientes | log de admin | > 2/hora por usuario | bloqueo + revisión |
| RT-10 | `kubectl exec` en producción | Cloud Audit Logs | 1 evento | alerta crítica |
| RT-11 | Plugin o tema activado en producción | logs de WP | 1 evento | alerta |
| RT-12 | Petición a REST con firma inválida | app | 3 en 5 min | alerta |

## 3. Implementación

- **Falco** como DaemonSet (o integración con GKE) con ruleset propio; salida a Cloud Logging y Pub/Sub.
- **Integridad:** `wp core verify-checksums` + hash SHA-256 de plugins/tema contra baseline en CI; ejecución programada cada 6 h y comparación con el commit desplegado.
- **Logs estructurados** del plugin propio: `request_id`, `user_id`, `route`, `status`, `item_id`, sin PII.
- **Métricas** de Cloud Run/GKE + Cloud Armor + Cloudflare Analytics para RT-05..RT-08.
- **RASP:** se implementa como verificación de integridad, FS de solo lectura y detección de entorno; un RASP comercial (instrumentación ofuscada) queda fuera de alcance y se declara.

## 4. Tabla de efectividad

| Regla | Prueba controlada | Resultado esperado | Evidencia |
|---|---|---|---|
| RT-01 | `kubectl exec -- sh -c 'id'` en demo | alerta en < 1 min | captura Falco |
| RT-03 | modificar `wp-config.php` en staging | alerta + diff | log |
| RT-04 | subir `.php` a uploads vía admin | rechazo + alerta | captura |
| RT-05 | 25 logins fallidos | alerta + 429 | log |
| RT-06 | 6 intentos de pedido ajeno | alerta | log + alerta |
| RT-09 | exportar clientes 3 veces | bloqueo + alerta | captura |
| RT-10 | `kubectl exec` | evento en audit log | captura |

## 5. Límites

- Sin UEBA histórico: umbrales de laboratorio, declarados como tales.
- Falco en Autopilot depende de la instrumentación disponible; si el DaemonSet no es admitido, se usa detección basada en logs y auditoría del clúster, y se documenta la limitación.
- El RASP no sustituye controles del servidor: toda decisión se revalida en la aplicación.
