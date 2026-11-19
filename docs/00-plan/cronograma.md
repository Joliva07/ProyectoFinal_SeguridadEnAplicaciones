# Cronograma

Hoy: **18 de noviembre de 2026** · Entrega objetivo: **9 de diciembre de 2026** (confirmar con la cátedra) · Congelamiento documental: **9-dic 23:59**.

## Hitos

| Hito | Fecha | Criterio de salida | Dueño |
|---|---|---|---|
| G0 · Arranque | 18-nov | Repo, issues asignadas, accesos y proyecto GCP | James |
| G1 · Tienda viva | 25-nov | `aurorashop.ancordss.me.uk` sirve catálogo y checkout; WAF y TLS activos; datos cargados | Josue + Horacio |
| G2 · Evaluación | 2-dic | Reportes de pentest, plugins, SAST/SCA, contenedores e IaC con IDs `H-NN` | Horacio + Josue |
| G3 · Ciberdefensa operativa | 7-dic | WAF aplicado y probado, SIEM/Falco alertando, plan de mitigación completo | Arun + James |
| G4 · Informe | 9-dic | PDF final APA 7, rúbrica mapeada, dictamen y anexos | James |

## Semana 1 — Fundaciones (18–25 nov)

| Fecha | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| 18–20 | Proyecto GCP, APIs, IAM, WIF, issues | Inventario de activos | Diagrama C4 + decisiones (GKE Autopilot, MySQL, GCS) | Dockerfile base de WP + WooCommerce | Plantillas WAF/SIEM + OWASP Web Top 10 |
| 21–22 | Cloudflare: 3 hosts, TLS, WAF base, Access | CIA y criticidad | Terraform: VPC, GKE, Cloud SQL, Artifact Registry | `wp-config` desde secretos, `php.ini`, Nginx | Consultas BigQuery base |
| 23–24 | Revisión de arquitectura, presupuesto | STRIDE | Manifiestos K8s + pipeline mínimo | Roles/capacidades, MFA, plugins fijados | Reglas WAF v1 (WordPress) |
| 25 | **G1**: demo de tienda viva | DREAD + matriz v1 | Tienda desplegada y pipeline en PR | Checkout de prueba y catálogo cargado | Spec WAF v1 |

## Semana 2 — Evaluación (26 nov – 2 dic)

| Fecha | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| 26–27 | Ventana de pentest, reglas de enfrentamiento, CRS en log | Matriz con arquitectura real | SAST/WPScan/SCA/Trivy/Checkov en CI | WPScan + ZAP baseline + Nmap | Verificación OWASP Web Top 10 |
| 28–29 | Revisión de hallazgos y priorización | Datos y cuentas demo finales | IaC + K8s: cierre de hallazgos (NetworkPolicy, PSA) | Burp manual: IDOR pedidos, nonces, upload, SQLi | Triaje de hallazgos SAST/SCA/WPScan |
| 30–1 | Cloudflare: rate limit, bot mgmt, Turnstile | Matriz v2 con hallazgos | Trivy fixes y redeploy | Evaluación de plugins/temas + PoC | Alertas SIEM v1 + Falco |
| 2 | **G2**: revisión de evidencia | Matriz v2 cerrada | Reportes de contenedores y pipeline | Informes de pentest y plugins | Tabla hallazgo→control |

## Semana 3 — Cierre (3–9 dic)

| Fecha | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| 3–4 | WAF custom + Logpush | Heatmap inicial | Hardening final de contenedores | Casos de abuso + superficie | Dashboards + alertas probadas |
| 5–6 | Informe §1–3 | Tratamiento (coautoría) | Informe §3.5–3.7, 4.5–4.7 | Informe §3.1–3.4, 4.3–4.4 | Informe §4.2, 5.1–5.6 + heatmap |
| 7 | **G3**: verificación de controles | Revisión cruzada de Josue | Revisión cruzada de Javier | Revisión cruzada de Arun | Revisión cruzada de Horacio |
| 8 | Informe completo + APA + anexos | Lectura final | Lectura final | Lectura final | Lectura final |
| 9 | **G4**: PDF y entrega | — | — | — | — |

## Ruta crítica

```
GCP + Cloudflare (James, D1-2)
        │
        ▼
GKE + MySQL (Josue, D2-5) ──► imagen CMS (Horacio, D1-5)
        │                          │
        ▼                          ▼
   tienda viva (G1, 25-nov) ◄──────┘
        │
        ▼
Pipeline + WPScan/Trivy/Checkov (Josue, D6-8)
        │
        ▼
Pentest + plugins + contenedores (Horacio/Josue, D9-14)
        │
        ▼
WAF + SIEM + Falco + mitigación (Arun/James, D13-19)
        │
        ▼
Informe final (James, D15-21)
```

Las tareas fuera de la ruta pueden moverse una semana; las de la ruta no.

## Presupuesto de tiempo por persona

| Integrante | Horas/semana | Pico |
|---|---|---|
| James | 10–12 | 8-dic |
| Javier | 6–8 | 25-nov y 5-dic |
| Josue | 11–13 | 25-nov (despliegue) |
| Horacio | 11–13 | 29-nov (pentest) |
| Arun | 7–9 | 6-dic |
