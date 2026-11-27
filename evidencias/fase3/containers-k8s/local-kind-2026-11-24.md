# Verificación local K8s — 2026-11-24

Entorno: `kind v0.33.0`, Kubernetes `v1.37.0`, Calico `v3.30.3`, macOS arm64, Docker 28.5.1.
Commit base: `b120240` + fix de PITR MySQL de esta sesión.
Objetivo: ejecutar los controles de #39 que no dependen de GKE. No sustituye la ejecución en Autopilot.

## Comandos y resultados

```bash
kind create cluster --config /tmp/kind-aurorashop.yaml --kubeconfig /tmp/kind-aurorashop.kubeconfig
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/calico.yaml
kubectl apply -f infra/k8s/bootstrap/{namespace-dev,namespace-staging,namespace-demo,workload-serviceaccounts,rbac}.yaml
kubectl apply -f <render dev>
```

| Prueba | Comando | Resultado |
|---|---|---|
| PSA privilegiado | `kubectl -n dev run evil --image=busybox:1.36 --privileged` | `Forbidden: violates PodSecurity "restricted:latest": privileged` |
| PSA hostPath | pod con `hostPath: /etc` | `Forbidden: restricted volume type "hostPath"` |
| Ingress denegado | `curl` desde pod en `test-client` a `192.168.218.5:8080` | timeout, `curl (28)` |
| Ingress permitido | NetworkPolicy temporal desde namespace `test-client` | HTTP 404 (la petición llegó) |
| Ingress denegado tras retirar allow | mismo `curl` | timeout de nuevo |
| DNS | `nslookup kubernetes.default.svc.cluster.local` desde `dev` | resuelve `10.96.0.1` |
| Egress externo | `wget -T 4 http://1.1.1.1` desde `dev` | timeout |
| RBAC escritura | `auth can-i create deployments -n dev/staging/aurorashop --as=sa-gh-deployer@...` | `yes` |
| RBAC Secret | `auth can-i delete secrets -n dev --as=...` | `no` |
| RBAC Namespace | `auth can-i create namespaces --as=...` | `no` |
| RBAC Roles | `auth can-i create roles -n dev --as=...` | `no` |
| RBAC comodines | `auth can-i --list` | solo `*/api` no-recurso; ningún `*` de recursos |
| Ingress + TLS | `kubectl create secret tls` + `IngressClass gce` + overlay | Ingress aceptado en `aurorashop` y `staging` |
| SecretProviderClass | CRD `secrets-store.csi.x-k8s.io/v1` | los 3 objetos aceptados |
| HPA/PDB | `kubectl get hpa,pdb -n dev` | HPA 2-6, PDB `minAvailable: 1` |

## Límites

- kind no tiene metadata server, Cloud SQL proxy, CSI de GCS Fuse/Secret Manager ni CRDs `FrontendConfig`/`BackendConfig`.
- `169.254.169.254` no responde en kind; en GKE es el endpoint de Workload Identity y la NetworkPolicy lo permite.
- No se ejecutó `kubectl top`: metrics-server no está instalado en el clúster local.
- kind no tiene AppArmor habilitado: los pods del Deployment quedan en estado `AppArmor` con el aviso `AppArmor is not enabled on the host`. En GKE COS AppArmor sí está disponible.
- El rollout real y el endpoint privado de Autopilot se verifican en GKE tras #30/#40.

## Emulación local de los gates de CI

| Gate | Comando | Resultado |
|---|---|---|
| Semgrep | `semgrep scan --config p/php --config p/owasp-top-ten --config p/secrets --error` | 0 findings, 274 reglas, 106 archivos |
| tfsec | `tfsec --minimum-severity HIGH infra` | 0 HIGH; 15 passed, 67 ignored |
| Checkov Terraform | `checkov --framework terraform --config-file .checkov.yaml` | 0 failed |
| Checkov Kubernetes | `checkov --framework kubernetes` sobre `rendered/` | 0 failed |
| Kubesec | `kubesec scan rendered/demo-deployment.yaml` | score 18, válido; única recomendación `HostUsers` |
| Composer audit | `composer audit --locked` | `composer.lock` sin paquetes; el job escribe reporte vacío y avisa |
| actionlint | `actionlint` | sin errores |
| Terraform | `fmt -check`, `validate`, `plan` (backend local) | OK; 106 to add, 0 change/destroy |

