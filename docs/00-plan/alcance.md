# Alcance del proyecto

## 1. Objetivo

Evaluar, rediseñar e implementar seguridad continua sobre **AuroraShop**, una tienda en línea basada en WordPress + WooCommerce desplegada en contenedores sobre Google Cloud, expuesta a Internet a través de Cloudflare. El entregable es un sistema funcional de demo, evaluado ofensiva y defensivamente, con evidencia reproducible y un informe técnico en formato UMG/APA 7.

## 2. Escenario elegido

**Opción B — CMS / E-Commerce Web Enterprise Cloud-Native**, porque permite cubrir de forma verificable los puntos críticos exigidos: OWASP Web Top 10 (SQLi, XSS, CSRF, Broken Access Control), seguridad de complementos y temas, WAF, hardening de servidores y contenedores, e Infraestructura como Código.

## 3. Dentro del alcance

| Área | Incluye |
|---|---|
| CMS | WordPress 6.x + WooCommerce, plugins mínimos (pagos, envíos, antispam), tema hijo propio |
| Runtime | Imagen Docker multi-stage (PHP-FPM 8.3 + Nginx), usuario no root, root FS de solo lectura |
| Orquestación | GKE Autopilot, namespace `aurorashop`, HPA, NetworkPolicy, Pod Security Admission `restricted`, Workload Identity |
| Base de datos | Cloud SQL MySQL 8 con IP privada, CMEK, usuario de app con privilegios mínimos |
| Media | Bucket GCS privado servido por Cloudflare; sin escritura desde el pod salvo vía API |
| Borde | Cloudflare: DNS, TLS 1.3, WAF (CRS + reglas custom), rate limiting, bot management, Access en `admin`, Logpush |
| Identidad administrativa | Cloudflare Access + MFA (TOTP) en WordPress, roles y capacidades revisadas |
| DevSecOps | GitHub Actions: gitleaks, Semgrep (PHP), WPScan, composer/npm audit, Trivy, Checkov/tfsec, despliegue por WIF |
| Evaluación | Pentest caja negra (WPScan/ZAP/Nmap/Burp), caja gris (IDOR en pedidos, nonces/CSRF, capacidades, SQLi en plugin propio), revisión de plugins y contenedores |
| Operación | Reglas WAF, SIEM (Cloud Logging + BigQuery), Falco, integridad de archivos, tratamiento del riesgo y heatmap |

## 4. Fuera del alcance

- Tienda en producción con clientes reales o pagos reales (solo sandbox de pasarela).
- Migración desde otro CMS, integraciones ERP y multiidioma avanzado.
- Pruebas de denegación de servicio y volumétricas.
- Certificación formal (PCI-DSS, SOC 2): solo mapeo de controles y brechas declaradas.
- Pentesting de terceros, de la universidad o de otros subdominios de `ancordss.me.uk`.
- Apps móviles y API pública de terceros (no aplica a la Opción B).

## 5. Ambientes

| Ambiente | Propósito | Datos | Acceso |
|---|---|---|---|
| `dev` | Construcción, pruebas de humo | sintéticos | pipeline |
| `demo` (público) | Evaluación y evidencia de pentest | sintéticos, cuentas `demo-*` | Internet vía Cloudflare |
| `staging` | Réplica para pruebas destructivas controladas | sintéticos | Cloudflare Access |
| `break-glass` | Cambios manuales de emergencia | — | solo James |

Un proyecto GCP (`aurorashop-sec-umg`) con prefijos `dev-`, `staging-` y `demo-`.

## 6. Datos

- Catálogo sintético: 60 productos con imágenes libres, 40 clientes, 150 pedidos, 30 cupones.
- Sin PII real, sin tarjetas reales (el checkout usa pasarela sandbox con montos de prueba).
- Cuentas: `demo-cliente-01..03`, `demo-admin-01`, `demo-editor-01`, con contraseñas rotadas tras la fase 4.

## 7. Normativas y estándares de referencia

ISO/IEC 27001:2022 (A.5, A.8), ISO/IEC 27005, OWASP Top 10 (2021), OWASP ASVS 5.0.0, OWASP WSTG, OWASP Cheat Sheets (SQLi, XSS, CSRF, File Upload, Deserialization), CIS Kubernetes Benchmark, NSA/CISA Kubernetes Hardening Guide, NIST SP 800-190 (contenedores), NIST SP 800-207 (Zero Trust), CVSS 4.0, STRIDE/DREAD, guías de Google Cloud (GKE security best practices) y de Cloudflare (WAF/Zero Trust), y PCI-DSS v4.0 como referencia de protección de datos de pago.

## 8. Supuestos y restricciones

1. Presupuesto: capa gratuita/trial de GCP + Cloudflare Free/Pro. Sin Chronicle ni Splunk: se sustituyen por Cloud Logging + BigQuery + alertas.
2. GKE Autopilot elimina la administración de nodos; el hardening se centra en pods, RBAC, red y admisión.
3. Todos con acceso de lectura a GCP y Claude; solo James con Cloudflare.
4. Entrega objetivo: **9 de diciembre de 2026** (confirmar con la cátedra).
5. Repo público: no se sube evidencia con datos personales, tokens ni claves.
6. WordPress y WooCommerce se usan sin modificaciones del núcleo; los cambios viven en plugins/temas propios y en la configuración.

## 9. Riesgos del propio proyecto

| Riesgo | Impacto | Mitigación | Dueño |
|---|---|---|---|
| Costos de GKE/Cloud SQL | Bloquea el despliegue | Autopilot, 1 réplica mínima, alertas de presupuesto, teardown | James |
| Plugin de pago no compatible con sandbox | Retrasa el checkout | Usar modo `bacs`/`cod` y simular pasarela; el objetivo es el flujo, no el cobro | Horacio |
| Complejidad de Kubernetes | Retrasa el entorno | Manifiestos mínimos + Helm chart simple; Cloud Run como plan B solo para demo | Josue |
| Ventana de pentest corta | Evidencia incompleta | Congelar alcance el 25-nov; ZAP/WPScan automatizados en CI | Horacio |
| Un solo operador de Cloudflare | Cuello de botella | Specs cerradas de Arun + SLA 24 h | James |
| Pérdida de integrante | Cae un componente | Documentación en repo, revisión cruzada, respaldo definido | James |
