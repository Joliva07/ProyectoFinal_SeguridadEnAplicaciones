# Formato UMG y APA 7

Dueño: **James** · Verificación final antes de generar el PDF

## 1. Requisitos de la cátedra

| Elemento | Requisito | Verificación |
|---|---|---|
| Tipo de letra | Arial 12 | todo el cuerpo |
| Interlineado | 1.5 | incluidas tablas (10 pt internas si es necesario) |
| Márgenes | 2.54 cm (1 pulgada) | Word → Diseño |
| Sangría | Primera línea 1.25 cm en párrafos | Estilos, no barra espaciadora |
| Justificación | Texto justificado | excepto títulos |
| Numeración | Esquina inferior derecha, desde la introducción | Insertar → Número de página |
| Títulos | Jerarquía 1, 1.1, 1.1.1 | Estilos de Word, no negrita manual |
| Tablas | Número y título arriba (`Tabla 1`), nota debajo | numeración corrida |
| Figuras | Número y título arriba (`Figura 1`), nota debajo | fuente citada si es ajena |
| Referencias | Sangría francesa, orden alfabético, APA 7 | ≥ 15 fuentes |
| Anexos | Rotulados A, B, C | referenciados en el texto |

## 2. Estructura

Portada → Resumen ejecutivo → Índice → 1–6 → Anexos → Referencias. Sin página en blanco, sin "Tabla de contenido" manual (campo automático), sin cambiar el orden de secciones.

## 3. Citas

| Caso | Ejemplo |
|---|---|
| Paráfrasis | (OWASP Foundation, 2023) |
| Cita textual corta | (NIST, 2020, p. 14) |
| Tres o más autores | (Autor et al., 2024) |
| Norma | (ISO/IEC, 2022) |
| Recurso en línea | (Google Cloud, 2024) |

Toda tabla de herramienta (ZAP, Semgrep, Trivy) cita su documentación oficial en la nota.

## 4. Referencias (formato)

- OWASP Foundation. (2021). *OWASP Top 10:2021*. https://owasp.org/Top10/
- OWASP Foundation. (2023). *OWASP API Security Top 10*. https://owasp.org/API-Security/
- OWASP Foundation. (2025). *Application Security Verification Standard 5.0.0*.
- International Organization for Standardization. (2022). *ISO/IEC 27001:2022*.
- National Institute of Standards and Technology. (2020). *SP 800-207: Zero Trust Architecture*.
- Google Cloud. (2024). *Security foundations guide*.
- Cloudflare. (2024). *Web Application Firewall documentation*.
- Junta Monetaria de Guatemala. (2011). *Reglamento para la gestión de riesgo tecnológico*.

## 5. Tablas y figuras del informe

| # | Contenido | Autor |
|---|---|---|
| Tabla 1 | Perfil de seguridad de FinanciaWeb | Javier |
| Tabla 2 | Inventario de activos (resumen) | Javier |
| Tabla 3 | Matriz STRIDE | Javier |
| Tabla 4 | Scoring DREAD | Javier |
| Tabla 5 | Matriz de riesgos inicial | Javier |
| Tabla 6 | Hallazgos caja negra | Horacio |
| Tabla 7 | Hallazgos caja gris y API Top 10 | Horacio / Arun |
| Tabla 8 | Resultados SAST/SCA/IaC | Josue |
| Tabla 9 | Tratamiento y residual | Arun |
| Figura 1 | Arquitectura de seguridad | Josue |
| Figura 2 | Flujo de transferencia | Josue |
| Figura 3 | Superficie de ataque | Horacio |
| Figura 4 | Heatmap antes/después | Arun |

## 6. Checklist previo a la entrega

- [ ] Arial 12 / 1.5 / márgenes 2.54 en **todo** el documento.
- [ ] Índice actualizado (F9) y numeración correcta.
- [ ] Todas las tablas y figuras citadas en el texto.
- [ ] Sin capturas con datos reales, tokens o IPs internas sin redactar.
- [ ] Referencias completas y citadas en el cuerpo.
- [ ] Nombres y carné de todos los integrantes en portada.
- [ ] PDF revisado en un segundo dispositivo (fuentes incrustadas).
- [ ] Anexos incluidos y con tamaño razonable (< 20 MB).
