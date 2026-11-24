# Bootstrap del namespace

Aplicación única, hecha por la persona con acceso inicial a GKE después de crear el clúster y registrar Connect Gateway:

```bash
gcloud container fleet memberships get-credentials aurorashop-demo --project aurorashop-sec-umg
kubectl apply -f infra/k8s/bootstrap/namespace-dev.yaml
kubectl apply -f infra/k8s/bootstrap/namespace-staging.yaml
kubectl apply -f infra/k8s/bootstrap/namespace-demo.yaml
kubectl apply -f infra/k8s/bootstrap/workload-serviceaccounts.yaml
kubectl apply -f infra/k8s/bootstrap/rbac.yaml
```

Antes de aplicar los Ingress en `staging` y `aurorashop`, James debe entregar el certificado Cloudflare Origin CA. Crear `aurorashop-origin-tls` en ambos namespaces desde un canal seguro con `kubectl create secret tls`; no guardar el PEM ni la clave privada en el repositorio. El rol de CI no tiene permiso para leer o escribir Secrets. James configura DNS y Access para `staging.aurorashop.ancordss.me.uk`.

El rol CI solo modifica los recursos de la aplicación en estos namespaces. No puede cambiar RBAC, namespaces, secretos de Kubernetes ni recursos del plano de control. Revisa y aplica esta carpeta una sola vez, luego los despliegues usan `kubectl apply -k infra/k8s/overlays/demo`.

Antes del despliegue, deben existir versiones para los tres secretos de cada ambiente (`auth-keys`, `salts`, `payment-sandbox`) en Secret Manager. Terraform crea únicamente sus metadatos y permisos; los valores los entrega el responsable del ambiente mediante un canal seguro.
