# Informe final — Opción A (Aplicación Móvil Banking / Fintech)

Responsable de ensamblaje: **James** · Autores: todo el equipo · Formato: UMG + APA 7

> Este archivo es el **esqueleto** con la estructura exacta exigida. Cada sección indica su autor y el documento fuente. El PDF final se produce en Word con el formato de `formato-apa.md`.

## 0. Portada

Universidad Mariano Gálvez de Guatemala · Facultad de Ingeniería en Sistemas de Información · Programa de Posgrados · Maestría en Seguridad Informática · Curso: Seguridad en Aplicaciones (093-013) · Docente: Mario Estuardo Chajón Arriaza · Título: *Evaluación, rediseño e implementación de seguridad continua en FinanciaWeb, aplicación móvil banking cloud-native* · Integrantes: Hector James Maradiaga López, Javier Oliva, Josue …, Horacio …, Arun … · Guatemala, diciembre de 2026.

## Resumen ejecutivo

<!-- James. Máx. 350 palabras: escenario, método, 3 hallazgos principales, controles implementados, riesgo residual y dictamen. -->

## Índice general

<!-- Generado automáticamente desde Word; verificar numeración de tablas y figuras. -->

## 1. Selección y planificación

| Sección | Autor | Fuente |
|---|---|---|
| 1.1 Contexto de la aplicación móvil | Horacio | `README.md`, `alcance.md` |
| 1.2 Objetivos del proyecto | James | `alcance.md` |
| 1.3 Alcance | James | `alcance.md` §§3–5 |
| 1.4 Normativas y estándares | Javier | `alcance.md` §7 |
| 1.5 Definición del scope técnico | Josue | `arquitectura-seguridad.md` §§1–2 |

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
| 3.2 Pentesting caja gris/blanca | Horacio | `pentest-caja-gris.md` §§2, 4–5 |
| 3.3 Evaluación de APIs (OWASP API Top 10) | Arun | `pentest-caja-gris.md` §3 |
| 3.4 SAST (código móvil y backend) | Josue | `sast-sca.md` §1 |
| 3.5 SCA (dependencias) | Josue | `sast-sca.md` §2 |
| 3.6 Evaluación de arquitectura cloud | Josue | `arquitectura-seguridad.md` §§4–6 |

## 4. Mitigación y ciberseguridad

| Sección | Autor | Fuente |
|---|---|---|
| 4.1 Rediseño arquitectónico cloud seguro | Josue | `arquitectura-seguridad.md` |
| 4.2 Controles de seguridad propuestos | Arun | `tratamiento-riesgo.md` §2 |
| 4.3 Hardening de aplicación móvil | Horacio | checklist MASVS (anexo) |
| 4.4 Hardening de APIs y microservicios | Josue | `sast-sca.md`, código |
| 4.5 Hardening de infraestructura cloud | Josue | `iac-hardening.md` |
| 4.6 Implementación de controles DevSecOps | Josue | `pipeline.md` |

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
| 6.1 Conclusiones | James | síntesis de todos |
| 6.2 Recomendaciones técnicas | James + leads | `tratamiento-riesgo.md` §4 |
| 6.3 Roadmap de seguridad continua | James | tabla abajo |
| 6.4 Lecciones aprendidas | todo el equipo | 1 párrafo cada uno |
| 6.5 Anexos | James | evidencias, checklists, capturas |
| 6.6 Referencias | Javier | ≥ 15 fuentes APA 7 |

### Roadmap propuesto (6.3)

| Horizonte | Acción | Métrica de éxito |
|---|---|---|
| 0–30 días | Cerrar hallazgos críticos y altos; activar alertas en producción | 0 críticos abiertos |
| 30–90 días | ASVS nivel 2 completo, pentest externo, DAST en pipeline | Cobertura de pruebas > 80% |
| 90–180 días | RASP comercial, UEBA, Chaos/DR multi-región | MTTR < 1 h |
| 180–365 días | Certificación ISO 27001 del proceso, SOC 2 para el servicio | Auditoría aprobada |

## Anexos

- A. Inventario completo de activos (CSV).
- B. Reportes crudos: ZAP, Semgrep, Dependency-Check, Trivy, Checkov/tfsec.
- C. Checklist OWASP MASVS (móvil) y API Top 10.
- D. Matriz DREAD completa y heatmap.
- E. Capturas de WAF y SIEM.
- F. Enlaces a repositorio y ejecuciones de CI.

## Control de cambios del informe

| Versión | Fecha | Cambio | Autor |
|---|---|---|---|
| 0.1 | 2026-11-19 | Esqueleto y asignación de secciones | James |
