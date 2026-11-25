# Primer despliegue del CMS en GKE `demo` (issue #40) — 2026-11-25

Ejecutado por Horacio desde su equipo (cuenta con `roles/owner`, a pedido de James), vía Connect Gateway
(`gcloud container fleet memberships get-credentials aurorashop-demo --location global`).
No se registran valores de secretos ni contraseñas.

## Pasos

| # | Acción | Resultado |
|---|---|---|
| 1 | Secretos `aurorashop-demo-auth-keys`, `-salts`, `-payment-sandbox` | Versión 2 válida (JSON). Versión 1 deshabilitada: llevaba BOM por el pipe de PowerShell 5.1 |
| 2 | Imágenes `wordpress-php` y `wordpress-nginx` en Artifact Registry | `wordpress-php@sha256:504f6206…`, `wordpress-nginx@sha256:c88a385e…` |
| 3 | `roles/artifactregistry.reader` para `757841493230-compute@developer` sobre el repo `aurorashop` | Necesario para que los nodos Autopilot bajen las imágenes (antes: `403 Forbidden`). **Falta en Terraform** |
| 4 | Correcciones de manifiestos (`infra/k8s/base`) aplicadas con `kubectl apply -k infra/k8s/overlays/demo` | Ver tabla siguiente |
| 5 | `install.php` / `setup-config.php` bloqueados en Nginx | `403` desde internet |
| 6 | Rol `aurorashop_runtime_demo` (template del equipo) + `CREATE, ALTER, INDEX, REFERENCES` temporal, con usuario temporal `aurora-migrate` en Cloud SQL Studio | Aplicado |
| 7 | `cms/docker/bin/install-wordpress.php` vía `kubectl exec` | WordPress 7.1.5, WooCommerce 11.3.1, 48 tablas, páginas de tienda creadas |
| 8 | `REVOKE CREATE, ALTER, INDEX, REFERENCES` y borrado de `aurora-migrate` | Grants finales: solo `SELECT, INSERT, UPDATE, DELETE` vía rol; usuarios: solo `sa-gke-workload-*` |

## Errores encontrados en `infra/k8s/base`

| Error | Síntoma | Corrección |
|---|---|---|
| Probes del `cloud-sql-proxy` con `tcpSocket` a 3306, pero el proxy escucha en `127.0.0.1` | Reinicio por liveness cada ~40 s | `--health-check --http-address=0.0.0.0 --http-port=9801` + probes `httpGet` `/startup`, `/readiness`, `/liveness` |
| Probes de `php-fpm` con `tcpSocket` a 9000, pero FPM escucha en `127.0.0.1` (a propósito) | `Finishing ... exiting` a los ~35 s | Probe `exec` con `fsockopen('127.0.0.1', 9000)`, igual que el HEALTHCHECK de la imagen |
| NetworkPolicy permitía Cloud SQL en 3306 | El proxy no alcanza la instancia (usa 3307) | Egress a `10.40.0.0/20:3307` |
| NetworkPolicy solo permitía DNS hacia pods `kube-dns`, pero el clúster usa Cloud DNS + NodeLocal DNSCache | Sin resolución de nombres: GCS FUSE `context deadline exceeded` | Egress DNS (53) a `169.254.20.10/32` y `169.254.169.254/32`; además `169.254.169.252:988` (metadata de Workload Identity en Dataplane V2) |

## Verificación final (desde internet, a través de Cloudflare)

```
200  /            200  /shop/        200  /my-account/   200  /cart/
200  /wp-login.php                   200  /healthz
403  /wp-admin/install.php           403  /xmlrpc.php    403  /wp-json/wp/v2/users
pods: 2/2 en 4/4 Running, 0 reinicios
```

Revisiones locales con las mismas imágenes y flags que `security-ci.yml`: Checkov Kubernetes 275 passed / 0 failed;
Semgrep 0 hallazgos; Trivy sin CRITICAL; gitleaks sin hallazgos en archivos versionados.

## Pendientes

- Terraform: `google_artifact_registry_repository_iam_member` para la cuenta de los nodos (paso 3).
- `/?author=1` redirige a `/author/<usuario>/` y revela el nombre del administrador → issue #44.
- El Deployment quedó con imágenes por digest (`kubectl set image`); el pipeline lo reemplaza en el primer merge a `main`.
