# infra/ — Infraestructura como código

Responsable: **Josue** · Revisión: James

Aún sin código. Estructura prevista (se crea en la fase 2):

```
infra/
  bootstrap/      proyecto, APIs, bucket de estado, WIF (aplicado una vez por James)
  modules/
    network/      VPC, subred, conector serverless, firewall
    data/         Cloud SQL, KMS, Secret Manager
    compute/      Cloud Run, Artifact Registry, LB, Cloud Armor
    observability/ sinks, alert policies, dashboards
  env/
    dev/
    demo/
```

Reglas:

- Estado remoto en GCS con versionado y bloqueo; nunca en el repo.
- `terraform apply` solo desde el pipeline con WIF; bootstrap es la única excepción documentada.
- Checkov y tfsec deben pasar sin hallazgos HIGH/CRITICAL antes del merge.
- Etiquetas obligatorias: `proyecto = "financiaweb"`, `ambiente`, `curso = "seguridad-apps"`.
- Sin secretos en variables de Terraform: referencias a Secret Manager.
