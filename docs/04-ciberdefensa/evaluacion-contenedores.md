# Evaluación de contenedores y Kubernetes (3.7)

Dueño: **Josue** · Hardening: `docs/03-devsecops/contenedores-k8s.md`

## 1. Alcance

Imagen del CMS, manifiestos del namespace `aurorashop`, configuración efectiva del clúster Autopilot y RBAC. No incluye el plano de control de Google (gestionado), que se declara como responsabilidad del proveedor.

## 2. Imagen

| Prueba | Comando | Resultado esperado | Obtenido |
|---|---|---|---|
| CVEs del SO y librerías | `trivy image --severity CRITICAL,HIGH <img>` | 0 CRITICAL con fix | |
| Usuario | `docker run --rm <img> id` | UID ≠ 0 | |
| Root FS | `docker run --rm --read-only <img> ...` | arranca sin escritura | |
| Capas y secretos | `docker history --no-trunc` | sin secretos ni `composer`/`git` | |
| Tamaño | `docker images` | < 400 MB | |
| Firma | `cosign verify` (opcional) | firma válida | |

## 3. Manifiestos y clúster

| # | Prueba | Método | Esperado | Obtenido |
|---|---|---|---|---|
| 1 | Pod privilegiado rechazado | `kubectl apply -f test-privileged.yaml` | error de PSA | |
| 2 | `hostPath` rechazado | manifiesto de prueba | error de admisión | |
| 3 | Sin token de SA innecesario | `ls /var/run/secrets/kubernetes.io` | ausente | |
| 4 | NetworkPolicy efectiva | `kubectl exec ... curl` a otro ns | timeout | |
| 5 | Egreso restringido | curl a Internet desde el pod | bloqueado salvo allowlist | |
| 6 | RBAC mínimo | `kubectl auth can-i --list -n aurorashop` | sin `*` | |
| 7 | API privada | `gcloud container clusters describe` | `enablePrivateEndpoint: true` | |
| 8 | Límites de recursos | `kubectl top pods` | dentro de requests/limits | |
| 9 | HPA y PDB | `kubectl get hpa,pdb` | 2–6 réplicas, minAvailable 1 | |
| 10 | Auditoría de `exec` | `kubectl exec` + Logging | evento registrado | |

## 4. Hallazgos

| ID | Componente | Hallazgo | Severidad | Capa | Control propuesto | Estado |
|---|---|---|---|---|---|---|
| H-0X | manifiesto | `allowPrivilegeEscalation` sin definir | Media | 3 | fijar `false` | abierto |

## 5. Conclusiones

- Separar lo que el equipo controla (pod, RBAC, red, admisión, imagen) de lo que gestiona Google (nodos, kernel, runtime).
- Declarar que `kube-bench` no aplica al plano de control de Autopilot; se sustituye por la guía CIS GKE y Security Command Center.
- Si se usara GKE Standard, el alcance incluiría hardening de nodos, `kube-bench` completo y rotación de credenciales del nodo.
