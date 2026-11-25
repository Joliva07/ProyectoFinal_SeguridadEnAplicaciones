# Aporte de Josue al informe

Texto para integrar en `docs/06-informe/informe-final.md`. Se informa el estado observado en el repositorio; no se atribuyen despliegues, escaneos o pruebas que no se han ejecutado.

## 1.5 Scope técnico

AuroraShop se diseña como una tienda WordPress/WooCommerce detrás de Cloudflare y de un balanceador de GKE Ingress. La infraestructura objetivo usa una VPC, GKE Autopilot con endpoint privado, Cloud SQL MySQL por IP privada, buckets privados de medios, Secret Manager, Cloud KMS, Artifact Registry y exportación de auditoría a BigQuery. El alcance incluye IaC, manifiestos, gates de seguridad y despliegue; excluye cambios al plano de control y nodos administrados por Google.

Este es un diseño preparado en Terraform y Kubernetes. Al corte de esta entrega, los recursos no tienen evidencia de plan o aplicación; el Dockerfile de Horacio y credenciales de Javier son dependencias para comprobarlo.

## 3.5 SAST

El workflow `.github/workflows/security-ci.yml` ejecuta Semgrep con las reglas `p/php`, `p/owasp-top-ten` y `p/secrets`. Se configura como gate bloqueante y conserva SARIF como artifact de Actions. No existe código propio de plugin/tema PHP en el repositorio, por lo que todavía no hay hallazgos del producto ni demostración before/after. La revisión manual al integrar el CMS debe documentar SQL parametrizado, escape contextual, autorización, nonces, uploads y ausencia de secretos.

## 3.6 SCA

Composer mantiene el requisito del runtime PHP 8.3 y un lockfile reproducible; CI ejecuta Composer audit verificando el SHA-256 del binario. WPScan analiza plugins/temas del storefront activo y bloquea CVSS ≥ 7.0 en ejecuciones de `main`, manuales y semanales. npm audit solo se habilita cuando el repositorio declara manifest y lockfile JS.

La lista real de bibliotecas Composer/npm y el inventario de plugins dependen del Dockerfile y del CMS de Horacio. No se han generado resultados de SCA; en consecuencia no se reportan CVE ni versiones vulnerables observadas.

## 3.7 Evaluación de contenedores y Kubernetes

Se definieron diez pruebas para vulnerabilidades de imagen, usuario no root, root filesystem, secretos en capas, rechazo PSA de pods privilegiados y `hostPath`, aislamiento de red, RBAC, API privada, HPA/PDB y recursos. La matriz de `docs/04-ciberdefensa/evaluacion-contenedores.md` conserva el criterio esperado y la causa pendiente. No existe imagen de CMS ni clúster observable, por lo que ninguna prueba tiene resultado obtenido.

## 4.1 Rediseño arquitectónico cloud

El borde de Cloudflare entrega al Ingress global protegido por Cloud Armor; las reglas de Armor aceptan rangos de Cloudflare en grupos CIDR y aplican reglas administradas SQLi/XSS. El plano de control GKE no publica endpoint IP; CI usa WIF y Connect Gateway. El workload usa identidades distintas por ambiente, Cloud SQL IAM DB Authentication, GCS Fuse para medios y Secret Manager CSI para secretos. CMEK y políticas de acceso refuerzan datos en reposo.

Las fuentes C4, checkout y supply chain están en `docs/02-arquitectura/diagramas/`. La implementación aún requiere plan/aplicación, certificado y DNS de James, bootstrap de Javier y Dockerfile de Horacio.

## 4.5 Hardening de contenedores

Los manifiestos declaran contenedores no root, `RuntimeDefault`, capabilities eliminadas, `allowPrivilegeEscalation: false`, root filesystem de solo lectura, requests/limits, PSA `restricted`, deny-all NetworkPolicy y RBAC limitado por namespace. Los targets PHP-FPM y Nginx deben ser una imagen multi-stage suministrada por Horacio; el workflow exige 0 CRITICAL con fix en Trivy y publica por digest.

Los controles están declarados en manifiestos, no verificados en runtime. Hasta que exista Dockerfile, Trivy no produce resultados y no puede afirmarse la composición real de las capas.

## 4.6 Hardening de infraestructura cloud

Terraform define VPC y rangos secundarios, Cloud NAT, Private Service Access, GKE privado, Cloud SQL sin IP pública y con CMEK, buckets con acceso uniforme/PAP/versionado, Secret Manager, Artifact Registry, Cloud Armor y sink de auditoría. Checkov bloquea HIGH/CRITICAL; tfsec complementa Terraform y Kubesec reporta los manifiestos renderizados.

El state remoto es externo y requiere bucket de Javier. Terraform format/validate se ejecutan en CI; el plan remoto usa WIF. Apply manual de `main` requiere el environment `infra-apply`. No hay plan, resultado de scanner ni despliegue disponibles para afirmar cero findings.

## 4.7 Controles DevSecOps

La cadena definida incluye Gitleaks, Semgrep, WPScan, Composer/npm audit, Checkov, tfsec, Kubesec, Trivy, publicación a Artifact Registry por digest, despliegue por WIF/Connect Gateway, verificación de rollout, HTTP smoke y ZAP baseline. Las acciones GitHub se fijan por SHA completo y los permisos OIDC quedan solo en los jobs que acceden a GCP.

La CI depende de `WPSCAN_TOKEN`, WIF, bucket de estado, configuración del environment protegido y los targets Docker de Horacio. Los reportes se conservan 30 días en Actions; deben copiarse, con acceso controlado, a `evidencias/` cuando existan ejecuciones reales.

## 5.5 Gestión continua de vulnerabilidades

Cada pull request bloquea secretos, errores SAST, SCA de dependencias declaradas, findings IaC HIGH/CRITICAL e imagen con CRITICAL con fix. En `main`, el workflow publica y despliega solo si las compuertas pasan; después ejecuta smoke y ZAP. WPScan registra el inventario del sitio activo semanalmente. Un hallazgo se corrige o se triagea con owner, alcance, versión corregida y evidencia; no se elimina mediante reintentos.

Esta rutina está configurada, pero sus métricas de ejecución, falsos positivos y tiempos de remediación quedan pendientes de la primera CI real.
