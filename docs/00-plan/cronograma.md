# Cronograma

Hoy: **19 de noviembre de 2026** · Entrega objetivo: **9 de diciembre de 2026** (confirmar con la cátedra) · Congelamiento documental: **9-dic 23:59**.

## Hitos

| Hito | Fecha | Criterio de salida | Dueño |
|---|---|---|---|
| G0 · Arranque | 19-nov | Repo con estructura, issues asignadas, accesos GCP y GitHub entregados | James |
| G1 · Entorno vivo | 25-nov | `api.financiaweb.ancordss.me.uk` responde con JWT válido; WAF base y TLS activos; datos sintéticos cargados | Josue + James |
| G2 · Evaluación | 2-dic | Reportes de pentest, SAST/SCA, IaC y contenedores entregados con IDs `H-NN` | Horacio + Josue |
| G3 · Ciberdefensa operativa | 7-dic | Reglas WAF aplicadas y probadas; SIEM con alertas disparadas; plan de mitigación completo | Arun + James |
| G4 · Informe | 9-dic | PDF final APA 7, 20/20 rúbrica mapeada, dictamen y anexos | James |

## Semana 1 — Fundaciones (19–25 nov)

| Fecha | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| 19–20 | Proyecto GCP, APIs, IAM base, WIF, repo e issues | Inventario de activos (borrador) | Diagrama C4 + decisiones de servicios | Setup Android Studio, repo `app/`, primer login PKCE | Plantillas WAF/SIEM, estudiar reglas Cloudflare |
| 21–22 | DNS Cloudflare (3 hosts), TLS, WAF base, Access en `admin` | CIA + criticidad | Terraform base (VPC, SQL, Artifact Registry) | APK con Keystore + biometría | Consultas BigQuery base |
| 23–24 | Revisión de arquitectura, presupuesto y alertas | STRIDE | Backend desplegado + pipeline mínimo | Pinning + R8; checklist MASVS | Mapeo OWASP API Top 10 |
| 25 | **G1**: demo de entorno vivo | DREAD + matriz inicial | Deploy verificado, pipeline en PR | APK firmado de prueba | Spec WAF v1 |

## Semana 2 — Evaluación (26 nov – 2 dic)

| Fecha | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| 26–27 | Ventana de pentest, reglas de enfrentamiento, WAF Managed Rules | Precisión de matriz con arquitectura real | SAST/SCA/Trivy/Checkov en CI + correcciones | ZAP baseline + Nmap | Evaluación API Top 10 con ZAP/Postman |
| 28–29 | Revisión de hallazgos, priorización con DREAD | Dataset y cuentas demo finales | IaC hardening: cierres de hallazgos | Burp manual + pruebas IDOR/BOLA | Triaje de hallazgos SAST/SCA |
| 30–1 | Cloudflare: rate limiting, bot management, Turnstile | Actualización de matriz con hallazgos | Correcciones de código y redeploy | Manipulación de JWT, bypass MFA, paginación | Alertas SIEM v1 |
| 2 | **G2**: revisión de evidencia | Matriz v2 | Reportes de pipeline archivados | Informes de pentest completos | Tabla hallazgo→control |

## Semana 3 — Cierre (3–9 dic)

| Fecha | James | Javier | Josue | Horacio | Arun |
|---|---|---|---|---|---|
| 3–4 | WAF: reglas custom + Logpush | Heatmap inicial | Hardening final de contenedores | Casos de abuso + superficie | Dashboards + alertas probadas |
| 5–6 | Ensamblaje del informe (secciones 1–3) | Tratamiento del riesgo (co-autoría) | Sección 3.6 y 4.5 del informe | Sección 3.1–3.2 y 4.3 | Sección 5 completa + heatmap residual |
| 7 | **G3**: verificación de controles | Revisión cruzada de Josue | Revisión cruzada de Javier | Revisión cruzada de Arun | Revisión cruzada de Horacio |
| 8 | Informe completo + APA + índice + anexos | Lectura final | Lectura final | Lectura final | Lectura final |
| 9 | **G4**: PDF, empaquetado, entrega | — | — | — | — |

## Ruta crítica

```
GCP+Cloudflare (James, D1-2)
        │
        ▼
Backend+DB (Josue, D3-6) ──► Pipeline (Josue, D6-8)
        │                         │
        ▼                         ▼
APK + pinning (Horacio, D3-8) ──► Pentest (Horacio, D9-14)
                                  │
                                  ▼
                        WAF + SIEM + mitigación (Arun/James, D13-19)
                                  │
                                  ▼
                           Informe final (James, D15-21)
```

Regla: cualquier tarea que no esté en la ruta crítica puede moverse una semana; las de la ruta no.

## Presupuesto de tiempo por persona

| Integrante | Horas/semana estimadas | Pico |
|---|---|---|
| James | 10–12 | 8-dic (informe) |
| Javier | 6–8 | 25-nov y 5-dic |
| Josue | 10–12 | 25-nov (despliegue) |
| Horacio | 10–12 | 30-nov (pentest) |
| Arun | 7–9 | 6-dic (SIEM + matriz) |
