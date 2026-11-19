# Informe final — Opción B (CMS / E-Commerce Web Enterprise Cloud-Native)

Responsable de ensamblaje: **James** · Autores: todo el equipo · Formato: UMG + APA 7

> Esqueleto con la estructura exigida. Cada sección indica autor y documento fuente. El PDF se produce en Word con `formato-apa.md`.

## 0. Portada

Universidad Mariano Gálvez de Guatemala · Facultad de Ingeniería en Sistemas de Información · Programa de Posgrados · Maestría en Seguridad Informática · Curso: Seguridad en Aplicaciones (093-013) · Docente: Mario Estuardo Chajón Arriaza · Título: *Evaluación, rediseño e implementación de seguridad continua en AuroraShop, e-commerce WordPress/WooCommerce cloud-native sobre Google Cloud* · Integrantes: Hector James Maradiaga López, Javier Oliva, Josue …, Horacio …, Arun … · Guatemala, diciembre de 2026.

## Resumen ejecutivo

<!-- James. Máx. 350 palabras: escenario, método, 3 hallazgos principales, controles implementados, riesgo residual y dictamen. -->

## Índice general

<!-- Campo automático de Word; verificar numeración de tablas y figuras. -->

## 1. Selección y planificación

| Sección | Autor | Fuente |
|---|---|---|
| 1.1 Contexto del CMS / E-Commerce | Horacio | `README.md`, `alcance.md` §2 |
| 1.2 Objetivos del proyecto | James | `alcance.md` §1 |
| 1.3 Alcance | James | `alcance.md` §§3–5 |
| 1.4 Normativas y estándares | Javier | `alcance.md` §7 |
| 1.5 Definición del scope técnico | Josue | `arquitectura-seguridad.md` §§1–3 |

## 2. Activos y riesgos

| Sección | Autor | Fuente |
|---|---|---|
| 2.1 Inventario de activos (ISO 27001) | Javier | `inventario-activos.md` |
| 2.2 Clasificación CIA y criticidad | Javier | `clasificacion-cia.md` |
| 2.3 Modelado de amenazas (STRIDE) | Javier | `stride.md` |
| 2.4 Clasificación de riesgos (DREAD) | Javier | `dread.md` |
| 2.5 Matriz de riesgos inicial | Javier | `matriz-riesgos.md` |

## 3. Evaluación de seguridad

| Sección | Autor | Fuente |
|---|---|---|
| 3.1 Pentesting caja negra | Horacio | `pentest-caja-negra.md` |
| 3.2 Pentesting caja gris/blanca | Horacio | `pentest-caja-gris.md` |
| 3.3 Evaluación OWASP Web Top 10 | Horacio / Arun | `owasp-web-top10.md` |
| 3.4 Evaluación de plugins y temas | Horacio | `evaluacion-plugins.md` |
| 3.5 SAST (código del CMS / plugins) | Josue | `sast-sca.md` §1 |
| 3.6 SCA (dependencias y plugins) | Josue | `sast-sca.md` §2 |
| 3.7 Evaluación de contenedores y Kubernetes | Josue | `evaluacion-contenedores.md` |

## 4. Mitigación y ciberseguridad

| Sección | Autor | Fuente |
|---|---|---|
| 4.1 Rediseño arquitectónico cloud seguro | Josue | `arquitectura-seguridad.md` |
| 4.2 Controles de seguridad propuestos | Arun | `tratamiento-riesgo.md` §2 |
| 4.3 Hardening del CMS | Horacio | `plugins-temas.md` §3 |
| 4.4 Hardening de plugins y temas | Horacio | `plugins-temas.md` §§2–4 |
| 4.5 Hardening de contenedores | Josue | `contenedores-k8s.md` §§1–2 |
| 4.6 Hardening de infraestructura cloud | Josue | `iac-hardening.md` |
| 4.7 Implementación de controles DevSecOps | Josue | `pipeline.md` |

## 5. Operaciones y monitoreo

| Sección | Autor | Fuente |
|---|---|---|
| 5.1 WAF | Arun / James | `waf-cloudflare.md` |
| 5.2 RASP / protección en tiempo de ejecución | Arun | `rasp-monitoreo.md` |
| 5.3 SIEM / correlación de eventos | Arun | `siem.md` |
| 5.4 Alertas y dashboards | Arun | `siem.md` §§4–5 |
| 5.5 Gestión continua de vulnerabilidades | Josue / Arun | `pipeline.md`, `sast-sca.md` |
| 5.6 Tratamiento del riesgo | Arun | `tratamiento-riesgo.md`, `heatmap.md` |

## 6. Dictamen y mejores prácticas

| Sección | Autor | Fuente |
|---|---|---|
| 6.1 Conclusiones | James | síntesis |
| 6.2 Recomendaciones técnicas | James + leads | `tratamiento-riesgo.md` §4 |
| 6.3 Roadmap de seguridad continua | James | tabla abajo |
| 6.4 Lecciones aprendidas | todo el equipo | un párrafo cada uno |
| 6.5 Anexos | James | evidencias, checklists, capturas |
| 6.6 Referencias | Javier | ≥ 15 fuentes APA 7 |

### Roadmap (6.3)

| Horizonte | Acción | Métrica |
|---|---|---|
| 0–30 días | Cerrar hallazgos críticos/altos; WAF en block; alertas activas | 0 críticos abiertos |
| 30–90 días | ASVS nivel 2, pentest externo, WPScan/DAST en cada release, rotación de secretos | cobertura > 80% |
| 90–180 días | RASP comercial, UEBA sobre checkout, DR multi-zona probado | MTTR < 1 h |
| 180–365 días | PCI-DSS SAQ-A/EP, ISO 27001 del proceso, SOC 2 del proveedor verificado | auditoría aprobada |

## Anexos

- A. Inventario completo de activos (CSV).
- B. Reportes crudos: WPScan, ZAP, Semgrep, composer audit, Trivy, Checkov/tfsec, kubesec.
- C. Checklist OWASP Web Top 10 y CIS GKE (alcance aplicable).
- D. Matriz DREAD completa y heatmap.
- E. Capturas de WAF, SIEM y Falco.
- F. Enlaces a repositorio y ejecuciones de CI.

## Control de cambios

| Versión | Fecha | Cambio | Autor |
|---|---|---|---|
| 0.1 | 2026-11-18 | Esqueleto y asignación de secciones (Opción B) | James |
