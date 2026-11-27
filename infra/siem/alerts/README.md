# Alertas AL-01..AL-08

Plantillas para Cloud Monitoring. Se crean en la #54. Hay dos tipos:

- **Alerta basada en logs** (`conditionMatchedLog`): dispara con cada entrada que cumple el filtro, con una latencia de alrededor de 1 minuto. Sirve para eventos únicos.
- **Métrica basada en logs + umbral** (`conditionThreshold`): cuenta entradas por ventana. Sirve para "más de N en M minutos". Tarda algo más, porque la métrica se alinea por minuto.

En las alertas por IP, el umbral se evalúa sobre la métrica agrupada por la etiqueta `ip` (extraída de `jsonPayload.remote_addr`).

| ID | Severidad | Tipo | Filtro de Cloud Logging | Umbral | Plantilla |
|---|---|---|---|---|---|
| AL-01 Fuerza bruta | alta | métrica `aurora/login_fallido` (etiqueta `ip`) | `resource.type="k8s_container" resource.labels.namespace_name="aurorashop" resource.labels.container_name="nginx" jsonPayload.method="POST" jsonPayload.uri="/wp-login.php" jsonPayload.status=200` | > 20 en 5 min por `ip` | — |
| AL-02 Pedido ajeno | **crítica** | métrica `aurora/pedido_rechazado` (etiqueta `ip`) | mismo recurso + `jsonPayload.status=(401 OR 403 OR 404)` + `jsonPayload.uri=~"^/(wp-json/wc/(v3\|store/v1)/orders\|my-account/view-order/\|checkout/order-received/)"` | > 5 en 10 min por `ip` | `AL-02-pedido-ajeno.json` |
| AL-03 Card testing | alta | métrica `aurora/checkout_fallido` (etiqueta `ip`) | mismo recurso + `jsonPayload.method="POST" jsonPayload.uri=~"^/wp-json/wc/store/v1/checkout" jsonPayload.status>=400` | > 10 en 1 h por `ip` | — |
| AL-04 Shell en pod | **crítica** | basada en logs | `logName="projects/aurorashop-sec-umg/logs/cloudaudit.googleapis.com%2Factivity" protoPayload.methodName=("io.k8s.core.v1.pods.exec.create" OR "io.k8s.core.v1.pods.attach.create") protoPayload.resourceName:"namespaces/aurorashop/"` (más la regla Falco RT-01 si se instala) | 1 evento | `AL-04-exec-en-pod.json` |
| AL-05 Cambio de archivos del CMS | **crítica** | basada en logs | `resource.type="k8s_container" resource.labels.namespace_name="aurorashop" jsonPayload.aurora_event="integrity_mismatch"` | 1 evento | requiere #55 |
| AL-06 Cambio de IAM/RBAC | alta | basada en logs | `logName:"cloudaudit.googleapis.com%2Factivity" (protoPayload.methodName:"SetIamPolicy" OR protoPayload.methodName=~"^io\.k8s\.authorization\.rbac\.v1\.") NOT protoPayload.authenticationInfo.principalEmail=~"^sa-gh-deployer@"` | 1 evento | — |
| AL-07 Origen sin Cloudflare | **crítica** | basada en logs | `resource.type="http_load_balancer" jsonPayload.enforcedSecurityPolicy.name="aurorashop-demo-edge" jsonPayload.enforcedSecurityPolicy.outcome="DENY"` | 1 evento (límite 1 aviso cada 5 min) | `AL-07-origen-directo.json` |
| AL-08 Error 5xx | media | métrica `aurora/peticiones` (etiqueta `clase` = `5xx` / resto) | mismo recurso + todas las peticiones; clase por `jsonPayload.status` | > 5 % en 5 min | — |

## Requisitos antes de crear las alertas (#54)

1. **Canal de notificación:** un canal de correo del grupo. Su ID sustituye a `NOTIFICATION_CHANNEL_ID` en los JSON.
2. **AL-07** necesita los logs del balanceador, que hoy están apagados: hay que añadir `logging: {enable: true, sampleRate: 1.0}` en `infra/k8s/overlays/*/backendconfig.yaml`. Sin eso Cloud Armor bloquea el acceso, pero no queda registro.
3. **AL-05** necesita el evento `integrity_mismatch` de la #55.
4. Permisos: `roles/monitoring.alertPolicyEditor`, `roles/monitoring.notificationChannelEditor` y `roles/logging.configWriter` (para las métricas). Hoy Arun solo tiene roles de lectura (`docs/00-plan/accesos.md`).

## Creación

```bash
gcloud alpha monitoring policies create --project=aurorashop-sec-umg \
  --policy-from-file=infra/siem/alerts/AL-04-exec-en-pod.json
```

## Prueba de detección (DoD de #54: ≥ 2 críticas en < 2 min)

| Alerta | Disparo controlado | Qué se mide |
|---|---|---|
| AL-04 | `kubectl exec -n aurorashop deploy/aurorashop -c php-fpm -- id` | hora del `exec` en el audit log frente a la hora del correo |
| AL-07 | `curl -sk --resolve aurorashop.ancordss.me.uk:443:<IP-LB> https://aurorashop.ancordss.me.uk/` (Cloud Armor responde 403) | hora del 403 frente a la hora del correo |
| AL-02 | 6 × `curl https://aurorashop.ancordss.me.uk/wp-json/wc/v3/orders/<id>` sin sesión (401) en menos de 10 min | hora de la 6.ª petición frente a la hora del correo |

AL-04 y AL-07 son las dos críticas más directas de probar. AL-02 queda como tercera, porque usa una métrica y su latencia puede pasar de 2 min.
