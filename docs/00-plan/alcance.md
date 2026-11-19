# Alcance del proyecto

## 1. Objetivo

Evaluar, rediseñar e implementar seguridad continua sobre **FinanciaWeb**, aplicación móvil de banca/fintech con backend de microservicios en Google Cloud, expuesta a Internet a través de Cloudflare. El entregable es un sistema funcional de demo, evaluado ofensiva y defensivamente, con evidencia reproducible y un informe técnico en formato UMG/APA 7.

## 2. Escenario elegido

**Opción A — Aplicación Móvil Banking / Fintech Cloud**, por continuidad con el caso FinanciaWeb trabajado en el curso y porque permite cubrir de forma natural los puntos críticos exigidos: autenticación biométrica + OAuth2/PKCE, cifrado en reposo en el dispositivo, resistencia a ingeniería inversa, seguridad de APIs (OWASP API Top 10) y TLS pinning.

## 3. Dentro del alcance

| Área | Incluye |
|---|---|
| Cliente móvil | APK Android de demo: login OAuth2 + PKCE, biometría, Keystore, pinning, ofuscación, detección de root |
| Backend | 2 microservicios en Cloud Run (`accounts`, `transfers`), Cloud SQL PostgreSQL con IP privada, Secret Manager |
| Identidad | Identity Platform (OIDC/OAuth2, MFA), JWT con verificación de firma, scopes y expiración |
| Borde | Cloudflare: DNS, TLS 1.3, WAF, rate limiting, bot management, Access en `admin` |
| Nube | Proyecto GCP propio, VPC, subredes, IAM de menor privilegio, KMS (CMEK), Cloud Armor, logging/monitoring |
| DevSecOps | GitHub Actions: Semgrep, OWASP Dependency-Check/Snyk, gitleaks, Trivy, Checkov/tfsec, build de APK |
| Evaluación | Pentest caja negra (ZAP/Nmap), caja gris/blanca (IDOR/BOLA, autorización, JWT), casos de abuso |
| Operación | Reglas WAF, alertas, dashboards, sinks de logs, tratamiento formal del riesgo y heatmap residual |

## 4. Fuera del alcance

- Producción real, clientes reales o integración con el core bancario.
- iOS (se documenta como trabajo futuro; el diseño es agnóstico).
- Pruebas de denegación de servicio y volumétricas.
- Cumplimiento formal certificado (PCI-DSS, SOC 2): solo mapeo de controles y brechas.
- Pentesting de terceros o de infraestructura de la universidad.
- Soporte 24/7, HA multi-región y DR productivo (se menciona como roadmap).

## 5. Ambientes

| Ambiente | Propósito | Datos | Acceso |
|---|---|---|---|
| `dev` | Construcción, pruebas de humo | sintéticos | pipeline |
| `demo` (público) | Evaluación y evidencia de pentest | sintéticos, cuentas `demo-*` | Internet vía Cloudflare |
| `break-glass` | Cambios manuales de emergencia | — | solo James |

Un solo proyecto GCP para el curso (`financiaweb-sec-umg`), con prefijos `dev-` y `demo-` en los recursos.

## 6. Datos

- Solo sintéticos: 50 clientes, 200 cuentas, 5 000 movimientos generados con `faker`.
- Sin PII real, sin secretos reales, sin credenciales de la universidad.
- Cuentas de prueba: `demo-cliente-01`, `demo-admin-01`, con contraseñas rotadas tras la fase 4.

## 7. Normativas y estándares de referencia

ISO/IEC 27001:2022 (A.5, A.8), ISO/IEC 27005, OWASP ASVS 5.0.0, OWASP MASVS/MASTG, OWASP API Security Top 10 (2023), OWASP Web Top 10 (2021), NIST SP 800-53/800-207 (Zero Trust), CVSS 4.0, STRIDE/DREAD, Reglamento de Riesgo Tecnológico de la Junta Monetaria de Guatemala (referencia contextual), y guías de GCP (Google Cloud Security Foundations) y Cloudflare (WAF/Zero Trust).

## 8. Supuestos y restricciones

1. Presupuesto: capa gratuita/trial de GCP + Cloudflare Free/Pro. Sin servicios de pago obligatorios; Chronicle/Splunk se sustituyen por Cloud Logging + BigQuery.
2. Todos los integrantes tienen acceso de lectura al proyecto GCP y a Claude; solo James opera Cloudflare.
3. La fecha de entrega se toma como **9 de diciembre de 2026** hasta confirmación de la cátedra.
4. El repo es público: no se sube ninguna evidencia con datos personales, tokens ni claves.
5. El APK de demo se distribuye por artifact de GitHub Actions, no por Play Store.

## 9. Riesgos del propio proyecto

| Riesgo | Impacto | Mitigación | Dueño |
|---|---|---|---|
| Cuotas/costos de GCP | Bloquea despliegue | Alertas de presupuesto, Cloud Run min-instances=0, Cloud SQL f1-micro | James |
| Curva de Android/Kotlin | Retrasa APK | Claude + plantilla; si falla, APK mínimo con WebView endurecido como respaldo | Horacio |
| Ventana de pentest corta | Evidencia incompleta | Congelar alcance el 25-nov; ZAP baseline automatizado desde CI | Horacio |
| Un solo operador de Cloudflare | Cuello de botella | Cambios por issue con SLA 24 h; reglas preparadas de antemano | James |
| Pérdida de integrante | Cae un componente | Documentación en repo, revisión cruzada, respaldo definido por componente | James |
