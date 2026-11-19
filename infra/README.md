# infra/ — Infraestructura como código

Responsable: **Josue** · Revisión: James

Aún sin código. Estructura prevista (se crea en la fase 2):

```
infra/
  bootstrap/      proyecto, APIs, bucket de estado, WIF (aplicado una vez por Javier)
  modules/
    network/      VPC, subredes (pods/servicios), Cloud NAT, firewall
    data/         Cloud SQL MySQL, KMS, Secret Manager, buckets
    compute/      GKE Autopilot, Artifact Registry, Ingress, Cloud Armor
    observability/ sinks, alert policies, dashboards
  k8s/            manifiestos base (namespace, deployment, service, ingress,
                  networkpolicy, pdb, hpa) + overlays por ambiente
  env/
    dev/
    staging/
    demo/
```

Reglas:

- Estado remoto en GCS con versionado y bloqueo; nunca en el repo.
- `terraform apply` solo desde el pipeline con WIF; bootstrap es la única excepción documentada.
- Checkov y tfsec deben pasar sin hallazgos HIGH/CRITICAL antes del merge.
- Etiquetas obligatorias: `proyecto = "aurorashop"`, `ambiente`, `curso = "seguridad-apps"`.
- Sin secretos en variables de Terraform: referencias a Secret Manager.
