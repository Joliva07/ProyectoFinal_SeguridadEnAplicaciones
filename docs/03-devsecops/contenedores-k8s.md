# Contenedores y Kubernetes

Dueño: **Josue** (contrato de imagen, despliegue y hardening) · Revisión: Arun · Componente 2.

> Estado: clúster GKE Autopilot aplicado el 2026-11-24; namespaces PSA, Workload Identity, RBAC de CI y drivers CSI verificados. Falta la imagen del CMS (#40) y el certificado Origin CA para aplicar el Ingress; el rollout sigue sin ejecutarse.

## 1. Contrato de la imagen

El job `container` espera que Horacio entregue `cms/docker/Dockerfile` con los targets `php-runtime` y `nginx-runtime`. La imagen final debe cumplir:

| Control | Requisito | Evidencia al completar la imagen |
|---|---|---|
| Base | PHP-FPM 8.3 Alpine endurecido y Nginx reducido | digest y SBOM |
| Etapas | Composer/npm/build tools fuera de los targets finales | `docker history` + inspección de paquetes |
| Usuario | UID/GID 10001 para PHP y Nginx no root | `docker run --rm <imagen> id` |
| FS | Sin escritura en root; solo volúmenes temporales declarados | prueba con `--read-only` |
| Secretos | Ningún secreto o `wp-config.php` con credenciales en capas | `docker history --no-trunc` + escáner |
| Versiones | WordPress, WooCommerce, plugins y bibliotecas fijados | locks e inventario del Dockerfile |
| Salud | `/healthz` atendido por Nginx en puerto 8080 | probe/HTTP smoke |
| Vulnerabilidades | 0 CRITICAL con fix en cada imagen | JSON de Trivy archivado |

Los nombres de destino se publican como `wordpress-php` y `wordpress-nginx` en Artifact Registry, con tag del commit para trazabilidad y digest para el manifiesto.

## 2. GKE y pods

| Control | Configuración preparada | Comprobación posterior |
|---|---|---|
| Plano de control | GKE Autopilot privado; API sin IP pública | `gcloud container clusters describe` |
| Acceso CI | WIF + GKE Connect Gateway + RBAC namespaced | `kubectl auth can-i --list` |
| Admisión | PSA `restricted` en los tres namespaces | `kubectl get namespace --show-labels` |
| Workload Identity | GSA diferente para dev, staging y demo; KSA sin token montado | revisar bindings y acceso a API |
| Contenedor | non-root, seccomp RuntimeDefault, read-only FS, capabilities drop ALL | YAML renderizado + runtime |
| Egress | NetworkPolicy deny-all con DNS, SQL, restricted APIs y metadata permitidos | conexión de prueba desde pod |
| Entrada | GKE Ingress protegido por Cloud Armor; origen solo Cloudflare | request desde IP permitida/no permitida |
| Secretos y medios | CSI de Secret Manager y GCS Fuse, IAM por ambiente | lectura/escritura autorizada |
| Recursos | requests/limits y HPA 2–6; PDB `minAvailable: 1` | `kubectl get hpa,pdb` |

El ServiceAccount Workload Identity se instala una sola vez desde `infra/k8s/bootstrap/workload-serviceaccounts.yaml`; CI no recibe permiso para editarlo. Secretos TLS de Cloudflare son prerrequisito manual y quedan fuera del repositorio.

## 3. Automatización de análisis

- `Checkov` revisa Terraform y Kubernetes, con bloqueo HIGH/CRITICAL.
- `tfsec` complementa el análisis Terraform heredado.
- `Kubesec` analiza el YAML resultante de `kubectl kustomize` y conserva su JSON.
- `Trivy` escanea las imágenes PHP y Nginx; el gate bloquea CRITICAL con fix disponible.
- `kubectl rollout status` y `/shop`, `/my-account` validan la revisión desplegada; ZAP ejecuta baseline en el storefront demo.

## 4. Alcance de Autopilot

El equipo controla imágenes, Pods, RBAC, NetworkPolicy, PSA y configuración de aplicación. Google administra nodos, kernel, runtime y el plano de control; no se atribuyen al equipo cambios sobre componentes gestionados. `kube-bench` no inspecciona nodos administrados de Autopilot; el análisis declarativo y la documentación de GKE CIS delimitan esa cobertura.
