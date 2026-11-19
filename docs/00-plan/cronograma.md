# Cronograma

Hoy: **18 de noviembre de 2026** · Entrega objetivo: **9 de diciembre de 2026** (confirmar con la cátedra) · Congelamiento documental: **9-dic 23:59**.

## Hitos

| Hito | Fecha | Criterio de salida | Dueño |
|---|---|---|---|
| G0 · Arranque | 18-nov | Repo e invitaciones (Josue), cuenta y proyecto GCP con IAM (Javier), issues asignadas | Josue + Javier |
| G1 · Tienda viva | 25-nov | `aurorashop.ancordss.me.uk` sirve catálogo y checkout; WAF y TLS activos; datos cargados | Josue + Horacio |
| G2 · Evaluación | 2-dic | Reportes de pentest, plugins, SAST/SCA, contenedores e IaC con IDs `H-NN` | Horacio + Josue |
| G3 · Ciberdefensa operativa | 7-dic | WAF aplicado y probado, SIEM/Falco alertando, plan de mitigación completo | Arun (+ James aplica borde) |
| G4 · Informe | 9-dic | PDF final APA 7, rúbrica mapeada, dictamen y anexos | James |

## Semana 1 — Fundaciones (18–25 nov)

| Fecha | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| 18–20 | Cloudflare: DNS de los 3 hosts, TLS, WAF base, Access | Cuenta GCP: proyecto, APIs, IAM, WIF, presupuesto; invitar accesos | Invitaciones al repo; C4 + Terraform base (VPC, GKE, SQL) | Dockerfile WP + WooCommerce, `php.ini`, Nginx | Plantillas SIEM/Falco; reglas WAF en borrador |
| 21–22 | WAF gestionado en log, Turnstile, cache rules | Inventario de activos (26+) | Manifiestos K8s + pipeline mínimo | `wp-config` desde Secret Manager, roles, MFA | Consultas BigQuery base; mapa OWASP Web Top 10 |
| 23–24 | Revisión de arquitectura de borde con Arun; HSTS/TLS | CIA + criticidad; dataset sintético | Deploy a GKE + WIF probado (primer apply: Javier) | Checkout de prueba y catálogo cargado | Spec WAF v1 (W-01..W-06) |
| 25 | **G1**: verificación de borde (`curl`, origen bloqueado) | DREAD + matriz v1 | Tienda desplegada y pipeline en PR | Pruebas de humo de compra | Matriz OWASP + spec WAF lista |

## Semana 2 — Evaluación (26 nov – 2 dic)

| Fecha | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| 26–27 | CRS en log, ventana de pentest, Cloud Armor | Matriz con arquitectura real | SAST/WPScan/SCA/Trivy/Checkov en CI | WPScan + ZAP baseline + Nmap | Sinks SIEM; verificación OWASP A01–A05 |
| 28–29 | Logpush a GCS y alertas v1 | Datos y cuentas demo finales | IaC + K8s: cierre de hallazgos | Burp manual: IDOR pedidos, nonces, upload, SQLi | Triaje de SAST/SCA/WPScan |
| 30–1 | Rate limiting, bot management, Turnstile en checkout | Matriz v2 con hallazgos | Trivy fixes y redeploy | Evaluación de plugins/temas + PoC | WAF W-07..W-12 + pruebas de efectividad |
| 2 | **G2**: revisión de evidencias del borde | Matriz v2 cerrada | Reportes de contenedores y pipeline | Informes de pentest y plugins | Tabla hallazgo→control |

## Semana 3 — Cierre (3–9 dic)

| Fecha | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| 3–4 | Aplicar spec WAF en block + Logpush verificado | Heatmap inicial (con Arun) | Hardening final de contenedores | Casos de abuso + superficie | Dashboards SIEM + Falco + integridad del CMS |
| 5–6 | Informe §1.2–1.3 y 6.1–6.5; integración | Tratamiento del riesgo (coautoría) | Informe §3.5–3.7, 4.5–4.7 | Informe §3.1–3.4, 4.3–4.4 | Informe §4.2, 5.1–5.6 + heatmap residual |
| 7 | **G3**: ensamblaje del informe v0.8 (verificación de controles la certifica Arun) | Revisión cruzada de Josue | Revisión cruzada de Javier | Revisión cruzada de Arun | Verificación de WAF/SIEM probados |
| 8 | Informe completo + APA + anexos | Lectura final | Lectura final | Lectura final | Lectura final |
| 9 | **G4**: PDF y entrega | Teardown GCP y facturación | — | — | — |

## Ruta crítica

```
Cuenta GCP + IAM + WIF (Javier, D1-2) ──┐
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
WAF aplicado + SIEM + Falco + mitigación (James/Arun, D13-19)
        │
        ▼
Informe final (James, D15-21)
```

Regla: lo que no está en la ruta crítica puede moverse una semana; lo que está, no.

## Presupuesto de tiempo por persona

| Integrante | Horas/semana | Pico |
|---|---|---|
| James | 8–10 | 8-dic (informe) |
| Javier | 11–13 | 20-nov (GCP) y 5-dic |
| Josue | 11–13 | 25-nov (despliegue) |
| Horacio | 11–13 | 29-nov (pentest) |
| Arun | 9–11 | 6-dic (SIEM + tratamiento) |
