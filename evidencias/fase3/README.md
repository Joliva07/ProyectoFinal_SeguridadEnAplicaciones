# Evidencias fase 3 · Josue

Estado al 2026-11-24: pendientes de ejecución. Los artifacts de Actions se conservan 30 días; al descargarlos se guarda aquí cada reporte junto con fecha, commit, número de workflow y versión de herramienta. No se copian secretos, certificados, cookies ni datos de usuarios.

| Subcarpeta/artefacto | Fuente | Estado |
|---|---|---|
| `gitleaks/` | Security CI | Pendiente de ejecución |
| `semgrep/` | Security CI | Pendiente: falta código PHP del CMS |
| `wpscan/` | Security CI semanal/main | Pendiente: falta `WPSCAN_TOKEN` y storefront activo |
| `composer-audit/` | Security CI + `cms/composer.lock` | Pendiente de ejecución; lock actual no incluye bibliotecas del CMS |
| `npm-audit/` | Security CI si aparece lockfile JS | No aplica aún: no hay `package.json` |
| `iac/` | Checkov, tfsec, Kubesec | Pendiente de ejecución |
| `trivy/` | Security CI | Pendiente: falta Dockerfile de Horacio |
| `containers-k8s/` | Matriz `docs/04-ciberdefensa/evaluacion-contenedores.md` | Parcial: `local-kind-2026-11-24.md` cubre PSA, NetworkPolicy, RBAC, Ingress y HPA/PDB; falta GKE |
| `actions/` | Security CI, Terraform plan/apply | Pendiente de workflows remotos |

Para cada resultado: incluir comando, versión, commit, resumen de hallazgos y decisión de triaje; dejar el valor original del reporte como artifact privado si contiene datos internos.
