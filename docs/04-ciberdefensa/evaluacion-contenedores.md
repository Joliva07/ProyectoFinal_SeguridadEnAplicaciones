# Evaluación de contenedores y Kubernetes (3.7)

Dueño: **Josue** · Hardening: `docs/03-devsecops/contenedores-k8s.md`.

> Estado de esta entrega: matriz de evaluación definida. Las pruebas no se han ejecutado: no existe aún Dockerfile de CMS y no hay clúster desplegado/evidencia en el repositorio. Los campos “Resultado obtenido” permanecen pendientes hasta registrar una ejecución real.

## 1. Alcance

Targets PHP-FPM/Nginx del CMS, manifiestos por namespace, clúster GKE Autopilot y RBAC de CI. Nodos, kernel, runtime y plano de control administrados se excluyen de pruebas directas del equipo.

## 2. Pruebas reproducibles

| # | Prueba | Método | Criterio esperado | Resultado obtenido |
|---:|---|---|---|---|
| 1 | CVE en targets de imagen | `trivy image --severity CRITICAL --ignore-unfixed <imagen>` | 0 CRITICAL con fix | Pendiente: falta imagen de Horacio |
| 2 | UID del proceso | `docker run --rm <imagen-php> id` | UID distinto de 0 | Pendiente: falta imagen |
| 3 | Root filesystem | ejecutar target con `docker run --read-only` y volúmenes previstos | servicio inicia sin escribir en root | Pendiente: falta imagen |
| 4 | Secretos en capas | `docker history --no-trunc <imagen>` + Gitleaks | sin tokens, claves ni credenciales | Pendiente: falta imagen |
| 5 | PSA rechaza pod privilegiado | crear en namespace demo un pod de laboratorio con `privileged: true` | API rechaza por `restricted` | Pendiente: no hay clúster |
| 6 | Rechazo de `hostPath` | crear pod de laboratorio con `hostPath` | API rechaza por PSA | Pendiente: no hay clúster |
| 7 | Aislamiento de red | desde pod autorizado probar conexión a namespace no permitido y a SQL privado | el lateral falla; SQL solo por proxy/3306 | Pendiente: no hay clúster |
| 8 | RBAC de despliegue | `kubectl auth can-i --list -n aurorashop` con la identidad CI | solo recursos de app; no Secrets, RBAC ni Namespace | Pendiente: no hay clúster |
| 9 | API privada y rollout | `gcloud ... clusters describe` + `kubectl rollout status` vía Connect Gateway | endpoint privado sin IP pública; rollout disponible | Pendiente: no hay clúster |
| 10 | Capacidad y disponibilidad | `kubectl get hpa,pdb` y `kubectl top pods` | HPA 2–6, PDB minAvailable 1, sin uso sobre límites | Pendiente: no hay clúster |

## 3. Registro de hallazgos

No se abren `H-NN` por resultados no observados. Por cada falla reproducible se registrará componente/commit, severidad, capa, evidencia redactada, control correctivo, responsable y estado; se repetirá la prueba afectada tras el cambio.

## 4. Evidencia y límites

Guardar salidas redactadas de Trivy, Kubesec, `kubectl auth can-i`, describe y pruebas de políticas en `evidencias/fase3/`. Quitar IPs sensibles, nombres de usuario, tokens y Secret Manager values. El informe separa los controles declarados en YAML de los verificados en ejecución.

Autopilot impide inspeccionar el host administrado; `kube-bench` no se usa para afirmar conformidad de nodos. Una evaluación de GKE Standard añadiría CIS de nodo, runtime y configuración del sistema operativo.
