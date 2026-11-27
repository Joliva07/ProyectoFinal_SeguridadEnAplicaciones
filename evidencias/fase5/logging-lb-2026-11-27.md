# Logging de Cloud Armor y del balanceador — 2026-11-27

Responsable: **James** · Issue relacionado: PR #77 (`fix/edge-logging`) · Cuenta GCP: `hmaradiagal@miumg.edu.gt`

Objetivo: confirmar que el `BackendConfig` de `demo` y `staging` expone `logging.enable: true` con `sampleRate: 1.0` y que Cloud Logging recibe peticiones del LB con la evaluación de Cloud Armor.

## 1. Contexto

El PR #77 (`648fb73`) agregó el bloque `logging` a `infra/k8s/overlays/{demo,staging}/backendconfig.yaml`. El overlay no se había reaplicado. Al reanudar la sesión, el contexto `connectgateway_aurorashop-sec-umg_global_aurorashop-demo` no podía autenticar porque `gke-gcloud-auth-plugin` no estaba en `PATH`; el binario sí existía en `/opt/homebrew/share/google-cloud-sdk/bin`.

## 2. Verificación del diff

`kubectl diff -k infra/k8s/overlays/<env>` mostró que aplicar el overlay completo habría cambiado, además del `BackendConfig`:

- `spec.template.spec.containers[*].image` de digest (`@sha256:…`) a la etiqueta `:local` en `demo`;
- `minReadySeconds`, `lifecycle.preStop` y probes de `php-fpm` en `staging`.

Ninguno de esos cambios forma parte del PR #77 y repuntar la imagen provocaría un rollout no autorizado. Por eso se aplicó **solo** el `BackendConfig` renderizado, no el overlay completo.

## 3. Comandos ejecutados

```bash
export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
CTX=connectgateway_aurorashop-sec-umg_global_aurorashop-demo

for e in demo staging; do
  kubectl kustomize infra/k8s/overlays/$e \
    | awk '/^apiVersion: cloud.google.com\/v1$/{f=1} f&&/^---$/{print;f=0;next} f' > /tmp/bc-$e.yaml
  kubectl --context $CTX diff -f /tmp/bc-$e.yaml
done

kubectl --context $CTX apply -f /tmp/bc-staging.yaml
kubectl --context $CTX -n staging get backendconfig aurorashop-backend \
  -o jsonpath='{.spec.logging}{"\n"}{.spec.connectionDraining}{"\n"}'
```

## 4. Resultado

| Ambiente | Estado previo | Acción | Estado posterior |
|---|---|---|---|
| `demo` | `logging.enable=true`, `sampleRate=1` ya presente | ninguna (diff vacío) | sin cambios |
| `staging` | sin `logging` ni `connectionDraining` | `apply` del `BackendConfig` | `{"enable":true,"sampleRate":1}`, `{"drainingTimeoutSec":30}` |

Ingress sin cambios tras la aplicación:

```
aurorashop  aurorashop  gce  aurorashop.ancordss.me.uk,admin-aurorashop.ancordss.me.uk  34.8.197.115  80,443
staging     aurorashop  gce  staging-aurorashop.ancordss.me.uk                           136.68.90.143 80,443
```

## 5. Consulta a Cloud Logging

```bash
gcloud logging read 'logName:"logs/requests"' \
  --project=aurorashop-sec-umg --limit=5 --freshness=2h \
  --format='value(timestamp,httpRequest.requestUrl,httpRequest.status,resource.labels.backend_service_name)'
```

Salida (2026-11-27):

```
2026-11-27T14:38:20Z  https://aurorashop.ancordss.me.uk/            200  k8s1-…-aurorashop-web-80-abca01c7
2026-11-27T14:38:18Z  https://aurorashop.ancordss.me.uk/            200  k8s1-…-aurorashop-web-80-abca01c7
2026-11-27T14:38:15Z  https://admin-aurorashop.ancordss.me.uk/wp-admin/  302  k8s1-…-aurorashop-web-80-abca01c7
2026-11-27T14:38:05Z  https://34.8.197.115/favicon.ico               404  k8s1-…-kube-system-default-http-backend-80
```

Negaciones de Cloud Armor (mismo log, `jsonPayload.enforcedSecurityPolicy`):

```bash
gcloud logging read 'logName:"logs/requests" AND jsonPayload.enforcedSecurityPolicy.outcome="DENY"' \
  --project=aurorashop-sec-umg --limit=3 --freshness=24h \
  --format='value(timestamp,httpRequest.requestUrl,jsonPayload.enforcedSecurityPolicy.name,jsonPayload.enforcedSecurityPolicy.priority)'
```

```
2026-11-27T12:48:28Z  https://aurorashop.ancordss.me.uk/favicon.ico       aurorashop-demo-edge  2147483647
2026-11-27T12:48:28Z  https://admin-aurorashop.ancordss.me.uk/favicon.ico aurorashop-demo-edge  2147483647
2026-11-27T12:48:27Z  https://aurorashop.ancordss.me.uk/                  aurorashop-demo-edge  2147483647
```

## 6. Conclusión

El log `requests` del proyecto recibe tráfico del LB con `backend_service_name`, estado HTTP y la evaluación de la política `aurorashop-demo-edge` (prioridad por defecto = deny). Esto habilita AL-07 y las consultas Q-05/Q-10/Q-11 del SIEM, que hasta ahora no tenían fuente de borde. No se modificaron DNS, WAF, Access ni imágenes.

Pendiente fuera de este cambio: probar el disparo real de AL-07 (issue #54), que depende de las alert policies y no se marca como verificado aquí.
