# SIEM: consultas y alertas

Dueño: **Arun** · Issue #41 (plantillas) y #54 (despliegue y pruebas) · Diseño: `docs/05-operaciones/siem.md`

## Origen de los datos

El sink `aurorashop-demo-security-to-bigquery` (`infra/modules/observability/main.tf`) exporta al dataset `aurorashop_demo_security_logs`:

| Log | Tabla en BigQuery | Qué contiene |
|---|---|---|
| `stdout` de `k8s_container` | `stdout_YYYYMMDD` | Access log JSON de Nginx (`aurora_json`): `remote_addr`, `method`, `uri`, `status`, `request_id`, `host`, `user_agent`, `duration` |
| `stderr` de `k8s_container` | `stderr_YYYYMMDD` | Errores de Nginx y PHP-FPM; eventos `aurora_event` de la app (#55) |
| `cloudaudit.googleapis.com/activity` | `cloudaudit_googleapis_com_activity_YYYYMMDD` | IAM, `pods/exec`, RBAC y cambios de recursos (`protopayload_auditlog`) |
| `cloudaudit.googleapis.com/system_event` | `cloudaudit_googleapis_com_system_event_YYYYMMDD` | Eventos de sistema de GCP |
| `cloudsql_database` | `cloudsql_googleapis_com_mysql_err_YYYYMMDD` y similares | Errores y conexiones de Cloud SQL |

El sink no activa `use_partitioned_tables`, así que las tablas quedan **fragmentadas por día**. Por eso las consultas leen `tabla_*` y filtran con `_TABLE_SUFFIX`.

> Los nombres de tablas y columnas salen de la configuración del sink y de la convención de exportación de Cloud Logging. Hay que confirmarlos con `bq ls aurorashop-sec-umg:aurorashop_demo_security_logs` y `bq show --schema` antes de archivar el primer resultado (#54). Una columna que todavía no tiene eventos no existe en el esquema y la consulta falla con `Unrecognized name`. No es un error de la consulta: falta el evento.

## Consultas

| ID | Archivo | Detecta | Fuente | Alerta |
|---|---|---|---|---|
| Q-01 | `queries/Q-01_fuerza_bruta.sql` | Fallos de login por IP | Nginx | AL-01 |
| Q-02 | `queries/Q-02_exploit_plugin.sql` | 403/404 concentrados en un plugin | Nginx | — |
| Q-03 | `queries/Q-03_idor_pedidos.sql` | 403 a pedidos por usuario | Nginx (proxy) + `aurora_event` | AL-02 |
| Q-04 | `queries/Q-04_card_testing.sql` | Checkouts fallidos por IP | Nginx (proxy) + `aurora_event` | AL-03 |
| Q-05 | `queries/Q-05_bypass_waf.sql` | Payloads que llegan al pod con 2xx | Nginx | — |
| Q-06 | `queries/Q-06_cambio_iam_rbac.sql` | `SetIamPolicy` y RBAC fuera del CI | Cloud Audit | AL-06 |
| Q-07 | `queries/Q-07_integridad.sql` | Hash del CMS distinto del baseline | `aurora_event` (#55) | AL-05 |
| Q-08 | `queries/Q-08_egreso_anomalo.sql` | Conexiones salientes no permitidas | Falco | — |
| Q-09 | `queries/Q-09_exec_en_pod.sql` | `kubectl exec`/`attach` en `aurorashop` | Cloud Audit | AL-04 |
| Q-10 | `queries/Q-10_host_invalido.sql` | Peticiones con `Host` ajeno que el pod sirvió | Nginx | AL-07 |
| Q-11 | `queries/Q-11_tasa_5xx.sql` | Porcentaje de 5xx por ventana | Nginx | AL-08 |

Se ejecutan así (requiere `roles/bigquery.jobUser` además de `dataViewer`):

```bash
bq query --use_legacy_sql=false --project_id=aurorashop-sec-umg < infra/siem/queries/Q-01_fuerza_bruta.sql
```

Cada resultado se archiva en `evidencias/fase5/siem/Q-NN-<fecha>.md` con el comando, el número de filas y una muestra redactada (sin IP completas).

## Alertas

Las alertas **no** salen de BigQuery: son alertas basadas en logs de Cloud Monitoring sobre Cloud Logging, con una latencia de alrededor de 1 minuto. Los filtros están en `alerts/`. BigQuery se usa para correlación, búsqueda y dashboard.
