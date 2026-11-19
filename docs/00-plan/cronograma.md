# Cronograma

Hoy: **18 de noviembre de 2026** · Entrega objetivo: **9 de diciembre de 2026** (confirmar con la cátedra) · Congelamiento documental: **9-dic 23:59**.

## Hitos

| Hito | Fecha | Criterio de salida | Dueño |
|---|---|---|---|
| G0 · Arranque | 18-nov | Repo, issues asignadas, accesos y proyecto GCP | James |
| G1 · Tienda viva | 25-nov | `aurorashop.ancordss.me.uk` sirve catálogo y checkout; WAF y TLS activos; datos cargados | Josue + Horacio |
| G2 · Evaluación | 2-dic | Reportes de pentest, plugins, SAST/SCA, contenedores e IaC con IDs `H-NN` | Horacio + Josue |
| G3 · Ciberdefensa operativa | 7-dic | WAF aplicado y probado, SIEM/Falco alertando, plan de mitigación completo | James |
| G4 · Informe | 9-dic | PDF final APA 7, rúbrica mapeada, dictamen y anexos | Arun |

## Semana 1 — Fundaciones (18–25 nov)

| Fecha | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| 18–20 | Proyecto GCP, APIs, IAM, WIF; plantillas WAF/SIEM | Inventario de activos | Diagrama C4 + decisiones (GKE, MySQL, GCS) | Dockerfile base de WP + WooCommerce | Esqueleto del informe, portada, checklist APA |
| 21–22 | Cloudflare: 3 hosts, TLS, WAF base, Access | CIA y criticidad | Terraform: VPC, GKE, Cloud SQL, Artifact Registry | `wp-config` desde secretos, `php.ini`, Nginx | Referencias APA + tabla de trazabilidad |
| 23–24 | Presupuesto, etiquetas y reglas WAF en borrador | STRIDE | Manifiestos K8s + pipeline mínimo | Roles/capacidades, MFA, plugins fijados | Estructura 1–6 y asignación de secciones |
| 25 | **G1**: WAF base verificado (log) | DREAD + matriz v1 | Tienda desplegada y pipeline en PR | Checkout de prueba y catálogo cargado | Índice, control de cambios, carpeta de evidencias |

## Semana 2 — Evaluación (26 nov – 2 dic)

| Fecha | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| 26–27 | CRS en log, ventana de pentest, alertas v1 | Matriz con arquitectura real | SAST/WPScan/SCA/Trivy/Checkov en CI | WPScan + ZAP baseline + Nmap | Integración de secciones 1–2 |
| 28–29 | SIEM: sinks y consultas iniciales | Datos y cuentas demo finales | IaC + K8s: cierre de hallazgos | Burp manual: IDOR pedidos, nonces, upload, SQLi | Redacción 1.2, 1.3 y revisión de tablas |
| 30–1 | Falco e integridad del CMS; WAF rate limiting | Matriz v2 con hallazgos | Trivy fixes y redeploy | Evaluación de plugins/temas + PoC | Integración 3.x y control de calidad |
| 2 | **G2**: evidencia de detección inicial | Matriz v2 cerrada | Reportes de contenedores y pipeline | Informes de pentest y plugins | Versión 0.5 del informe |

## Semana 3 — Cierre (3–9 dic)

| Fecha | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| 3–4 | WAF custom + Logpush; pruebas de bloqueo | Heatmap inicial | Hardening final de contenedores | Casos de abuso + superficie | Corrección de formato y anexos |
| 5–6 | SIEM: dashboards y alertas probadas | Tratamiento (coautoría con James) | Informe §3.5–3.7, 4.5–4.7 | Informe §3.1–3.4, 4.3–4.4 | Informe §1.2–1.3, 6.1–6.5 + integración |
| 7 | **G3**: verificación de controles | Revisión cruzada de Josue | Revisión cruzada de Javier | Revisión cruzada de James | Revisión cruzada de Horacio |
| 8 | Lectura técnica final | Lectura final | Lectura final | Lectura final | Informe completo + APA + anexos |
| 9 | Teardown y costos | — | — | — | **G4**: PDF y entrega |

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
WAF + SIEM + Falco + mitigación (James, D13-19)
        │
        ▼
Informe final (Arun, D15-21)
```

Las tareas fuera de la ruta pueden moverse una semana; las de la ruta no.

## Presupuesto de tiempo por persona

| Integrante | Horas/semana | Pico |
|---|---|---|
| James | 11–13 | 25-nov y 6-dic |
| Javier | 6–8 | 25-nov y 5-dic |
| Josue | 11–13 | 25-nov (despliegue) |
| Horacio | 11–13 | 29-nov (pentest) |
| Arun | 8–10 | 8-dic (informe) |
