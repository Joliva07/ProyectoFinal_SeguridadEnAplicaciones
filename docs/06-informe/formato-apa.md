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
| Tablas | `Tabla N` en negrita y título en cursiva arriba; nota 10 pt debajo | numeración corrida |
| Figuras | `Figura N` en negrita y título en cursiva arriba; nota 10 pt debajo | fuente citada si es ajena |
| Referencias | Sangría francesa 1.27 cm, alineación izquierda, orden alfabético, APA 7 | ≥ 15 fuentes |
| Anexos | Rotulados A, B, C | referenciados en el texto |

## 2. Estructura

Portada → Resumen ejecutivo → Índice → 1-6 → Anexos → Referencias. Sin página en blanco, sin "Tabla de contenido" manual (campo automático), sin cambiar el orden de secciones.

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
- OWASP Foundation. (2021). *Web Security Testing Guide*. https://owasp.org/www-project-web-security-testing-guide/
- Center for Internet Security. (2024). *CIS Kubernetes Benchmark*.
- OWASP Foundation. (2025). *Application Security Verification Standard 5.0.0*.
- International Organization for Standardization. (2022). *ISO/IEC 27001:2022*.
- National Institute of Standards and Technology. (2020). *SP 800-207: Zero Trust Architecture*.
- Google Cloud. (2024). *Security foundations guide*.
- Cloudflare. (2024). *Web Application Firewall documentation*.
- Junta Monetaria de Guatemala. (2011). *Reglamento para la gestión de riesgo tecnológico*.

## 5. Tablas y figuras del informe

| # | Contenido | Autor |
|---|---|---|
| Tabla 1 | Perfil de seguridad de AuroraShop (stack, hosts) | James |
| Tabla 2 | Alcance dentro y fuera | James |
| Tabla 3 | Inventario de activos (resumen por criticidad) | Javier |
| Tabla 4 | Amenazas STRIDE priorizadas | Javier |
| Tabla 5 | Scoring DREAD (extracto) | Javier |
| Tabla 6 | Matriz de riesgos inicial (resumen) | Javier |
| Tabla 7 | Hallazgos de caja negra | Horacio |
| Tabla 8 | OWASP Top 10:2021 verificado | Horacio / Arun |
| Tabla 9 | Plugins y temas: versión, CVE y decisión | Horacio |
| Tabla 10 | Resultados SAST/SCA y decisión | Josue / Arun |
| Tabla 11 | Controles de plataforma y comprobación | Josue |
| Tabla 12 | Reglas de borde activas | Arun / James |
| Tabla 13 | Tratamiento y riesgo residual | Arun |
| Figura 1 | Arquitectura de seguridad (C4) | Josue |
| Figura 2 | Flujo de checkout con controles | Josue |
| Figura 3 | Superficie de ataque por zonas | Horacio |
| Figura 4 | Heatmap antes / residual / objetivo | Arun |

Las figuras 1-4 están exportadas en `docs/06-informe/figuras/` (PNG) y embebidas en el informe; su fuente editable es Mermaid.

## 5.1 APA 7 aplicado en la exportación

La versión Word/PDF se genera desde `informe-final.md` y aplica estas convenciones de APA 7:

| Elemento | Tratamiento |
|---|---|
| Portada | Título en negrita, centrado; autoría, afiliación, curso, docente y fecha centrados |
| Nivel 1 | Centrado y en negrita (título del documento, resumen) |
| Nivel 2 | Alineado a la izquierda y en negrita |
| Nivel 3 | Alineado a la izquierda, negrita y cursiva |
| Tablas | `Tabla N` en negrita; título en cursiva; encabezado de columna en negrita; nota 10 pt |
| Figuras | `Figura N` en negrita; título en cursiva; nota 10 pt |
| Referencias | Sangría francesa de 1.27 cm, alineación izquierda (no justificada), orden alfabético |
| Citas | Autor-fecha en el cuerpo; cada entrada de la lista está citada al menos una vez |

Se conservan por requisito de la cátedra: Arial 12, interlineado 1.5, márgenes de 2.54 cm, texto justificado y numeración inferior derecha. APA 7 pediría doble espacio y número en la esquina superior derecha; prevalece la norma UMG, documentada en la sección 1.

## 6. Checklist previo a la entrega

- [ ] Arial 12 / 1.5 / márgenes 2.54 en **todo** el documento.
- [ ] Índice actualizado (F9) y numeración correcta.
- [ ] Todas las tablas y figuras citadas en el texto.
- [ ] Sin capturas con datos reales, tokens o IPs internas sin redactar.
- [ ] Referencias completas y citadas en el cuerpo.
- [ ] Nombres y carné de todos los integrantes en portada.
- [ ] PDF revisado en un segundo dispositivo (fuentes incrustadas).
- [ ] Anexos incluidos y con tamaño razonable (< 20 MB).
