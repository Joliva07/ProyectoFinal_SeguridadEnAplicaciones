# Contenedores y Kubernetes

Dueños: **Josue** (hardening y evaluación) · Revisión: Arun · Componente de rúbrica 2 y sección 3.7/4.5 del informe

## 1. Imagen del CMS

| Aspecto | Requisito | Verificación |
|---|---|---|
| Base | `php:8.3-fpm-alpine` o distroless equivalente, digest fijado | `docker inspect` |
| Etapas | Multi-stage: build de composer/npm fuera de la imagen final | `docker history` |
| Usuario | UID 10001, sin root | `id` dentro del contenedor |
| Escritura | Root FS de solo lectura; `emptyDir` para `uploads` si aplica | `docker run --read-only` |
| Herramientas | Sin `curl`, `bash`, `git`, `composer` en la imagen final | `trivy` + `which` |
| Versiones | WordPress y WooCommerce fijados por versión; plugins con versión exacta | `composer.lock` / Dockerfile |
| Secretos | Ninguno en capas; `wp-config.php` generado al arrancar desde Secret Manager | `docker history` |
| Puertos | Solo 9000 (FPM); Nginx como sidecar o contenedor separado | manifiesto |
| Salud | `readinessProbe`/`livenessProbe` en `/healthz` | manifiesto |

## 2. Clúster y workloads

| Control | Implementación | Evidencia |
|---|---|---|
| Autopilot | Sin administración de nodos; hardening del pod | `gcloud container clusters describe` |
| API privada | `enable_private_endpoint`, authorized networks | Salida de gcloud |
| Pod Security | `restricted` en el namespace | `kubectl get ns aurorashop -o yaml` |
| NetworkPolicy | deny-all ingress/egress + allow MySQL, GCS, DNS | `kubectl get networkpolicy` |
| Workload Identity | `iam.gke.io/gcp-service-account` en la SA de K8s | manifiesto |
| RBAC | SA con `get/list/watch` en su namespace; CI con `edit` acotado | `kubectl auth can-i --list` |
| Recursos | requests/limits de CPU y memoria; HPA 2–6 | `kubectl describe hpa` |
| Disponibilidad | PDB `minAvailable: 1`, 2 réplicas mínimas en demo | `kubectl get pdb` |
| Admisión | Sin `privileged`, `hostPath`, `hostNetwork`; seccomp `RuntimeDefault` | manifiesto + kubesec |
| Imágenes | Solo desde Artifact Registry; `imagePullPolicy: IfNotPresent`; digest | manifiesto |

## 3. Escaneo

| Herramienta | Objetivo | Umbral | Salida |
|---|---|---|---|
| Trivy | SO + librerías de la imagen | 0 CRITICAL con fix | tabla + JSON |
| kubesec | Manifiestos | score ≥ 5 por workload | JSON |
| Checkov | Manifiestos | sin HIGH/CRITICAL | SARIF |
| `kubectl auth can-i` | RBAC efectivo | sin cluster-admin | captura |

## 4. Evaluación del clúster (sección 3.7)

| # | Prueba | Método | Resultado esperado | Obtenido |
|---|---|---|---|---|
| 1 | API server expuesto | `nmap` al endpoint, `gcloud` describe | sin endpoint público | |
| 2 | Pod privilegiado aceptado | aplicar manifiesto de prueba | rechazo por PSA | |
| 3 | Tráfico lateral | `curl` desde el pod a otro namespace | bloqueado por NetworkPolicy | |
| 4 | Token de SA montado | `ls /var/run/secrets` | ausente donde no se usa | |
| 5 | Secretos en env | `kubectl describe pod` | sin valores sensibles | |
| 6 | Imagen con CVE crítica | Trivy | 0 con fix | |
| 7 | `kubectl exec` y auditoría | exec + log | registrado en Cloud Logging | |
| 8 | Límites de recursos | `kubectl top`, HPA | sin OOM y escala | |

> `kube-bench` no aplica al plano de control de Autopilot (gestionado). Se ejecuta sobre los manifiestos y se complementa con Security Command Center y la guía CIS GKE, declarando la limitación.

## 5. Limitaciones declaradas

- Autopilot impone muchas configuraciones de nodo: el informe separa lo que controla el equipo (pods, RBAC, red, admisión) de lo que controla Google (kernel, runtime, nodos).
- Sin RuntimeClass alternativo ni nodos dedicados: no se evalúa aislamiento por hardware.
