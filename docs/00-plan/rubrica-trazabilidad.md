# Trazabilidad de la rúbrica (20 puntos)

Cada criterio se mapea a un artefacto verificable. El estado se actualiza en cada checkpoint de los martes.

## Componente 1 — Análisis de riesgos y activos (4 pts) · Javier

| Criterio de la cátedra | Artefacto | Evidencia | Estado |
|---|---|---|---|
| Inventario completo de activos ISO 27001 | `docs/01-activos-riesgos/inventario-activos.md` | 26+ activos con 7 campos y CSV | pendiente |
| Modelado STRIDE | `docs/01-activos-riesgos/stride.md` | 6 categorías × componentes, casos de abuso | pendiente |
| Scoring DREAD | `docs/01-activos-riesgos/dread.md` | Fórmula, desglose, ordenamiento | pendiente |
| 7 capas de seguridad en profundidad | `docs/01-activos-riesgos/matriz-riesgos.md` (columna capa) | ≥1 riesgo y ≥1 control por capa | pendiente |
| Matriz de calor y tratamiento | `docs/05-operaciones/heatmap.md` + `tratamiento-riesgo.md` | Heatmap antes/después y decisión por riesgo | pendiente |

## Componente 2 — Arquitectura Cloud & DevSecOps (4 pts) · Josue

| Criterio | Artefacto | Evidencia | Estado |
|---|---|---|---|
| Diagrama de arquitectura de seguridad | `docs/02-arquitectura/arquitectura-seguridad.md` + `diagramas/` | C4 + checkout con API Gateway/WAF/IAM/cifrado | pendiente |
| SAST/SCA integrados | `docs/03-devsecops/sast-sca.md` | Runs de Actions con Semgrep, WPScan, composer audit | pendiente |
| Análisis de IaC | `docs/03-devsecops/iac-hardening.md` | Checkov/tfsec antes/después sobre Terraform y K8s | pendiente |
| Menor privilegio y cifrado | `arquitectura-seguridad.md` §4–5 | Matriz IAM/RBAC, CMEK y TLS 1.3 | pendiente |
| Contenedores y K8s | `docs/03-devsecops/contenedores-k8s.md` + `docs/04-ciberdefensa/evaluacion-contenedores.md` | Trivy, kube-bench, Pod Security, NetworkPolicy | pendiente |

## Componente 3 — Implementación de ciberdefensa (4 pts) · Horacio

| Criterio | Artefacto | Evidencia | Estado |
|---|---|---|---|
| Reporte pentest caja negra | `docs/04-ciberdefensa/pentest-caja-negra.md` | WPScan, ZAP HTML, `nmap -sV`, capturas Burp | pendiente |
| Evaluación caja gris/blanca | `pentest-caja-gris.md` | PoC IDOR en pedidos, nonces/CSRF, capacidades | pendiente |
| OWASP Web Top 10 | `owasp-web-top10.md` | Tabla A01–A10 con estado y evidencia | pendiente |
| Evaluación de plugins y temas | `evaluacion-plugins.md` | Versión, CVE, decisión, código revisado | pendiente |
| Casos de abuso | `casos-abuso.md` | Escenarios con pasos, impacto y detección | pendiente |
| Perímetro del software | `superficie-ataque.md` | Endpoints, puertos, `wp-json`, `xmlrpc`, origen | pendiente |

## Componente 4 — Implementación de ciberseguridad (4 pts) · James

| Criterio | Artefacto | Evidencia | Estado |
|---|---|---|---|
| Plan de mitigación por hallazgo | `tratamiento-riesgo.md` | Tabla `H-NN` → control → responsable → estado | pendiente |
| WAF | `waf-cloudflare.md` | Reglas WP/WooCommerce + capturas de bloqueo | pendiente |
| RASP / monitoreo en ejecución | `rasp-monitoreo.md` | Falco, integridad de archivos, reglas de API | pendiente |
| SIEM | `siem.md` | Sinks, consultas, alertas probadas, dashboard | pendiente |
| Cifrado | `arquitectura-seguridad.md` §5 + `waf-cloudflare.md` §4 | CMEK, TLS 1.3, secretos | pendiente |
| Tratamiento y heatmap | `heatmap.md` | Decisión aceptar/eliminar/evitar/mitigar/transferir | pendiente |

## Componente 5 — Informe técnico y APA (4 pts) · Arun

| Criterio | Artefacto | Evidencia | Estado |
|---|---|---|---|
| Formato UMG (Arial 12, 1.5, sangrías) | `formato-apa.md` | Checklist + PDF verificado | pendiente |
| Estructura formal (Opción B) | `informe-final.md` | Índice con secciones 1–6 y anexos | pendiente |
| Referencias APA 7 | `informe-final.md` §6.6 | ≥15 fuentes citadas en el texto | pendiente |
| Dictamen y conclusiones | `informe-final.md` §6.1–6.2 | Dictamen del grupo | pendiente |

## Regla de aceptación

Un componente se marca **completo** solo si: el documento existe, la evidencia está en `evidencias/`, otra persona lo revisó y aprobó. Marcar "listo" sin evidencia resta credibilidad al informe.
