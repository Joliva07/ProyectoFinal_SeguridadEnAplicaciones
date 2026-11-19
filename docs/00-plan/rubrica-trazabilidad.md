# Trazabilidad de la rúbrica (20 puntos)

Cada criterio se mapea a un artefacto verificable. El estado se actualiza en cada checkpoint de los martes.

## Componente 1 — Análisis de riesgos y activos (4 pts) · Javier

| Criterio de la cátedra | Artefacto | Evidencia | Estado |
|---|---|---|---|
| Inventario completo de activos ISO 27001 | `docs/01-activos-riesgos/inventario-activos.md` | Tabla con 7 campos por activo, 30–40 activos | pendiente |
| Modelado STRIDE | `docs/01-activos-riesgos/stride.md` | 6 categorías × componentes, casos de abuso | pendiente |
| Scoring DREAD | `docs/01-activos-riesgos/dread.md` | Fórmula, desglose por riesgo, ordenamiento | pendiente |
| 7 capas de seguridad en profundidad | `docs/01-activos-riesgos/matriz-riesgos.md` (columna capa) + `docs/02-arquitectura/arquitectura-seguridad.md` | Al menos 1 riesgo y 1 control por capa | pendiente |
| Matriz de calor y tratamiento | `docs/05-operaciones/heatmap.md` + `tratamiento-riesgo.md` | Heatmap antes/después, decisión por riesgo | pendiente |

## Componente 2 — Arquitectura Cloud & DevSecOps (4 pts) · Josue

| Criterio | Artefacto | Evidencia | Estado |
|---|---|---|---|
| Diagrama de arquitectura de seguridad | `docs/02-arquitectura/arquitectura-seguridad.md` + `diagramas/` | C4 + flujo de datos con API Gateway, IAM, WAF, cifrado | pendiente |
| SAST/SCA integrados | `docs/03-devsecops/sast-sca.md` | Runs de Actions, reportes Semgrep/Dependency-Check/Snyk | pendiente |
| Análisis de IaC | `docs/03-devsecops/iac-hardening.md` | Checkov/tfsec antes/después, diff de hallazgos | pendiente |
| Menor privilegio y cifrado | `docs/02-arquitectura/arquitectura-seguridad.md` §4 | Matriz de roles IAM, política CMEK/TLS 1.3 | pendiente |

## Componente 3 — Implementación de ciberdefensa (4 pts) · Horacio

| Criterio | Artefacto | Evidencia | Estado |
|---|---|---|---|
| Reporte pentest caja negra | `docs/04-ciberdefensa/pentest-caja-negra.md` | ZAP HTML, `nmap -sV`, capturas Burp | pendiente |
| Evaluación caja gris/blanca | `docs/04-ciberdefensa/pentest-caja-gris.md` | PoC IDOR/BOLA con 2 cuentas, JWT, control de acceso | pendiente |
| Casos de abuso | `docs/04-ciberdefensa/casos-abuso.md` | Escenarios con pasos, impacto y detección | pendiente |
| Perímetro del software | `docs/04-ciberdefensa/superficie-ataque.md` | Inventario de endpoints, puertos, webhooks | pendiente |
| OWASP API Top 10 | `docs/04-ciberdefensa/pentest-caja-gris.md` §4 | Tabla API1–API10 con estado y evidencia | pendiente |

## Componente 4 — Implementación de ciberseguridad (4 pts) · Arun

| Criterio | Artefacto | Evidencia | Estado |
|---|---|---|---|
| Plan de mitigación por hallazgo | `docs/05-operaciones/tratamiento-riesgo.md` | Tabla `H-NN` → control → responsable → estado | pendiente |
| WAF | `docs/05-operaciones/waf-cloudflare.md` | Reglas + capturas de bloqueo antes/después | pendiente |
| RASP / monitoreo de APIs | `docs/05-operaciones/rasp-monitoreo.md` | Métricas y reglas de detección activas | pendiente |
| SIEM | `docs/05-operaciones/siem.md` | Sinks, consultas, alerta disparada, dashboard | pendiente |
| Cifrado | `docs/02-arquitectura/arquitectura-seguridad.md` §5 + `docs/05-operaciones/` | CMEK, TLS 1.3, Keystore (móvil) | pendiente |
| Tratamiento y heatmap | `docs/05-operaciones/heatmap.md` | Decisión aceptar/eliminar/evitar/mitigar/transferir | pendiente |

## Componente 5 — Informe técnico y APA (4 pts) · James

| Criterio | Artefacto | Evidencia | Estado |
|---|---|---|---|
| Formato UMG (Arial 12, 1.5, sangrías) | `docs/06-informe/formato-apa.md` | Checklist + PDF verificado | pendiente |
| Estructura formal (Opción A) | `docs/06-informe/informe-final.md` | Índice con secciones 1–6 y anexos | pendiente |
| Referencias APA 7 | `docs/06-informe/informe-final.md` §6.6 | ≥15 fuentes, todas citadas en el texto | pendiente |
| Dictamen y conclusiones | `docs/06-informe/informe-final.md` §6.1–6.2 | Dictamen firmado por el grupo | pendiente |

## Regla de aceptación

Un componente se marca **completo** solo si: el documento existe, la evidencia está en `evidencias/`, otra persona lo revisó y el revisor lo aprobó. Marcar "listo" sin evidencia resta credibilidad al informe completo.
