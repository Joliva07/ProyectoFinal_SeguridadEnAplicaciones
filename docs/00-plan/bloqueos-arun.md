# Bloqueos de Arun

Registro de lo que **no puede avanzar** en las tareas de Arun (#41, #52, #54, #55, #56) y de qué depende. Complementa a [`plan-de-trabajo.md`](plan-de-trabajo.md) sección 6.

Cómo se usa:

- Un bloqueo por fila, con ID estable `B-NN`. No se reutilizan IDs.
- Cada bloqueo se comenta también en su issue con la etiqueta `estado/bloqueado` y el ID.
- Al resolverse: estado **resuelto**, fecha y evidencia en la misma fila. La fila no se borra.
- Una **limitación** es un bloqueo que no se va a resolver en el curso. Se declara en el documento técnico y en el informe.

Estados: **abierto** · **en gestión** (ya se pidió) · **resuelto** · **limitación** (permanente, declarada).

## 1. Bloqueos

| ID | Qué está bloqueado | Issue | Motivo | Qué se necesita | De quién | Desde | Estado |
|---|---|---|---|---|---|---|---|
| B-01 | Ejecutar las consultas Q-01..Q-11 en BigQuery y archivar los resultados. Es el criterio de cierre de la #41 ("consultas ejecutables en BigQuery") | #41, #54 | Arun solo tiene `roles/bigquery.dataViewer`, que permite leer tablas pero **no ejecutar consultas** | `roles/bigquery.jobUser` en `aurorashop-sec-umg` | Javier (dueño de la cuenta GCP) | 2026-11-26 | abierto |
| B-02 | Crear las alertas AL-01..AL-08, el canal de correo y las métricas basadas en logs | #54 | Arun solo tiene roles de lectura (`monitoring.viewer`, `logging.viewer`) | `roles/monitoring.alertPolicyEditor`, `roles/monitoring.notificationChannelEditor` y `roles/logging.configWriter` | Javier | 2026-11-26 | abierto |
| B-03 | Pruebas controladas en el clúster: `kubectl exec` (AL-04, RT-01, RT-10), Falco y la integridad del CMS (RT-02..RT-04) | #54, #55 | Arun no tiene acceso a `kubectl` en el clúster | `roles/container.developer` (o un rol con `pods/exec` en `aurorashop`) y acceso por Connect Gateway | Javier / Josue | 2026-11-26 | abierto |
| B-04 | Usar cualquiera de los permisos anteriores desde el equipo de Arun | #41, #54, #55 | `gcloud` y `bq` no están instalados | Instalar Google Cloud SDK y ejecutar `gcloud auth login` | Arun | 2026-11-26 | abierto |
| B-05 | Probar AL-07 (acceso al origen sin pasar por Cloudflare) | #54 | Los logs del balanceador están apagados: la `BackendConfig` no tiene `logging.enable`. Cloud Armor bloquea el acceso, pero no deja registro | Añadir `logging: {enable: true, sampleRate: 1.0}` en `infra/k8s/overlays/*/backendconfig.yaml` | Josue (dueño de los manifiestos) | 2026-11-26 | abierto |
| B-06 | Q-08 (egreso anómalo) en BigQuery | #54, #55 | El filtro del sink solo exporta los namespaces `aurorashop`, `dev` y `staging`; los eventos de Falco quedarían fuera | Añadir el namespace `falco` al filtro en `infra/modules/observability/main.tf` | Josue | 2026-11-26 | abierto |
| B-07 | Instalar Falco en el clúster | #55 | GKE Autopilot no admite DaemonSets privilegiados salvo las cargas de socios de su allowlist. No se ha confirmado si Falco está admitido en la versión del clúster | Verificarlo (`kubectl get allowlistedv2workloads` o la documentación de *Autopilot partner workloads*). Si no está admitido, pasa a **limitación** y RT-01 se cubre con Q-09/AL-04 | Arun (verifica, requiere B-03) | 2026-11-26 | abierto |
| B-08 | Variante por usuario de Q-03 (IDOR) y variante por monto de Q-04 (card testing); señales RT-06, RT-07, RT-09 y RT-11 | #41, #55 | El access log de Nginx no trae el usuario ni el query string. Hacen falta eventos `aurora_event` emitidos por la aplicación | Un mu-plugin de eventos. El código del CMS lo mantiene Horacio, así que hay que acordarlo con él antes de tocarlo | Arun escribe, Horacio revisa | 2026-11-26 | abierto |
| B-09 | Correlacionar con las acciones del WAF de Cloudflare (Q-05) y usar Cloudflare como fuente del SIEM | #54 | El plan Free de Cloudflare no incluye Logpush (`1004 logpush is not enabled for this account`) | No tiene solución sin plan pago. Se compensa con los logs del balanceador y de Cloud Armor (B-05), más Cloudflare Analytics en el dashboard | James (dueño de la zona) | 2026-11-24 | limitación |
| B-10 | Cerrar la #56 | #56 | El sección 1 de `tratamiento-riesgo.md` exige que James apruebe los riesgos aceptados (sección 4): H-10, P-12, S-03, S-07, R-25, R-28 y la cobertura del plan Free | Comentario de aprobación de James en la #56 | James | 2026-11-26 | abierto |
| B-11 | Prueba H-12 (scraping) de las 8 pruebas con `curl` de la #52 | #52 | `/shop/` no tiene límite de tasa. La única regla de rate limit del plan Free ya se usa en el login | Turnstile o Bot Fight Mode en Cloudflare, o `limit_req` de Nginx para `/shop/` | James / Horacio | 2026-11-26 | abierto |
| B-12 | Bajar R-22 (backups sin restauración probada) en el heatmap | #56 | La restauración de un backup de Cloud SQL no está en el plan de nadie. `matriz-riesgos.md` sección 4 la deja a nombre de Arun, pero Arun no tiene permisos de Cloud SQL | Que el grupo decida quién la ejecuta (Javier o Josue tienen acceso). Si nadie la hace, queda declarada como pendiente | Grupo | 2026-11-26 | abierto |

## 2. Qué desbloquea cada cosa

| Si se resuelve… | Se puede cerrar o avanzar |
|---|---|
| B-01 + B-04 | **#41** (ejecutar Q-01..Q-11) |
| B-01 + B-02 + B-03 + B-04 + B-05 | **#54** (2 alertas críticas en menos de 2 min: AL-04 y AL-07) |
| B-03 + B-07 + B-08 | **#55** (RT-01..RT-12 con evidencia) |
| B-10 | **#56** |
| B-11 | **#52** (8 pruebas con `curl`) |

## 3. Pedido de permisos a Javier (B-01..B-03)

Texto listo para la issue o el grupo:

> Javier, para cerrar #41 y #54 necesito estos roles en `aurorashop-sec-umg` para mi cuenta:
> `roles/bigquery.jobUser`, `roles/monitoring.alertPolicyEditor`, `roles/monitoring.notificationChannelEditor`, `roles/logging.configWriter` y `roles/container.developer` (o un rol con `pods/exec` en `aurorashop`).
> Con eso ejecuto las consultas del SIEM, creo las alertas y hago las pruebas de detección. Detalle en `docs/00-plan/bloqueos-arun.md`.

## 4. Pedido de aprobación a James (B-10)

Comentario listo para la #56:

> @Ancordss, según la sección 1 de `docs/05-operaciones/tratamiento-riesgo.md`, aceptar un riesgo requiere tu aprobación y una fecha de revisión. Para cerrar esta issue necesito que apruebes (o rechaces) los 7 riesgos aceptados de la sección 4:
>
> | # | Riesgo / hallazgo | Por qué se acepta | Revisión |
> |---|---|---|---|
> | 1 | **R-25** Cumplimiento del proveedor | Se transfiere a Google Cloud (certificaciones y SLA); no es mitigable en el curso | 9-dic |
> | 2 | **R-28** Un solo operador de Cloudflare | Tú defines el acceso a la zona; con un SLA de cambios de 24 h es operable | 9-dic |
> | 3 | **Cobertura parcial del plan Free** | W-07, W-08 y W-10 y Logpush requieren plan pago; se compensan con `limit_req` de Nginx, Cloud Armor y la lógica de la app | 9-dic |
> | 4 | **H-10** Cookies sin `SameSite` explícito | Los navegadores aplican `Lax` por defecto y toda acción exige nonce | 9-dic |
> | 5 | **P-12** `wp-cron.php` público (temporal) | Carga baja; Horacio lo reemplaza por un CronJob antes del cierre | 9-dic |
> | 6 | **S-03** Cloud SQL con `ENCRYPTED_ONLY` | El pod entra por `cloud-sql-proxy` con mTLS, IP privada e IAM; exigir certificado de cliente no añade protección | 9-dic |
> | 7 | **S-07** Binary Authorization desactivado | Rompe el bootstrap; se compensa con el deploy por digest (PR #67) y WIF limitado a `main` | 9-dic |
>
> Para responder, basta con un comentario aquí: **"Apruebo 1-7"**, o indica cuáles no apruebas y por qué. Lo que no apruebes pasa a "Mitigar" con responsable y plazo.
>
> Aparte, hay cuatro hallazgos abiertos a tu nombre que bajan el residual del heatmap cuando se cierren: **P-07** (TLS mínimo 1.2; hoy el borde acepta 1.0 y 1.1), **P-08** (HSTS), **P-10** (borrar el DNS de `staging-aurorashop`) y **H-08** (Cloudflare Access en `admin-aurorashop`). La prueba de cierre de cada uno está en la sección 5.

Cuando James responda: pegar el enlace al comentario en la fila B-10, cambiar los "pendiente de aprobación" de `tratamiento-riesgo.md` sección 2 y sección 4 por la fecha de la aprobación, y cerrar la #56.

## 5. Historial

| Fecha | Cambio | Autor |
|---|---|---|
| 2026-11-26 | Registro inicial: B-01..B-12 | Arun |
| 2026-11-26 | Texto del pedido de aprobación a James (B-10) | Arun |
